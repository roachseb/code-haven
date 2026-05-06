#include <gtest/gtest.h>
#include "math_utils/math_utils.h"

// Integration tests — verify the library works when consumed as a dependency

TEST(CalculatorIntegration, BasicArithmetic) {
    EXPECT_EQ(math_utils::add(100, 200), 300);
    EXPECT_EQ(math_utils::subtract(100, 200), -100);
    EXPECT_EQ(math_utils::multiply(12, 12), 144);
    EXPECT_EQ(math_utils::divide(100, 10), 10);
}

TEST(CalculatorIntegration, FactorialLargeValues) {
    EXPECT_EQ(math_utils::factorial(12), 479001600);
    EXPECT_EQ(math_utils::factorial(15), 1307674368000LL);
}

TEST(CalculatorIntegration, PrimeVerification) {
    // Known primes
    EXPECT_TRUE(math_utils::is_prime(97));
    EXPECT_TRUE(math_utils::is_prime(101));
    EXPECT_TRUE(math_utils::is_prime(7919));

    // Known composites
    EXPECT_FALSE(math_utils::is_prime(100));
    EXPECT_FALSE(math_utils::is_prime(7920));
}

TEST(CalculatorIntegration, GCDEdgeCases) {
    EXPECT_EQ(math_utils::gcd(1, 1), 1);
    EXPECT_EQ(math_utils::gcd(100, 100), 100);
    EXPECT_EQ(math_utils::gcd(17, 23), 1); // coprime
}
