#define EPM_IMPLEMENTATION
#include "external/epm.hpp"

#include <cstdio>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <cuda_runtime.h>

__global__ void kernelMult() {
    int global_id = blockIdx.x * blockDim + threadIdx

//computation of the potential

}

int gpuN_calculate_z_slice(
    float* pmap,        // The potential map slice (width x height) 
    const int width,    // Width of the slice
    const int height,   // Height of the slice
    const int z,        // What z slice we are calculating
    const Particle* ps, // Particles of the system
    const int n)        // Number of particles
{
    cudaEvent_t start, stop;
    

//mem device allocation

//copy data from memory to device

//device initialization
    dim3 DimGrid(N/256, 1, 1);
    if (N%256) DimGrid.x++;
    dim3 DimBlock(256, 1, 1);

//device execution
    cudaEventCreate(&start);
    kernelMult<<<>>>()


    cudaEventCreate(&stop);

//retrive data to the host


    int time = 0;
    cudaEventElapsedTime(&time, start, stop);


//deallocation host memory

//deallocation device memory
    return time;

}
