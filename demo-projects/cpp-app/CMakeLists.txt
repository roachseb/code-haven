cmake_minimum_required(VERSION 3.20)
project(calculator-app VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Find the math-utils library (provided by Conan)
find_package(math-utils REQUIRED)

# Application binary
add_executable(calculator-app src/main.cpp)
target_link_libraries(calculator-app PRIVATE math-utils::math-utils)

# Install
install(TARGETS calculator-app RUNTIME DESTINATION bin)

# Testing
option(BUILD_TESTS "Build unit tests" ON)
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
