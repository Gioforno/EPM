#define EPM_IMPLEMENTATION
#include "external/epm.hpp"

#include <cstdio>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <cuda_runtime.h>

#define TILE 16

__global__ 
void kernelMultTile(float* d_pmap, int width, int height, int z, Particle* d_ps, int n) {

    __shared__ Particle t_ps[TILE];

    int row = blockIdx.y * TILE + threadIdx.y;
    int col = blockIdx.x * TILE + threadIdx.x;
    int t_id = threadIdx.y * blockDim.x + threadIdx.x;
    
    float result = 0.0f;

//building of batch of the particles to be parallelized
    for (int t = 0; t <n; t += TILE) {  //process particles in batch
        

        if(t_id < TILE && t + t_id < n) {
            t_ps[t_id] = d_ps[t + t_id];
        }

        __syncthreads();

        int batchCount = min(TILE, n - t); //last tile could have less particles than a standard batch with #tile particles

//calculus part parallelized in tiles
        if(row < height && col < width){

            //parallelized computation of result
            for (int i = 0; i < batchCount; i++) {

                    float dx = (float)col - t_ps[i].x;
                    float dy = (float)row - t_ps[i].y;
                    float dz = (float)z - t_ps[i].z;

                    float d = (dx*dx + dy*dy + dz*dz);
                    result += t_ps[i].q / d;
                }
        }
        __syncthreads();
    }
    
    if(row < height && col < width){
            d_pmap[width * row + col] = result;
    }


    
}

float gpuT_calculate_z_slice(
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
    dim3 DimBlock(TILE, TILE);
    dim3 DimGrid((width + TILE - 1) / TILE, (height + TILE - 1) / TILE);

//device execution
    std::cout<<"Starting GPU naive computation"<<std::endl;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);
    kernelMultTile<<<DimGrid,DimBlock>>>(d_pmap,width,height,z,d_ps,n);
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
