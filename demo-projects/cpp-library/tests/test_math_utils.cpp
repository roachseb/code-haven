#include <gtest/gtest.h>
#include "math_utils/math_utils.h"

TEST(MathUtilsTest, Add) {
    EXPECT_EQ(math_utils::add(2, 3), 5);
    EXPECT_EQ(math_utils::add(-1, 1), 0);
    EXPECT_EQ(math_utils::add(0, 0), 0);
}

TEST(MathUtilsTest, Subtract) {
    EXPECT_EQ(math_utils::subtract(5, 3), 2);
    EXPECT_EQ(math_utils::subtract(3, 5), -2);
}

TEST(MathUtilsTest, Multiply) {
    EXPECT_EQ(math_utils::multiply(3, 4), 12);
    EXPECT_EQ(math_utils::multiply(-2, 3), -6);
    EXPECT_EQ(math_utils::multiply(0, 100), 0);
}

TEST(MathUtilsTest, Divide) {
    EXPECT_EQ(math_utils::divide(10, 2), 5);
    EXPECT_EQ(math_utils::divide(7, 2), 3); // integer division
    EXPECT_THROW(math_utils::divide(1, 0), std::invalid_argument);
}

TEST(MathUtilsTest, Factorial) {
    EXPECT_EQ(math_utils::factorial(0), 1);
    EXPECT_EQ(math_utils::factorial(1), 1);
    EXPECT_EQ(math_utils::factorial(5), 120);
    EXPECT_EQ(math_utils::factorial(10), 3628800);
    EXPECT_THROW(math_utils::factorial(-1), std::invalid_argument);
}

TEST(MathUtilsTest, IsPrime) {
    EXPECT_FALSE(math_utils::is_prime(0));
    EXPECT_FALSE(math_utils::is_prime(1));
    EXPECT_TRUE(math_utils::is_prime(2));
    EXPECT_TRUE(math_utils::is_prime(3));
    EXPECT_FALSE(math_utils::is_prime(4));
    EXPECT_TRUE(math_utils::is_prime(17));
    EXPECT_FALSE(math_utils::is_prime(100));
}

TEST(MathUtilsTest, GCD) {
    EXPECT_EQ(math_utils::gcd(12, 8), 4);
    EXPECT_EQ(math_utils::gcd(7, 13), 1);
    EXPECT_EQ(math_utils::gcd(0, 5), 5);
    EXPECT_EQ(math_utils::gcd(-12, 8), 4);
}
