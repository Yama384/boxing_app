import 'package:flutter/services.dart';

/// Verwirft Eingaben, die den Wert `max` überschreiten würden (z.B. Sekunden
/// über 59), statt sie zu übernehmen und dann falsch zu interpretieren.
class MaxValueTextInputFormatter extends TextInputFormatter {
  const MaxValueTextInputFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final value = int.tryParse(newValue.text);
    if (value == null || value > max) return oldValue;
    return newValue;
  }
}
