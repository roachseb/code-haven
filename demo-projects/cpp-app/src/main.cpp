#include <iostream>
#include "math_utils/math_utils.h"

int main() {
    std::cout << "=== Calculator App (using math-utils library) ===" << std::endl;
    std::cout << std::endl;

    std::cout << "Addition: 5 + 3 = " << math_utils::add(5, 3) << std::endl;
    std::cout << "Subtraction: 10 - 4 = " << math_utils::subtract(10, 4) << std::endl;
    std::cout << "Multiplication: 6 * 7 = " << math_utils::multiply(6, 7) << std::endl;
    std::cout << "Division: 15 / 3 = " << math_utils::divide(15, 3) << std::endl;
    std::cout << "Factorial: 8! = " << math_utils::factorial(8) << std::endl;
    std::cout << "GCD(48, 18) = " << math_utils::gcd(48, 18) << std::endl;

    std::cout << std::endl;
    std::cout << "Prime check:" << std::endl;
    for (int i = 2; i <= 20; ++i) {
        if (math_utils::is_prime(i)) {
            std::cout << "  " << i << " is prime" << std::endl;
        }
    }

    return 0;
}
