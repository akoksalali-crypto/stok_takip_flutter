class BarcodeUtils {
  /// EAN-13 kontrol basamağı hesaplayan ve 13 haneli barkod üreten yardımcı metot
  static String uretBarkod(String inBar) {
    if (inBar.isEmpty || inBar.toLowerCase() == "null") {
      return "0000000000000";
    }

    String code = inBar.length > 12 ? inBar.substring(0, 12) : inBar;
    while (code.length < 12) {
      code = '${code}0';
    }

    int sumOdd = 0;
    int sumEven = 0;

    for (int i = 0; i < 12; i++) {
      int digit = int.tryParse(code[i]) ?? 0;
      if ((i + 1) % 2 != 0) {
        sumOdd += digit;
      } else {
        sumEven += digit;
      }
    }

    int tot = (sumEven * 3) + sumOdd;
    int checkDigit = (tot % 10 == 0) ? 0 : (10 - (tot % 10));

    return "$code$checkDigit";
  }
}
