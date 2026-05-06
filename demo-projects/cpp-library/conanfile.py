from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout, CMakeToolchain, CMakeDeps


class MathUtilsConan(ConanFile):
    name = "math-utils"
    version = "1.0.0"
    license = "MIT"
    description = "A simple math utilities library — Code Haven demo project"
    settings = "os", "compiler", "build_type", "arch"
    exports_sources = "CMakeLists.txt", "src/*", "include/*", "tests/*"

    def layout(self):
        cmake_layout(self)

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()

    def package_info(self):
        self.cpp_info.libs = ["math-utils"]

    def build_requirements(self):
        self.test_requires("gtest/1.14.0")
