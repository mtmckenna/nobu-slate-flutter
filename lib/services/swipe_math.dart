final _matchRe = RegExp(r'^(\d*)([A-Z]?)$');

String swipeValue(String oldValue, int direction) {
  final upper = oldValue.toUpperCase();
  final m = _matchRe.firstMatch(upper);
  if (m == null) return oldValue;

  final numberStr = m.group(1) ?? '';
  final letter = m.group(2) ?? '';
  final width = numberStr.length;
  final number = int.tryParse(numberStr) ?? 1;

  if (letter.isNotEmpty) {
    return '$numberStr${_nextLetter(letter, direction)}';
  }

  final newNumber = direction > 0 ? number + 1 : (number - 1).clamp(1, 1 << 30);
  return newNumber.toString().padLeft(width, '0');
}

String _nextLetter(String letter, int direction) {
  final code = letter.codeUnitAt(0);
  if (direction > 0 && code < 'Z'.codeUnitAt(0)) {
    return String.fromCharCode(code + 1);
  }
  if (direction < 0 && code > 'A'.codeUnitAt(0)) {
    return String.fromCharCode(code - 1);
  }
  return letter;
}
