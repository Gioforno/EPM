#define EPM_IMPLEMENTATION
#include "external/epm.hpp"

#include <cstdio>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <cuda_runtime.h>

__global__ 
void kernelMult(float* d_pmap, int width, int height, int z, Particle* d_ps, int n) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

//computation of the potential
    if (row < height && col < width) {

        float result = 0.0f;

        for (int i = 0; i < n; i++) {

                float dx = (float)col - d_ps[i].x;
                float dy = (float)row - d_ps[i].y;
                float dz = (float)z - d_ps[i].z;

                float d = sqrtf(dx*dx + dy*dy + dz*dz);
                result += d_ps[i].q / d;
            }

        d_pmap[width * row + col] = result;

    }
    
}

float gpuN_calculate_z_slice(
    float* pmap,        // The potential map slice (width x height) 
    const int width,    // Width of the slice
    const int height,   // Height of the slice
    const int z,        // What z slice we are calculating
    const Particle* ps, // Particles of the system
    const int n         // Number of particles
    )        
{
    cudaEvent_t start, stop;
    
//mem device allocation
    float* d_pmap;   
    cudaMalloc(&d_pmap, (width*height) * sizeof(float));

    Particle* d_ps;   
    cudaMalloc(&d_ps, n*sizeof(Particle));

//copy data from memory to device
    cudaMemcpy(d_ps, ps, n*sizeof(Particle), cudaMemcpyHostToDevice);


//device initialization
    dim3 DimBlock(16, 16);
    dim3 DimGrid((width  + DimBlock.x - 1) / DimBlock.x,
                (height + DimBlock.y - 1) / DimBlock.y);

//device execution
    std::cout<<"Starting GPU naive computation"<<std::endl;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    kernelMult<<<DimGrid,DimBlock>>>(d_pmap,width,height,z,d_ps,n);
    cudaEventRecord(stop);

    cudaEventSynchronize(stop);
    

    float time = 0;
    cudaEventElapsedTime(&time, start, stop);

//retrive data to the host
    cudaMemcpy(pmap, d_pmap, (width*height) * sizeof(float), cudaMemcpyDeviceToHost);

//deallocation device memory
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    cudaFree(d_pmap);
    cudaFree(d_ps);
    return time;

}
