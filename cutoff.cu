#define EPM_IMPLEMENTATION
#include "external/epm.hpp"

#include <cstdio>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <cuda_runtime.h>

void computeKey(Partcile* d_ps,int height, int width, int z, int n) {
    if(i > n) return;
    
    Particle p = d_ps[i];

    int cx = floor(p.x/dimCell);
    int cy = floor(p.y/dimCell);

    keys[i] = (z*height + cy)*width+cx;
    idx[i] = i;

}

void kernelReord(
    
) {

}
vodi kernelBuildRange(
    
) {

}

__global__ 
void kernelMult(float* d_pmap, int width, int height, int z, Particle* d_ps, int n, int* keys, int* idx, int dimCell) {




}





void sortKeys(int* keys, int* idx) {

}









float gpuC_calculate_z_slice(
    float* pmap,        // The potential map slice (width x height) 
    const int width,    // Width of the slice
    const int height,   // Height of the slice
    const int z,        // What z slice we are calculating
    const Particle* ps, // Particles of the system
    const int n         // Number of particles
    )        
{
    int cutoff = 3;   //range of the cutoff

    dimCell = cutoff*(1+10-6);  //avoid division by 0

    numCells = width*height;

    //mem device allocation
    Particle* d_ps;   
    cudaMalloc(&d_ps, n*sizeof(Particle));
    cudaMemcpy(d_ps, ps, n*sizeof(Particle), cudaMemcpyHostToDevice);

    Particle* od_ps;   
    cudaMalloc(&od_ps, n*sizeof(Particle));

    cellStart[numCells+1];
    cudaMalloc(&cellStart, (numCells+1)*sizeof(int));

    float* d_pmap;   
    cudaMalloc(&d_pmap, (width*height) * sizeof(float));



//kernel initialization
    dim3 DimBlock(16, 16);
    dim3 DimGrid((width  + DimBlock.x - 1) / DimBlock.x,
                (height + DimBlock.y - 1) / DimBlock.y);

//device execution
    std::cout<<"Starting GPU cutoff computation"<<std::endl;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);

    cudaEventRecord(start);

    createKeys(d_ps,height,width,z,n);

    sortByKeys(keys, idx);

    reordParticle()
    createRanges()

    kernelMultCutoff<<<DimGrid,DimBlock>>>(d_pmap,width,height,z,d_ps,n,keys,idx,dimCell);
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
    cudaFree(keys);
    cudaFree(idx);
    cudaFree(od_ps);
    cudaFree(cellStart);
    return time;

}