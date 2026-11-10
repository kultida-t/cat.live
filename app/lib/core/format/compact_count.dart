/// ย่อตัวเลขยอดไลก์/คอมเมนต์ให้อ่านง่าย — 1,200 → 1.2K, 12,000 → 12K (ตามเว็บ)
String compactCount(int value) {
  if (value < 1000) return '$value';
  final k = value / 1000;
  final text = k.toStringAsFixed(value >= 10000 ? 0 : 1);
  return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}K';
}
