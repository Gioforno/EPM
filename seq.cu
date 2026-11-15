#define EPM_IMPLEMENTATION
#include "external/epm.hpp"

#include <cstdio>
#include <chrono>
#include <iomanip>
#include <iostream>

int cpu_calculate_z_slice(
    float* pmap,        // The potential map slice (width x height) 
    const int width,    // Width of the slice
    const int height,   // Height of the slice
    const int z,        // What z slice we are calculating
    const Particle* ps, // Particles of the system
    const int n         // Number of particles
)        
{

    std::cout<<"Starting CPU computation"<<std::endl;
    auto start = std::chrono::high_resolution_clock::now();

    // Iterate over all grid points in the 2D slice
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            
            float result = 0.0f;

            // Iterate over all particles
            for (int i = 0; i < n; i++) {

                float dx = (float)x - ps[i].x;
                float dy = (float)y - ps[i].y;
                float dz = (float)z - ps[i].z;

                float d = (dx*dx + dy*dy + dz*dz);
                result += ps[i].q / d;
            }

            pmap[width * y + x] = result;
        }
    }


    auto stop = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(stop - start);

    return duration.count();

}
