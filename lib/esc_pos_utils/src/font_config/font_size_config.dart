enum Size {
  //charWidth = default font width * text size multiplier
  small(sizeMultiplier: 1, charWidth: 12), // Font A width: 12
  large(sizeMultiplier: 2, charWidth: 18); // Font B width: 9

  const Size({
    required this.sizeMultiplier,
    required this.charWidth,
  });

  final int sizeMultiplier;
  final int charWidth;
}
