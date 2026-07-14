#include "summa_opts.h"
#include "utils.h"
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>


void distribute_matrix_blocks(float *globalA, float *globalB, 
                              float *localA, float *localB,
                              int A_rows, int B_cols, int A_cols,
                              int grid, int local_rows, int local_cols, int local_shared,
                              MPI_Comm comm, int myRank) {
    int total = grid * grid;
    float *bufferA = NULL, *bufferB = NULL;
    if (myRank == 0) {
        size_t sizeA = total * local_rows * local_shared * sizeof(float);
        size_t sizeB = total * local_shared * local_cols * sizeof(float);
        bufferA = (float *)malloc(sizeA);
        bufferB = (float *)malloc(sizeB);
        memset(bufferA, 0, sizeA);
        memset(bufferB, 0, sizeB);
        for (int p = 0; p < total; p++) {
            int procRow = p / grid;
            int procCol = p % grid;
            int offA_r = procRow * local_rows;
            int offA_c = procCol * local_shared;
            int offB_r = procRow * local_shared;
            int offB_c = procCol * local_cols;
            for (int i = 0; i < local_rows; i++) {
                int global_i = offA_r + i;
                if (global_i >= A_rows) continue;
                for (int j = 0; j < local_shared; j++) {
                    int global_j = offA_c + j;
                    if (global_j >= A_cols) continue;
                    int index = p * local_rows * local_shared + i * local_shared + j;
                    bufferA[index] = globalA[global_i * A_cols + global_j];
                }
            }
            for (int i = 0; i < local_shared; i++) {
                int global_i = offB_r + i;
                if (global_i >= A_cols) continue;
                for (int j = 0; j < local_cols; j++) {
                    int global_j = offB_c + j;
                    if (global_j >= B_cols) continue;
                    int index = p * local_shared * local_cols + i * local_cols + j;
                    bufferB[index] = globalB[global_i * B_cols + global_j];
                }
            }
        }
    }
    MPI_Scatter(bufferA, local_rows * local_shared, MPI_FLOAT,
                localA, local_rows * local_shared, MPI_FLOAT,
                0, comm);
    MPI_Scatter(bufferB, local_shared * local_cols, MPI_FLOAT,
                localB, local_shared * local_cols, MPI_FLOAT,
                0, comm);
    if (myRank == 0) {
        free(bufferA);
        free(bufferB);
    }
    MPI_Barrier(comm);
}
//---------------------------------------------------------------------


