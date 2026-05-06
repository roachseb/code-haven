find_package(GTest REQUIRED)

add_executable(test_calculator test_calculator.cpp)

target_link_libraries(test_calculator
    PRIVATE
        math-utils::math-utils
        GTest::gtest_main
)

include(GoogleTest)
gtest_discover_tests(test_calculator)
