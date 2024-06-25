class FindMultiplesUseCase {
  static int _gcd(int a, int b) {
    while (b != 0) {
      final int temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  static int _lcm(int a, int b) {
    return (a * b) ~/ _gcd(a, b);
  }

  static List<int> findMultiples(int num1, int num2, int minRange, int maxRange) {
    final int multiple = _lcm(num1, num2);
    final List<int> multiples = [];

    for (int i = minRange; i <= maxRange; i++) {
      if (i % multiple == 0) {
        multiples.add(i);
      }
    }

    return multiples;
  }
}