// Stationary-A variant (using matmul for local multiplication).
// In this variant, each process keeps its A_local block fixed and
// first gathers the entire row of A subblocks into A_row. Then, for each
// step, it extracts the corresponding A block from A_row and combines it
// with a broadcast B subblock (from the column communicator) to update C.
void summa_variant_A(int M, int N, int K, int totalProcs, int myRank) {
    double start_time, end_time;
    start_time = MPI_Wtime();  // Start timing

    int grid = (int)sqrt(totalProcs);
    int localRows  = M / grid;
    int localShared = K / grid;
    int localCols  = N / grid;

    MPI_Comm cartComm;
    int dims[2] = {grid, grid}, periods[2] = {0, 0}, reorder = 0;
    MPI_Cart_create(MPI_COMM_WORLD, 2, dims, periods, reorder, &cartComm);

    int coords[2];
    MPI_Cart_coords(cartComm, myRank, 2, coords);
    int rowID = coords[0], colID = coords[1];

    MPI_Comm rowComm, colComm;
    MPI_Comm_split(cartComm, rowID, colID, &rowComm);
    MPI_Comm_split(cartComm, colID, rowID, &colComm);

    float *A_local = (float *)malloc(localRows * localShared * sizeof(float));
    float *B_local = (float *)malloc(localShared * localCols * sizeof(float));
    float *C_local = (float *)calloc(localRows * localCols, sizeof(float));

    float *A_full = NULL, *B_full = NULL;
    if (myRank == 0) {
        A_full = generate_matrix_A(M, K, myRank);
        B_full = generate_matrix_B(K, N, myRank);
    }
    distribute_matrix_blocks(A_full, B_full, A_local, B_local,
                             M, N, K, grid, localRows, localCols, localShared, cartComm, myRank);

    MPI_Barrier(MPI_COMM_WORLD);

    // Timing for the gather
    double gather_start = MPI_Wtime();
    float *A_row = (float *)malloc(localRows * K * sizeof(float));
    MPI_Allgather(A_local, localRows * localShared, MPI_FLOAT,
                  A_row, localRows * localShared, MPI_FLOAT, rowComm);
    double gather_end = MPI_Wtime();
    if (myRank == 0) {
        printf("Gather time: %f seconds\n", gather_end - gather_start);
    }

    // Timing for the matrix multiplication
    float *A_block = (float *)malloc(localRows * localShared * sizeof(float));
    float *B_buf   = (float *)malloc(localShared * localCols * sizeof(float));
    float *tempC = (float *)malloc(localRows * localCols * sizeof(float));

    for (int step = 0; step < grid; step++) {
        for (int i = 0; i < localRows; i++) {
            memcpy(&A_block[i * localShared],
                   A_row + step * (localRows * localShared) + i * localShared,
                   localShared * sizeof(float));
        }

        if (rowID == step)
            memcpy(B_buf, B_local, localShared * localCols * sizeof(float));
        MPI_Bcast(B_buf, localShared * localCols, MPI_FLOAT, step, colComm);

        memset(tempC, 0, localRows * localCols * sizeof(float));
        matmul(A_block, B_buf, tempC, localRows, localCols, localShared);
        for (int i = 0; i < localRows * localCols; i++) {
            C_local[i] += tempC[i];
        }
    }
    free(A_block);
    free(B_buf);
    free(tempC);
    free(A_row);

    end_time = MPI_Wtime();  // End timing

    // Gather the result back to the root
    float *C_global = NULL;
    if (myRank == 0)
        C_global = (float *)malloc(M * N * sizeof(float));
    MPI_Gather(C_local, localRows * localCols, MPI_FLOAT,
               C_global, localRows * localCols, MPI_FLOAT, 0, cartComm);

    if (myRank == 0) {
        float *C_final = (float *)malloc(M * N * sizeof(float));
        for (int i = 0; i < grid; i++) {
            for (int j = 0; j < grid; j++) {
                int base = (i * grid + j) * (localRows * localCols);
                for (int r = 0; r < localRows; r++) {
                    for (int c = 0; c < localCols; c++) {
                        int global_i = i * localRows + r;
                        int global_j = j * localCols + c;
                        C_final[global_i * N + global_j] = C_global[base + r * localCols + c];
                    }
                }
            }
        }
        verify_result(C_final, A_full, B_full, M, N, K);
        free(C_final);
        free(C_global);
        free(A_full);
        free(B_full);
    }

    free(A_local);
    free(B_local);
    free(C_local);
    MPI_Comm_free(&cartComm);
    MPI_Comm_free(&rowComm);
    MPI_Comm_free(&colComm);

    if (myRank == 0) {
        printf("Total execution time: %f seconds\n", end_time - start_time);
    }
}


