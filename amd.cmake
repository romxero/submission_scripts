# this is a test cmake script for compiling on the amd gpu architecture 
cmake_minimum_required(VERSION 3.28)
project(HIP_Project)


# this is for the ninja build system 
set(CMAKE_GENERATOR "Ninja")

# Find HIP package
find_package(HIP REQUIRED)

# Add HIP source files
set(SOURCE_FILES
    src/main.cpp
    src/kernel.hip.cpp
)

# Add executable target
add_executable(HIP_Project ${SOURCE_FILES})

# Link HIP libraries
target_link_libraries(HIP_Project HIP::hiprtc)

# Include HIP directories
target_include_directories(HIP_Project PRIVATE ${HIP_INCLUDE_DIRS})

# Specify HIP properties
set_target_properties(HIP_Project PROPERTIES
    CXX_STANDARD 14
    CXX_STANDARD_REQUIRED YES
    HIP_SOURCE_PROPERTY_FORMAT TRUE
)

# Add HIP compilation flags
target_compile_options(HIP_Project PRIVATE $<$<COMPILE_LANGUAGE:HIP>:-std=c++14>)

# Add HIP compile definitions if necessary
target_compile_definitions(HIP_Project PRIVATE $<$<COMPILE_LANGUAGE:HIP>:__HIP_PLATFORM_AMD__>)
