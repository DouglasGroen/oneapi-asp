#include <sycl/ext/intel/fpga_extensions.hpp>

#include <sycl/sycl.hpp>

// NOTE: sycl::ulong8 was picked for this test because it is 64 bytes in size
// and that is the width of the interconnect to global memory.

// Arbitrary value used for testing/initialization
#define TEST_VAL 5

// Forward declare the kernel names
class USMMemCopy;
class USMMemRead;
class USMMemWrite;

// Available tests to be run
enum USMTest { MEMCOPY, READ, WRITE };
//enum USELINK { L1, L2, L1L2 };

#define MEMCOPY_PROPS1_BUFLOC   1
#define MEMCOPY_PROPS2_BUFLOC   2
#define READ_PROPS1_BUFLOC      1
#define READ_PROPS2_BUFLOC      2
#define WRITE_PROPS1_BUFLOC     1
#define WRITE_PROPS2_BUFLOC     2
#define IN1_BUFLOC              1
#define IN2_BUFLOC              2
#define OUT1_BUFLOC             1
#define OUT2_BUFLOC             2


// MEMCOPY test: launches a kernel to copy data from one USM pointer to another.
sycl::event memcopy_kernel(sycl::queue &q, sycl::ulong8 *in_1,  sycl::ulong8 *in_2, sycl::ulong8 *out_1, sycl::ulong8 *out_2,
                           size_t num_items) {

  auto props1 = sycl::ext::oneapi::experimental::properties{sycl::ext::intel::experimental::buffer_location<MEMCOPY_PROPS1_BUFLOC>};
  auto props2 = sycl::ext::oneapi::experimental::properties{sycl::ext::intel::experimental::buffer_location<MEMCOPY_PROPS2_BUFLOC>};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props1)> in_a{in_1};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props2)> in_b{in_2};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props1)> out_a{out_1};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props2)> out_b{out_2};

  return q.single_task<USMMemCopy>([=]() [[intel::kernel_args_restrict]] {
    //sycl::host_ptr<sycl::ulong8> in_h(in);
    //sycl::host_ptr<sycl::ulong8> out_h(out);
    for (size_t i = 0; i < num_items; i++) {
      //out_h[i] = in_h[i];
      out_a[i] = in_a[i];
      out_b[i] = in_b[i];
    }
  });
}

// READ test: launches a kernel to read data from a USM pointer, sum it up, and
// store to an output pointer.
sycl::event read_kernel(sycl::queue &q, sycl::ulong8 *in_1,  sycl::ulong8 *in_2, sycl::ulong8 *out_1, sycl::ulong8 *out_2,
                           size_t num_items) {
  auto props1 = sycl::ext::oneapi::experimental::properties{sycl::ext::intel::experimental::buffer_location<READ_PROPS1_BUFLOC>};
  auto props2 = sycl::ext::oneapi::experimental::properties{sycl::ext::intel::experimental::buffer_location<READ_PROPS2_BUFLOC>};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props1)> in_a{in_1};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props2)> in_b{in_2};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props1)> out_a{out_1};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props2)> out_b{out_2};

  return q.single_task<USMMemRead>([=]() {
    //sycl::host_ptr<sycl::ulong8> in_h(in);
    //sycl::host_ptr<sycl::ulong8> out_h(out);
    sycl::ulong8 sum{0};
    for (size_t i = 0; i < num_items; i++) {
      //sum += in_h[i];
        sum += in_a[i] + in_b[i];
    }
    // This prevents the reads from being optimized away
        out_a[0] = sum;
        out_b[0] = sum;
  });
}

