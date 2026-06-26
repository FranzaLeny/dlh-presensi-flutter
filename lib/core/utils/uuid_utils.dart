// ====================================
// UUID v7 Generator — Time-based UUID
// ====================================

import 'dart:math';

/// Generates a cryptographically-like time-based UUID v7.
/// Format: xxxxxxxx-xxxx-7xxx-yxxx-xxxxxxxxxxxx
String uuidv7() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final timestampHex = now.toRadixString(16).padLeft(12, '0');

  final random = Random();

  // 4 bits version (7) + 12 bits random
  final randA = random.nextInt(0x1000);
  final verAndRandA = (0x7000 | randA).toRadixString(16).padLeft(4, '0');

  // 2 bits variant (8, 9, a, b) + 62 bits random
  const variantChars = ['8', '9', 'a', 'b'];
  final variant = variantChars[random.nextInt(4)];

  final randB = StringBuffer();
  for (var i = 0; i < 15; i++) {
    randB.write(random.nextInt(16).toRadixString(16));
  }
  final randBStr = randB.toString();

  return '${timestampHex.substring(0, 8)}-'
      '${timestampHex.substring(8, 12)}-'
      '$verAndRandA-'
      '$variant${randBStr.substring(0, 3)}-'
      '${randBStr.substring(3)}';
}
