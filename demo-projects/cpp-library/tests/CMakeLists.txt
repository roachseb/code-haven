find_package(GTest REQUIRED)

add_executable(test_math_utils test_math_utils.cpp)

target_link_libraries(test_math_utils
    PRIVATE
        math-utils
        GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(test_math_utils)