// WRITE test: launches a kernel to write data to a USM pointer.
sycl::event write_kernel(sycl::queue &q, sycl::ulong8 *in_1,  sycl::ulong8 *in_2, sycl::ulong8 *out_1, sycl::ulong8 *out_2,
                           size_t num_items) {
  auto props1 = sycl::ext::oneapi::experimental::properties{sycl::ext::intel::experimental::buffer_location<WRITE_PROPS1_BUFLOC>};
  auto props2 = sycl::ext::oneapi::experimental::properties{sycl::ext::intel::experimental::buffer_location<WRITE_PROPS2_BUFLOC>};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props1)> in_a{in_1};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props2)> in_b{in_2};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props1)> out_a{out_1};
  sycl::ext::oneapi::experimental::annotated_arg<sycl::ulong8 *, decltype(props2)> out_b{out_2};

  return q.single_task<USMMemWrite>([=]() {
    //sycl::host_ptr<sycl::ulong8> out_h(out);
    sycl::ulong8 answer{TEST_VAL};
    for (size_t i = 0; i < num_items; i++) {
      //out_h[i] = answer;
        out_a[i] = answer;
        out_b[i] = answer;
    }
  });
}

// Function to check output against expected answer.
bool verify(sycl::ulong8 *actual_1, sycl::ulong8 *actual_2, sycl::ulong8 *expected_1, sycl::ulong8 *expected_2, size_t num_items) {
  // Verify all values are equal
  for (int i = 0; i < num_items; i++) {
    for (int j = 0; j < 8; j++) {
      if (actual_1[i][j] != expected_1[i][j]) {
        std::cerr << "ERROR: Values do not match, "
                  << "out[" << i << "][" << j << "] = " << actual_1[i][j]
                  << "; expected " << expected_1[i][j] << std::endl;
        return false;
      }
      if (actual_2[i][j] != expected_2[i][j]) {
        std::cerr << "ERROR: Values do not match, "
                  << "out[" << i << "][" << j << "] = " << actual_2[i][j]
                  << "; expected " << expected_2[i][j] << std::endl;
        return false;
      }
    }
  }
  return true;
}