// Stationary-C variant using blocking collective calls and a different loop order.
// Updated to use matmul() for the local multiplication.
void summa_variant_C(int M, int N, int K, int nProcs, int myRank) {
    double start_time;
    start_time = MPI_Wtime();  // Start total algorithm timing

    int p = (int)sqrt(nProcs);
    int subM = M / p;
    int subK = K / p;
    int subN = N / p;

    MPI_Comm cartComm;
    int dims[2] = {p, p}, periods[2] = {0, 0}, reorder = 0;
    MPI_Cart_create(MPI_COMM_WORLD, 2, dims, periods, reorder, &cartComm);

    int coords[2];
    MPI_Cart_coords(cartComm, myRank, 2, coords);
    int gridRow = coords[0], gridCol = coords[1];

    MPI_Comm rowComm, colComm;
    MPI_Comm_split(cartComm, gridRow, gridCol, &rowComm);
    MPI_Comm_split(cartComm, gridCol, gridRow, &colComm);

    float *localA = (float *)malloc(subM * subK * sizeof(float));
    float *localB = (float *)malloc(subK * subN * sizeof(float));
    float *localC = (float *)calloc(subM * subN, sizeof(float));

    float *fullA = NULL, *fullB = NULL;
    if (myRank == 0) {
        fullA = generate_matrix_A(M, K, myRank);
        fullB = generate_matrix_B(K, N, myRank);
    }

    // Timing for matrix distribution (scatter)
    double dist_start = MPI_Wtime();
    distribute_matrix_blocks(fullA, fullB, localA, localB,
                             M, N, K, p, subM, subN, subK, cartComm, myRank);
    MPI_Barrier(MPI_COMM_WORLD);  // Ensure all processes have finished distribution
    double dist_end = MPI_Wtime();
    if (myRank == 0) {
        printf("Matrix distribution time: %f seconds\n", dist_end - dist_start);
    }

    // Timing for the gather
    double gather_start = MPI_Wtime();
    float *bufA = (float *)malloc(subM * subK * sizeof(float));
    float *bufB = (float *)malloc(subK * subN * sizeof(float));
    float *tempC = (float *)malloc(subM * subN * sizeof(float));

    for (int step = 0; step < p; step++) {
        if (gridCol == step)
            memcpy(bufA, localA, subM * subK * sizeof(float));
        MPI_Bcast(bufA, subM * subK, MPI_FLOAT, step, rowComm);
        if (gridRow == step)
            memcpy(bufB, localB, subK * subN * sizeof(float));
        MPI_Bcast(bufB, subK * subN, MPI_FLOAT, step, colComm);

        memset(tempC, 0, subM * subN * sizeof(float));
        matmul(bufA, bufB, tempC, subM, subN, subK);
        for (int i = 0; i < subM * subN; i++) {
            localC[i] += tempC[i];
        }
    }

    free(bufA);
    free(bufB);
    free(tempC);

    double gather_end = MPI_Wtime();
    if (myRank == 0) {
        printf("Gather and computation time: %f seconds\n", gather_end - gather_start);
    }

    // Gather the result back to the root
    double gather_result_start = MPI_Wtime();
    float *gatheredC = NULL;
    if (myRank == 0)
        gatheredC = (float *)malloc(M * N * sizeof(float));
    MPI_Gather(localC, subM * subN, MPI_FLOAT,
               gatheredC, subM * subN, MPI_FLOAT,
               0, cartComm);
    double gather_result_end = MPI_Wtime();
    if (myRank == 0) {
        printf("Result gathering time: %f seconds\n", gather_result_end - gather_result_start);
    }

    // Final computation on root (reconstruction of the final result matrix)
    if (myRank == 0) {
        double final_start = MPI_Wtime();
        float *finalC = (float *)malloc(M * N * sizeof(float));
        for (int i = 0; i < p; i++) {
            for (int j = 0; j < p; j++) {
                int base = (i * p + j) * (subM * subN);
                for (int r = 0; r < subM; r++) {
                    for (int c = 0; c < subN; c++) {
                        int globalRow = i * subM + r;
                        int globalCol = j * subN + c;
                        finalC[globalRow * N + globalCol] = gatheredC[base + r * subN + c];
                    }
                }
            }
        }
        verify_result(finalC, fullA, fullB, M, N, K);
        free(finalC);
        free(gatheredC);
        free(fullA);
        free(fullB);
        double final_end = MPI_Wtime();
        printf("Final computation and verification time: %f seconds\n", final_end - final_start);
    }

    free(localA);
    free(localB);
    free(localC);
    MPI_Comm_free(&cartComm);
    MPI_Comm_free(&rowComm);
    MPI_Comm_free(&colComm);

    // End total execution time
    double total_end_time = MPI_Wtime();
    if (myRank == 0) {
        printf("Total execution time for the algorithm: %f seconds\n", total_end_time - start_time);
    }
}

int main(int argc, char *argv[]){
    MPI_Init(&argc, &argv);
    int myRank, nProcs;
    MPI_Comm_rank(MPI_COMM_WORLD, &myRank);
    MPI_Comm_size(MPI_COMM_WORLD, &nProcs);
    
    SummaOpts opts = parse_args(argc, argv);
    MPI_Bcast(&opts, sizeof(SummaOpts), MPI_BYTE, 0, MPI_COMM_WORLD);
    
    int gridSize = (int)sqrt(nProcs);
    if (gridSize * gridSize != nProcs) {
         if (myRank == 0)
              printf("Error: Process count must be a perfect square.\n");
         MPI_Finalize();
         return 1;
    }
    if (opts.m % gridSize != 0 || opts.n % gridSize != 0 || opts.k % gridSize != 0) {
         if (myRank == 0)
              printf("Error: Matrix dimensions must be divisible by grid size (%d).\n", gridSize);
         MPI_Finalize();
         return 1;
    }
    if (myRank == 0) {
         printf("\nMatrix Dimensions: A(%d x %d), B(%d x %d), C(%d x %d)\n",
                opts.m, opts.k, opts.k, opts.n, opts.m, opts.n);
         printf("Algorithm Variant: %c\n", opts.stationary);
    }

    if (opts.stationary == 'a') {
         summa_variant_A(opts.m, opts.n, opts.k, nProcs, myRank);
    } else if (opts.stationary == 'c') {
         summa_variant_C(opts.m, opts.n, opts.k, nProcs, myRank);
    }
    
    MPI_Finalize();
    return 0;
}
