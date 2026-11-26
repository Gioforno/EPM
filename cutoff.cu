#define EPM_IMPLEMENTATION
#include "external/epm.hpp"

#include <cstdio>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <cmath>
#include <cuda_runtime.h>

void computeKey(
    const Particle* d_ps,
    int height, 
    int width, 
    int z,
    int n,
    int* keys, 
    int* idx,
    int dimCell
    ) 
     {
    
    for(int i=0; i<n;i++) {
        Particle p = d_ps[i];

        int cx = floor(p.x/dimCell);
        int cy = floor(p.y/dimCell);

        keys[i] = (z*height + cy)*width+cx;
        idx[i] = i;
    }
    
}
void sortKeys(
    int* keys,
    int* idx, 
    int numCell, 
    int* cellStart, 
    int* sortIdx,
    int n
) 
    {
    int count[n];
    for(int i=0;i<n;++i){
        count[keys[i]+1]++;
    }
    for(int j = 0; j<numCell; ++j){
        count[j+1] = count[j] + count[j+1];
    }

    cellStart = count;

    for (int i = 0; i < n; ++i) {
        sortIdx[count[keys[i]]++] = i;
    }  
}

void reorderParticle(Particle* o_ps, const Particle* ps, int* idx,int n) {
    for(int i=0; i<n; i++) {
        o_ps[i] = ps[idx[i]];
    }
}

__global__ 
void kernelMult(float* d_pmap, int width, int height, int z, Particle* d_ps, int n, int dimCell, int* cellStart) {

    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

//computation of the potential
    if (row < height && col < width) {

        float result = 0.0f;

        for (int i = 0; i < n; i++) {

            int cx = floorf(col/dimCell);
            int cy = floorf(row/dimCell);

            int r_co2 = dimCell*dimCell; 

            for(int ny=max(cy-1, 0); ny<min(cy+1, height-1); ny++) {
                int s = cellStart[ny*width + max(cx-1, 0)];
                int f = cellStart[ny*width + min(cx+1, width-1) + 1];
                for (int j=s;j<f;j++) {
                    
                    float dx = (float)col - d_ps[j].x;
                    float dy = (float)row - d_ps[j].y;
                    float dz = (float)z - d_ps[j].z;
                    float d2 = dx*dx + dy*dy + dz*dz;
                    if(d2 > r_co2) {
                        continue;
                    }
                    float d = sqrtf(d);

                    result += d_ps[i].q / d;
                }
            }
            d_pmap[width * row + col] = result;
        }
    }
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
    cudaEvent_t start, stop;
    int cutoff = 3;   //range of the cutoff
    int keys[n];
    int idx[n];
    int sortIdx[n];
    
    int dimCell = cutoff*(1+10-6);  //avoid division by 0
    int numCells = (width/dimCell)*(height/dimCell);
    int cellStart[numCells+1];
    Particle* o_ps;

    auto startC = std::chrono::high_resolution_clock::now();

    computeKey(ps,height,width,z,n,keys,idx,dimCell);

    sortKeys(keys, idx, numCells, cellStart, sortIdx,n);

    reorderParticle(o_ps,ps,idx,n);

    auto stopC = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(stopC - startC);

    //mem device allocation
    Particle* od_ps;   
    cudaMalloc(&od_ps, n*sizeof(Particle));
    cudaMemcpy(od_ps, o_ps, n*sizeof(Particle), cudaMemcpyHostToDevice);


    int* d_cellStart;
    cudaMalloc(&d_cellStart, (numCells+1)*sizeof(int));
    cudaMemcpy(d_cellStart, cellStart, (numCells+1)*sizeof(int), cudaMemcpyHostToDevice);


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

    kernelMult<<<DimGrid,DimBlock>>>(d_pmap,width,height,z,od_ps,n,dimCell,cellStart);
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
    cudaFree(od_ps);
    cudaFree(cellStart);

    return duration.count()+time;

}