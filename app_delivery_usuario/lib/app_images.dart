const _assets = [
  'images/plza-22.jpg',
  'images/Chepepepe.png',
  'images/320.jpg',
  'images/35847.jpg',
];

String assetForKey(String key) {
  final hash = key.codeUnits.fold(0, (a, b) => a + b);
  return _assets[hash % _assets.length];
}