// Parameterized function to perform one of the tests defined above. Allocates
// and initializes host USM, runs the test, then verifies the answer. Then
// re-runs the test several times to measure bandwidth.
int run_test(sycl::queue &q, USMTest test) {

  size_t iterations = 1;
  size_t num_buffers = 2;
  size_t num_bytes = 1024*1024;//originally 64x1024
  size_t num_items = num_bytes / sizeof(sycl::ulong8);
  size_t num_bytes_GB = ((num_bytes * num_buffers)/ kGiB);

  std::cout << "Iterations: " << iterations << std::endl;
#if FPGA_HARDWARE 
  std::cout << "Data size: " << ((num_bytes * num_buffers)/ kMiB) << " MB" << std::endl;
#else
  std::cout << "Data size: " << num_bytes << " B" << std::endl;
#endif
  std::cout << "Data type size: " << sizeof(sycl::ulong8) << " bytes"
            << std::endl;

  // USM host allocation
  //sycl::ulong8 *in = sycl::malloc_host<sycl::ulong8>(num_items, q);
  //sycl::ulong8 *out = sycl::malloc_host<sycl::ulong8>(num_items, q);
  //auto link = L2; //Change to L1 || L2 or L1L2
  auto *in_1 = sycl::malloc_host<sycl::ulong8>(num_items, q, sycl:: ext::intel::experimental::property::usm::buffer_location(IN1_BUFLOC)); // L1 -1, L2 -2
  auto *in_2 = sycl::malloc_host<sycl::ulong8>(num_items, q, sycl:: ext::intel::experimental::property::usm::buffer_location(IN2_BUFLOC));
  auto *out_1 = sycl::malloc_host<sycl::ulong8>(num_items, q, sycl:: ext::intel::experimental::property::usm::buffer_location(OUT1_BUFLOC));
  auto *out_2 = sycl::malloc_host<sycl::ulong8>(num_items, q, sycl:: ext::intel::experimental::property::usm::buffer_location(OUT2_BUFLOC));
  if (in_1 == nullptr || in_2 == nullptr || out_1 == nullptr || out_2 == nullptr) {
    std::cerr << "Error: Out of memory, can't allocate " << num_bytes
              << " bytes" << std::endl;
    return 1;
  }

  // Initialize the input with random values and output with zero.
  for (int i = 0; i < num_items; i++) {
    in_1[i] = 0x123;//rand();
    in_2[i] = 0x4567;//rand();
    out_1[i] = 0;
    out_2[i] = 0;
  }

  std::function<sycl::event(sycl::queue &, sycl::ulong8 *, sycl::ulong8 *, sycl::ulong8 *, sycl::ulong8 *, size_t)>  kernel;

  sycl::ulong8 *expected_1 = new sycl::ulong8[num_items];
  sycl::ulong8 *expected_2 = new sycl::ulong8[num_items];

  // Test selection: set the test function that will be run, and fill the
  // "expected" array with the expected answer.
  switch (test) {
  case MEMCOPY: {
    std::cout << "Case: Full Duplex" << std::endl;
    kernel = memcopy_kernel;
    // Full duplex transfers twice the amount of data
    num_bytes_GB *= 2 ; //2- Used to account for TX & RX 
    // When verifying, the output pointer should match the input pointer.
    for (int i = 0; i < num_items; i++) {
        expected_1[i] = in_1[i];
        expected_2[i] = in_2[i];
    }
    break;
  }
  case READ: {
    std::cout << "Case: From Host to Device" << std::endl;
    kernel = read_kernel;
    // When verifying, the first index of the output pointer should contain
    // the expected answer (sum of all values at the input pointer); at all
    // other indices it should contain zero.
    sycl::ulong8 read_answer{0};
    for (int i = 0; i < num_items; i++) {
      //read_answer += in[i];
      read_answer += in_1[i] + in_2[i];
    }
    for (int i = 0; i < num_items; i++) {
      expected_1[i] = (i == 0) ? read_answer : (sycl::ulong8)(0);
      expected_2[i] = (i == 0) ? read_answer : (sycl::ulong8)(0);
    }
    break;
  }
  case WRITE: {
    std::cout << "Case: From Device to Host" << std::endl;
    kernel = write_kernel;
    // When verifying, each index of the output pointer should contain the
    // known answer that was written.
    for (int i = 0; i < num_items; i++) {
      expected_1[i] = TEST_VAL;
      expected_2[i] = TEST_VAL;
    }
    break;
  }
  default:
    std::cout << "Error: Failed to launch test" << std::endl;
    sycl::free(in_1, q);
    sycl::free(in_2, q);
    sycl::free(out_1, q);
    sycl::free(out_2, q);
    delete[] expected_1;
    delete[] expected_2;
    return 1;
  }

  // The first iteration is slow due to one time tasks like buffer creation,
  // program creation and device programming, bandwidth measured in subsequent
  // iterations.
  kernel(q, in_1, in_2,out_1, out_2, num_items).wait();
  std::cout << "DOUG DOUG DOUG: after kernel function call" << std::endl;
  bool test_status;
    test_status = verify(out_1, out_2, expected_1, expected_2, num_items);

  if (!test_status) {
    std::cerr << "FAILED" << std::endl << std::endl;
    sycl::free(in_1, q);
    sycl::free(in_2, q);
    sycl::free(out_1, q);
    sycl::free(out_2, q);
    delete[] expected_1;
    delete[] expected_2;
    return 1;
  }
  float time = 0;
  for (int i = 0; i < iterations; i++) {
    sycl::event e;
    e = kernel(q, in_1, in_2, out_1, out_2, num_items);
    e.wait();
    time += SyclGetQStExecTimeNs(e);
  }

  sycl::free(in_1, q);
  sycl::free(in_2, q);
  sycl::free(out_1, q);
  sycl::free(out_2, q);
  delete[] expected_1;
  delete[] expected_2;

  // Report throughput
  time /= iterations;
  //std::cout << "Average Time: " << time / 1000.0 << " ns\t" << std::endl;//Measurement is already in ns
  std::cout << "PCIe Link: Both L1 -x8 & L2 -x8" << std::endl;
  std::cout << "Average Time: " << time << " ns\t" << std::endl;
  std::cout << "Average Throughput: "
            << (num_bytes_GB / (time / (1000.0 * 1000.0 * 1000.0))) << " GB/s\t"
            << std::endl
            << std::endl;

  return 0;
}

