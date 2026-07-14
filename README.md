# Distributed Matrix Multiplication Using the SUMMA Algorithm

This project implements distributed matrix multiplication using the **Scalable Universal Matrix Multiplication Algorithm (SUMMA)** with MPI (Message Passing Interface). The two main variants of the SUMMA algorithm, **Stationary-A** and **Stationary-C**, are implemented and evaluated for their performance on square and rectangular matrices.

## Prerequisites

Before running the code, make sure the following tools are installed:

- **MPI**: This implementation requires an MPI library for parallelization (e.g., OpenMPI, MPICH).
- **C Compiler**: Make sure a C compiler like GCC is installed.
- **Valgrind**, **Callgrind**, and **Massif** for profiling.

## Code Structure

- **`main.c`**: Contains the `main` function that initializes MPI, handles argument parsing, and calls the appropriate SUMMA variant based on user input.
- **`summa_opts.c`**: Contains functions for parsing command-line arguments and handling options like matrix dimensions, block size, and algorithm variant.
- **`utils.c`**: Contains utility functions, including matrix multiplication, result verification, and matrix generation.
- **`Makefile`**: Automates the build process.

## Compilation

To compile the project, use the provided `Makefile`. Run the following command:

make clean
make
make valgrind_all

This will compile the code and generate an executable named `summa`.

## Running the Program

After compiling, you can run the program using `mpirun` with the desired number of processes. The general usage of the program is as follows:

mpirun -np <num_procs> ./summa --rows <M> --cols <N> --inner <K> --stationary <variant> --block <block_size> [options]

### Example Usage:

To run with 4 processes, where matrix A is of size 4096x4096, matrix B is 4096x4096, and the algorithm variant is Stationary-A:

mpirun -np 4 ./summa --rows 4096 --cols 4096 --inner 4096 --stationary a --block 64 --verbose


### Profiling (Optional):

To profile memory and execution performance, you can use tools like Valgrind, Callgrind, and Massif. These tools can be invoked as follows:

valgrind --tool=massif ./summa --rows 4096 --cols 4096 --inner 4096 --stationary a --block 64


Or for performance profiling using Callgrind:

valgrind --tool=callgrind ./summa --rows 4096 --cols 4096 --inner 4096 --stationary a --block 64


## How the Code Works

### SUMMA Algorithm

The SUMMA algorithm decomposes the matrix multiplication into smaller sub-blocks and distributes these sub-blocks across multiple processes. Each process performs local matrix multiplication on its assigned sub-blocks, and the results are accumulated to form the final matrix.

#### Stationary-A Variant:

In the **Stationary-A** variant, matrix A remains fixed, and only matrix B is broadcasted during the computation. The local blocks of matrix A are broadcast across the processes, and matrix C is updated as the results are accumulated.

#### Stationary-C Variant:

In the **Stationary-C** variant, matrix C remains fixed, and both matrix A and matrix B are broadcasted during computation. The local blocks of A and B are multiplied, and the results are stored in matrix C.

### Communication

The communication is managed using MPI’s **MPI_Scatter** to distribute matrix sub-blocks to all processes, and **MPI_Bcast** to broadcast the necessary blocks during computation. Finally, **MPI_Gather** is used to collect the results.

### Matrix Generation and Verification

Matrix A and B are generated randomly in the code using the functions `generate_matrix_A()` and `generate_matrix_B()`. The correctness of the result is verified by computing the result using a direct multiplication approach and comparing the values with those computed by the distributed algorithm using the function `verify_result()`.

## Performance Metrics

The program supports performance profiling with the **`--perf`** option. It measures:

- Execution time for the algorithm.
- Data movement between processes.
- Communication overhead and computation time breakdown.

## Profiling Tools

- **Valgrind**: Detects memory leaks and memory access errors.
- **Callgrind**: Profiles cache usage and performance bottlenecks.
- **Massif**: Measures memory consumption over time.

## Conclusion

The project implements a scalable matrix multiplication algorithm using the SUMMA approach, with two variants for optimizing communication and computation. It demonstrates the importance of minimizing communication overhead and optimizing memory access patterns for large-scale parallel computation. 
