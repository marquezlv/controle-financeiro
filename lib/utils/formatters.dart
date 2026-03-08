import 'package:intl/intl.dart';

String formatCurrency(double value) {
  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2);
  // Some locales put a non-breaking space after the currency symbol
  return formatter.format(value).replaceAll('\u00A0', '');
}
