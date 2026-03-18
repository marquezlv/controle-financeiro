import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

final NumberFormat _brCurrencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

String formatCurrency(double value) {
  // Some locales put non-breaking/normal spaces after currency symbol.
  return _brCurrencyFormatter
      .format(value)
      .replaceAll('\u00A0', '')
      .replaceAll(' ', '');
}

double parseCurrencyInput(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return double.parse(digits) / 100;
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final value = double.parse(digits) / 100;
    final formatted = formatCurrency(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
