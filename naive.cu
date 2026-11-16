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
    if (row < width && col < height) {

        float result = 0.0f;

        for (int i = 0; i < n; i++) {

                float dx = (float)row - d_ps[i].x;
                float dy = (float)col - d_ps[i].y;
                float dz = (float)z - d_ps[i].z;

                float d = (dx*dx + dy*dy + dz*dz);
                result += d_ps[i].q / d;
            }

        d_pmap[width * row + col] = result;

    }
    
}

int gpuN_calculate_z_slice(
    float* pmap,        // The potential map slice (width x height) 
    const int width,    // Width of the slice
    const int height,   // Height of the slice
    const int z,        // What z slice we are calculating
    const Particle* ps, // Particles of the system
    const int n
    )        // Number of particles
{
    cudaEvent_t start, stop;
    
//mem device allocation
    float* d_pmap;   
    cudaMalloc(&d_pmap, (width*height) * sizeof(int));

    Particle* d_ps;   
    cudaMalloc(&d_ps, sizeof(Particle));

//copy data from memory to device
    cudaMemcpy(d_pmap, pmap, (width*height) * sizeof(int), cudaMemcpyHostToDevice);
    cudaMemcpy(d_ps, ps, sizeof(Particle), cudaMemcpyHostToDevice);


//device initialization
    dim3 DimGrid((width*height)/256, 1, 1);
    if ((width*height)%256) DimGrid.x++;
    dim3 DimBlock(256, 1, 1);

//device execution

    std::cout<<"Starting gpu naive computation"<<std::endl;
    cudaEventCreate(&start);

    kernelMult<<<DimGrid,DimBlock>>>(d_pmap,width,height,z,d_ps,n);

    cudaEventCreate(&stop);

    float time = 0;
    cudaEventElapsedTime(&time, start, stop);

//retrive data to the host
    cudaMemcpy(pmap, d_pmap, (width*height) * sizeof(int), cudaMemcpyDeviceToHost);

//deallocation host memory 

//deallocation device memory
    cudaFree(d_pmap);
    cudaFree(d_ps);
    return (int)time;

}
