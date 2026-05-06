#pragma once

namespace math_utils {

/// Add two integers
int add(int a, int b);

/// Subtract b from a
int subtract(int a, int b);

/// Multiply two integers
int multiply(int a, int b);

/// Integer division (throws on division by zero)
int divide(int a, int b);

/// Compute factorial of n (n >= 0)
long long factorial(int n);

/// Check if a number is prime
bool is_prime(int n);

/// Compute the greatest common divisor
int gcd(int a, int b);

} // namespace math_utils
