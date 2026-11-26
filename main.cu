
#define EPM_IMPLEMENTATION
#include "external/epm.hpp"
#include "seq.cu"
#include "naive.cu"
#include "tiled.cu"

#include <cstdio>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <random>

/*TODO
    move on jetson OK
    implement timing check OK

    implement basic parallel code OK


    implement enhanced parallel code OK


    implement spatial binning
*/

int main() {
    
    const int N = 100000;
    const int W = 256;
    const int H = 256;
    const int D = 256;

    // Create N particles in a WxHxD space
    const Particle* particles = epm_create_particles(N, W, H, D);
    
    // Create two potential maps slices of size 64x64 initialized to zero
    float* pmapA = epm_create_pmap_zeroed(W, H);
    float* pmapB = epm_create_pmap_zeroed(W, H);
    float* pmapC = epm_create_pmap_zeroed(W, H);

    // Calculate the potential map slice at z=32
    const int Z = 32;

//CPU COMPUTATION    
    int cpu_time = cpu_calculate_z_slice(pmapA, W, H, Z, particles, N);
    std::cout << "CPU Time: " << cpu_time << " ms\n" << std::endl;


//GPU NAIVE COMPUTATION
    float gpuN_time = gpuN_calculate_z_slice(pmapB, W, H, Z, particles,N);
    std::cout << "GPU naive time: " << gpuN_time << " ms\n" << std::endl;

    std::cout << "speedup GPU naive vs CPU x" << cpu_time/gpuN_time << "\n" << std::endl;

//GPU TILED COMPUTATION
    float gpuT_time = gpuT_calculate_z_slice(pmapC, W, H, Z, particles,N);
    std::cout << "GPU tiled time: " << gpuT_time << " ms\n" << std::endl;

    std::cout << "speedup GPU tiled vs CPU x" << cpu_time/gpuT_time << "\n" << std::endl;
    std::cout << "speedup GPU tiled vs GPU naive x" << gpuN_time/gpuT_time << "\n" << std::endl;


//GPU SPATIAL BINING COMPUTATION




    // Check if the potential maps are approximately equal
        if (epm_check_pmap_slices(pmapA, pmapB, W, H)) {
            printf("Potential maps A and B are approximately equal.\n");
    } else {
        printf("Potential maps A and B are NOT approximately equal.\n");
        for (int i = 0; i < W * H; i++) {
            if (pmapA[i] != pmapB[i]) {
                printf("Difference at index %d: pmapA=%f, pmapB=%f\n", i,pmapA[i], pmapB[i]);
            }
        }
    }
    if (epm_check_pmap_slices(pmapA, pmapC, W, H)) {
            printf("Potential maps A and C are approximately equal.\n");
    } else {
        printf("Potential maps A and C are NOT approximately equal.\n");
        for (int i = 0; i < W * H; i++) {
            if (pmapA[i] != pmapC[i]) {
                printf("Difference at index %d: pmapA=%f, pmapC=%f\n", i,pmapA[i], pmapC[i]);
            }
        }
    }


    delete[] particles;
    delete[] pmapA;
    delete[] pmapB;
    delete[] pmapC;

    return 0;
}