import 'package:esc_pos_printer/esc_pos_utils/src/font_config/find_multuples_use_case.dart';

enum Size {
  //charWidth = default font width * text size multiplier
  small(
    sizeMultiplier: 1,
    fontWidth: 12,
    emptyLinesBeforeCut: 4,
    letterSpacing: 0,
  ), // Font A width: 12
  large(
    sizeMultiplier: 2,
    fontWidth: 9,
    emptyLinesBeforeCut: 3,
    letterSpacing: 3,
  ); // Font B width: 9

  const Size({
    required this.sizeMultiplier,
    required this.fontWidth,
    required this.emptyLinesBeforeCut,
    required this.letterSpacing,
  });

  final int sizeMultiplier;
  final int emptyLinesBeforeCut;
  final int letterSpacing;
  final int fontWidth;

  int get charWidth => (fontWidth + letterSpacing) * sizeMultiplier;

  static List<int> availablePaperSize() =>
      FindMultiplesUseCase.findMultiples(Size.small.charWidth, Size.large.charWidth, 300, 600);
}
