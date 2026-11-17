
#define EPM_IMPLEMENTATION
#include "external/epm.hpp"
#include "seq.cu"
#include "naive.cu"

#include <cstdio>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <random>

/*TODO
    move on jetson OK
    implement timing check OK

    implement basic parallel code


    implement enhanced parallel code


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
    



    // Calculate the potential map slice at z=32
    const int Z = 32;

    int cpu_time = cpu_calculate_z_slice(pmapA, W, H, Z, particles, N);
    std::cout << "CPU Time: " << cpu_time << " ms\n" << std::endl;

    float gpuN_time = gpuN_calculate_z_slice(pmapB, W, H, Z, particles,N);
    std::cout << "GPU naive time: " << gpuN_time << " ms\n" << std::endl;

    std::cout << "speedup GPU naive x" << cpu_time/gpuN_time << "\n" << std::endl;

    // Check if the potential maps are approximately equal
    if (epm_check_pmap_slices(pmapA, pmapB, W, H)) {
        printf("Potential maps are approximately equal.\n");
    } else {
        printf("Potential maps are NOT approximately equal.\n");
        for (int i = 0; i < W * H; i++) {
            if (pmapA[i] != pmapB[i]) {
                printf("Difference at index %d: pmapA=%f, pmapB=%f\n", i, pmapA[i], pmapB[i]);
            }
        }
    }

    delete[] particles;
    delete[] pmapA;
    delete[] pmapB;

    return 0;
}