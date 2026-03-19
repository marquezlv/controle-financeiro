import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

final NumberFormat _brCurrencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

// Map of currency codes to their formatters
final Map<String, NumberFormat> _currencyFormatters = {
  'BRL': NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ),
  'USD': NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  ),
  'EUR': NumberFormat.currency(
    locale: 'de_DE',
    symbol: '€',
    decimalDigits: 2,
  ),
  'GBP': NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 2,
  ),
  'JPY': NumberFormat.currency(
    locale: 'ja_JP',
    symbol: '¥',
    decimalDigits: 0,
  ),
  'INR': NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  ),
};

String formatCurrency(double value) {
  // Some locales put non-breaking/normal spaces after currency symbol.
  return _brCurrencyFormatter
      .format(value)
      .replaceAll('\u00A0', '')
      .replaceAll(' ', '');
}

/// Format a value using the specified currency code.
/// Defaults to BRL if currency code is not found.
String formatCurrencyForCode(double value, String currencyCode) {
  final formatter = _currencyFormatters[currencyCode] ?? _brCurrencyFormatter;
  return formatter
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
  final String currencyCode;

  CurrencyInputFormatter({this.currencyCode = 'BRL'});

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
    final formatted = formatCurrencyForCode(value, currencyCode);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
