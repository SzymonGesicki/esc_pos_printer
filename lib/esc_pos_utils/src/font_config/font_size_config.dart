enum Size {
  //charWidth = default font width * text size multiplier
  small(
    sizeMultiplier: 1,
    charWidth: 12,
    emptyLinesBeforeCut: 4,
  ), // Font A width: 12
  large(
    sizeMultiplier: 2,
    charWidth: 18,
    emptyLinesBeforeCut: 3,
  ); // Font B width: 9

  const Size({
    required this.sizeMultiplier,
    required this.charWidth,
    required this.emptyLinesBeforeCut,
  });

  final int sizeMultiplier;
  final int charWidth;
  final int emptyLinesBeforeCut;
}
