// ignore_for_file: prefer_final_locals, avoid_function_literals_in_foreach_calls

/*
 * esc_pos_utils
 * Created by Andrey U.
 * 
 * Copyright (c) 2019-2020. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'dart:typed_data' show Uint8List;

import 'package:bidi/bidi.dart' as bidi;
import 'package:enough_convert/latin.dart';
import 'package:esc_pos_printer/esc_pos_utils/src/barcode.dart';
import 'package:esc_pos_printer/esc_pos_utils/src/capability_profile.dart';
import 'package:esc_pos_printer/esc_pos_utils/src/enums.dart';
import 'package:esc_pos_printer/esc_pos_utils/src/font_config/font_size_config.dart';
import 'package:esc_pos_printer/esc_pos_utils/src/pos_column.dart';
import 'package:esc_pos_printer/esc_pos_utils/src/pos_styles.dart';
import 'package:esc_pos_printer/esc_pos_utils/src/qrcode.dart';
import 'package:hex/hex.dart';
import 'package:intl/intl.dart';

import 'commands.dart';
import 'not_supported_characters.dart';

class Generator {
  Generator(
    this._printableWidth,
    this._profile,
    this.leftMarginDots,
  );

  // Ticket config
  final PrintableWidth _printableWidth;
  final CapabilityProfile _profile;
  final int leftMarginDots;

  // Global styles
  String? _codeTable;

  // Current styles
  PosStyles _styles = const PosStyles();

  // ************************ Internal helpers ************************
  int _getMaxCharsPerLine(Size fontSize) => (_printableWidth.value / fontSize.charWidth).floor();

  double _colIndToPosition(int colInd) {
    final int width = _printableWidth.value;
    return (colInd == 0 ? 0 : (width * colInd / 12 - 1)) + leftMarginDots.toDouble();
  }

  Uint8List _encode(String text) {
    var textToEncode = text;
    notSupportedCharactersForBidi.forEach((element) {
      textToEncode = textToEncode.replaceAll(String.fromCharCode(element.asci), element.replaceTo);
    });
    final visual = bidi.logicalToVisual(textToEncode);
    var decoded = String.fromCharCodes(visual);
    notSupportedCharactersForPrint.forEach((element) {
      decoded = decoded.replaceAll(String.fromCharCode(element.asci), element.replaceTo);
    });

    return Uint8List.fromList(const Latin8Codec(allowInvalid: true).encode(decoded));
  }

  // ************************ (end) Internal helpers  ************************

  //**************************** Public command generators ************************
  /// Clear the buffer and reset text styles
  List<int> reset() {
    List<int> bytes = [];
    bytes += cInit.codeUnits;
    _styles = const PosStyles();
    bytes += setGlobalCodeTable(_codeTable);
    return bytes;
  }

  /// Set global code table which will be used instead of the default printer's code table
  /// (even after resetting)
  List<int> setGlobalCodeTable(String? codeTable) {
    List<int> bytes = [];
    _codeTable = codeTable;
    if (codeTable != null) {
      bytes += Uint8List.fromList(
        List.from(cCodeTable.codeUnits)..add(_profile.getCodePageId(codeTable)),
      );
      _styles = _styles.copyWith(codeTable: codeTable);
    }
    return bytes;
  }

  List<int> setStyles(PosStyles styles) {
    List<int> bytes = [];

    // unlike other styles, align is set every time because the printer
    // does not remember the previous settings after printing a row
    bytes += const Latin8Codec().encode(styles.align == PosAlign.left
        ? cAlignLeft
        : (styles.align == PosAlign.center ? cAlignCenter : cAlignRight));

    _styles = _styles.copyWith(align: styles.align);

    if (styles.bold != _styles.bold) {
      bytes += styles.bold ? cBoldOn.codeUnits : cBoldOff.codeUnits;
      _styles = _styles.copyWith(bold: styles.bold);
    }
    if (styles.turn90 != _styles.turn90) {
      bytes += styles.turn90 ? cTurn90On.codeUnits : cTurn90Off.codeUnits;
      _styles = _styles.copyWith(turn90: styles.turn90);
    }
    if (styles.reverse != _styles.reverse) {
      bytes += styles.reverse ? cReverseOn.codeUnits : cReverseOff.codeUnits;
      _styles = _styles.copyWith(reverse: styles.reverse);
    }
    if (styles.underline != _styles.underline) {
      bytes += styles.underline ? cUnderline1dot.codeUnits : cUnderlineOff.codeUnits;
      _styles = _styles.copyWith(underline: styles.underline);
    }

    // Set font
    // Characters size
    switch (styles.fontSize) {
      case Size.small:
        if (_styles.fontSize != Size.small) {
          bytes += _linesSpacingCommand(Size.small.lineSpacing);
          bytes += _lettersSpacingCommand(Size.small.letterSpacing);
          bytes += cFontA.codeUnits;
          bytes += Uint8List.fromList(
            List.from(cSizeGSn.codeUnits)..add(PosTextSize.decSize(styles.fontSize)),
          );
          _styles = _styles.copyWith(fontSize: Size.small);
        }
      case Size.large:
        if (_styles.fontSize != Size.large) {
          bytes += _linesSpacingCommand(Size.large.lineSpacing);
          bytes += _lettersSpacingCommand(Size.large.letterSpacing);
          bytes += cFontB.codeUnits;
          bytes += Uint8List.fromList(
            List.from(cSizeGSn.codeUnits)..add(PosTextSize.decSize(styles.fontSize)),
          );
          _styles = _styles.copyWith(fontSize: Size.large);
        }
    }

    // Set local code table
    if (styles.codeTable != null) {
      bytes += Uint8List.fromList(
        List.from(cCodeTable.codeUnits)..add(_profile.getCodePageId(styles.codeTable)),
      );
      _styles = _styles.copyWith(align: styles.align, codeTable: styles.codeTable);
    } else if (_codeTable != null) {
      bytes += Uint8List.fromList(
        List.from(cCodeTable.codeUnits)..add(_profile.getCodePageId(_codeTable)),
      );
      _styles = _styles.copyWith(align: styles.align, codeTable: _codeTable);
    }

    return bytes;
  }

  List<int> _linesSpacingCommand(int spacing) => [27, 51, spacing];

  List<int> _lettersSpacingCommand(int spacing) => [27, 32, spacing];

  /// Sens raw command(s)
  List<int> rawBytes(List<int> cmd, {bool isKanji = false}) {
    List<int> bytes = [];
    if (!isKanji) {
      bytes += cKanjiOff.codeUnits;
    }
    bytes += Uint8List.fromList(cmd);
    return bytes;
  }

  List<int> text({
    required String text,
    PosStyles styles = const PosStyles(),
    int linesAfter = 0,
  }) {
    List<int> bytes = [];

    bytes += _simpleText(
      textBytes: _encode(text),
      styles: styles,
      isRtl: Bidi.detectRtlDirectionality(text),
    );
    // Ensure at least one line break after the text
    bytes += emptyLines(linesAfter + 1);

    return bytes;
  }

  /// Skips [n] lines
  ///
  /// Similar to [feed] but uses an alternative command
  List<int> emptyLines(int n) {
    List<int> bytes = [];
    if (n > 0) {
      bytes += List.filled(n, '\n').join().codeUnits;
    }
    return bytes;
  }

  /// Skips [n] lines
  ///
  /// Similar to [emptyLines] but uses an alternative command
  List<int> feed(int n) {
    List<int> bytes = [];
    if (n >= 0 && n <= 255) {
      bytes += Uint8List.fromList(
        List.from(cFeedN.codeUnits)..add(n),
      );
    }
    return bytes;
  }

  /// Cut the paper
  ///
  /// [mode] is used to define the full or partial cut (if supported by the priner)
  List<int> cut({PosCutMode mode = PosCutMode.full}) {
    List<int> bytes = [];

    bytes += emptyLines(_styles.fontSize.emptyLinesBeforeCut);

    if (mode == PosCutMode.partial) {
      bytes += cCutPart.codeUnits;
    } else {
      bytes += cCutFull.codeUnits;
    }
    return bytes;
  }

  /// Print selected code table.
  ///
  /// If [codeTable] is null, global code table is used.
  /// If global code table is null, default printer code table is used.
  List<int> printCodeTable({String? codeTable}) {
    List<int> bytes = [];
    bytes += cKanjiOff.codeUnits;

    if (codeTable != null) {
      bytes += Uint8List.fromList(
        List.from(cCodeTable.codeUnits)..add(_profile.getCodePageId(codeTable)),
      );
    }

    bytes += Uint8List.fromList(List<int>.generate(256, (i) => i));

    // Back to initial code table
    setGlobalCodeTable(_codeTable);
    return bytes;
  }

  /// Beeps [n] times
  ///
  /// Beep [duration] could be between 50 and 450 ms.
  List<int> beep({int n = 3, PosBeepDuration duration = PosBeepDuration.beep450ms}) {
    List<int> bytes = [];
    if (n <= 0) {
      return [];
    }

    int beepCount = n;
    if (beepCount > 9) {
      beepCount = 9;
    }

    bytes += Uint8List.fromList(
      List.from(cBeep.codeUnits)..addAll([beepCount, duration.value]),
    );

    beep(n: n - 9, duration: duration);
    return bytes;
  }

  /// Reverse feed for [n] lines (if supported by the priner)
  List<int> reverseFeed(int n) {
    List<int> bytes = [];
    bytes += Uint8List.fromList(
      List.from(cReverseFeedN.codeUnits)..add(n),
    );
    return bytes;
  }

  /// Print a row.
  ///
  /// A row contains up to 12 columns. A column has a width between 1 and 12.
  /// Total width of columns in one row must be equal 12.
  List<int> row(List<PosColumn> posColumns) {
    List<int> bytes = [];
    final isSumValid = posColumns.fold(0, (int sum, col) => sum + col.width) == 12;
    if (!isSumValid) {
      throw Exception('Total columns width must be equal to 12');
    }
    bool isNextRow = false;
    List<PosColumn> nextRow = <PosColumn>[];

    for (int i = 0; i < posColumns.length; ++i) {
      final posColumn = posColumns[i];
      int colInd = posColumns.sublist(0, i).fold(0, (int sum, column) => sum + column.width);
      double charWidth = posColumn.styles.fontSize.charWidth.toDouble();
      double fromPos = _colIndToPosition(colInd);
      final double toPos = _colIndToPosition(colInd + posColumn.width);
      int maxCharactersNb = ((toPos - fromPos) / charWidth).floor();

      Uint8List encodedData = switch (posColumn) {
        TextPosColumn value => _encode(value.text),
        TextEncodedPosColumn value => value.textEncoded,
      };

      final splitData = _splitEncodedText(encodedData, maxCharactersNb, posColumn.isRtl);

      if (splitData.encodedToPrintNextLine != null) {
        isNextRow = true;
        nextRow.add(
          TextEncodedPosColumn(
            textEncoded: splitData.encodedToPrintNextLine!,
            width: posColumn.width,
            styles: posColumn.styles,
            textIsRtl: posColumn.isRtl,
          ),
        );
      } else {
        // Insert an empty col
        nextRow.add(TextPosColumn(text: '', width: posColumn.width, styles: posColumn.styles));
      }

      // end rows splitting
      bytes += _rowText(
        textBytes: splitData.encodedToPrint,
        styles: posColumn.styles,
        colInd: colInd,
        colWidth: posColumn.width,
      );
    }

    bytes += emptyLines(1);

    if (isNextRow) {
      bytes += row(nextRow);
    }
    return bytes;
  }

  /// Print a barcode
  ///
  /// [width] range and units are different depending on the printer model (some printers use 1..5).
  /// [height] range: 1 - 255. The units depend on the printer model.
  /// Width, height, font, text position settings are effective until performing of ESC @, reset or power-off.
  List<int> barcode(
    Barcode barcode, {
    int? width,
    int? height,
    BarcodeFont? font,
    BarcodeText textPos = BarcodeText.below,
    PosAlign align = PosAlign.center,
  }) {
    List<int> bytes = [];
    // Set alignment
    bytes += setStyles(const PosStyles().copyWith(align: align));

    // Set text position
    bytes += cBarcodeSelectPos.codeUnits + [textPos.value];

    // Set font
    if (font != null) {
      bytes += cBarcodeSelectFont.codeUnits + [font.value];
    }

    // Set width
    if (width != null && width >= 0) {
      bytes += cBarcodeSetW.codeUnits + [width];
    }
    // Set height
    if (height != null && height >= 1 && height <= 255) {
      bytes += cBarcodeSetH.codeUnits + [height];
    }

    // Print barcode
    final header = cBarcodePrint.codeUnits + [barcode.type!.value];
    if (barcode.type!.value <= 6) {
      // Function A
      bytes += header + barcode.data! + [0];
    } else {
      // Function B
      bytes += header + [barcode.data!.length] + barcode.data!;
    }
    return bytes;
  }

  /// Print a QR Code
  List<int> qrcode(
    String text, {
    PosAlign align = PosAlign.center,
    QRSize size = QRSize.Size4,
    QRCorrection cor = QRCorrection.L,
  }) {
    List<int> bytes = [];
    // Set alignment
    bytes += setStyles(const PosStyles().copyWith(align: align));
    QRCode qr = QRCode(text, size, cor);
    bytes += qr.bytes;
    return bytes;
  }

  /// Print horizontal full width separator
  /// If [len] is null, then it will be defined according to the paper width
  List<int> hr({
    String ch = '-',
    int? len,
    int linesAfter = 0,
    PosStyles styles = const PosStyles(),
  }) {
    List<int> bytes = [];
    int n = len ?? _getMaxCharsPerLine(styles.fontSize);
    String ch1 = ch.length == 1 ? ch : ch[0];
    bytes += text(text: List.filled(n, ch1).join(), linesAfter: linesAfter, styles: styles);
    return bytes;
  }

  List<int> openCashDrawer({required int pin}) {
    // ESC p m t1 t2
    // p -> 112
    // m -> pin connector (0, 1)
    // t1 t2 -> on off impulse milliseconds
    const t1 = 120;
    const t2 = 240;
    List<int> bytes = [];
    bytes += esc.codeUnits;
    bytes += [112, pin, t1, t2];

    return bytes;
  }

  List<int> buzzerCommand({
    required int volume,
    required BuzzerDuration duration,
  }) {
    return [
      ..._setBuzzerVolume(volume),
      ..._setBuzzerDuration(duration.value),
      ..._setBuzzerDuration(0),
    ];
  }

  // ************************ (end) Public command generators ************************

  // ************************ (end) Internal command generators ************************

  List<int> _setBuzzerVolume(int volume) {
    return [29, 153, 66, 69, 146, 154, 86, 1, volume.clamp(0, 255)];
  }

  List<int> _setBuzzerDuration(int duration) {
    return [27, 8, duration];
  }

  /// Generic print for internal use
  ///
  /// [colInd] range: 0..11. If null: do not define the position
  List<int> _rowText({
    required Uint8List textBytes,
    required PosStyles styles,
    required int colInd,
    required int colWidth,
  }) {
    List<int> bytes = [];
    double charWidth = styles.fontSize.charWidth.toDouble();
    double fromPos = _colIndToPosition(colInd);

    // Align
    if (colWidth != 12) {
      // Update fromPos
      final double toPos = _colIndToPosition(colInd + colWidth);
      final double textLen = textBytes.length * charWidth;

      if (styles.align == PosAlign.right) {
        fromPos = toPos - textLen;
      } else if (styles.align == PosAlign.center) {
        fromPos = fromPos + (toPos - fromPos) / 2 - textLen / 2;
      }
      if (fromPos < 0) {
        fromPos = 0;
      }
    }

    bytes += _textPositionCommand(fromPos);
    bytes += setStyles(styles);

    bytes += textBytes;
    return bytes;
  }

  List<int> _simpleText({
    required Uint8List textBytes,
    required PosStyles styles,
    required bool isRtl,
  }) {
    List<int> bytes = [];
    final data = _splitEncodedText(textBytes, _getMaxCharsPerLine(styles.fontSize), isRtl);

    bytes += _textPositionCommand(_colIndToPosition(0));
    bytes += setStyles(styles);
    bytes += data.encodedToPrint;

    if (data.encodedToPrintNextLine != null) {
      bytes += emptyLines(1);
      bytes += _simpleText(textBytes: data.encodedToPrintNextLine!, styles: styles, isRtl: isRtl);
    }

    return bytes;
  }

  List<int> _textPositionCommand(double fromPos) {
    final hexStr = fromPos.round().toRadixString(16).padLeft(3, '0');
    final hexPair = HEX.decode(hexStr);

    // Position
    return Uint8List.fromList(
      List.from(cPos.codeUnits)..addAll([hexPair[1], hexPair[0]]),
    );
  }

  ({Uint8List encodedToPrint, Uint8List? encodedToPrintNextLine}) _splitEncodedText(
      Uint8List encodedText, int maxCharacters, bool isRtl) {
    if (encodedText.length > maxCharacters) {
      if (isRtl) {
        return (
          encodedToPrint: encodedText.sublist(encodedText.length - maxCharacters),
          encodedToPrintNextLine: encodedText.sublist(0, encodedText.length - maxCharacters),
        );
      } else {
        return (
          encodedToPrint: encodedText.sublist(0, maxCharacters),
          encodedToPrintNextLine: encodedText.sublist(maxCharacters),
        );
      }
    } else {
      return (
        encodedToPrint: encodedText,
        encodedToPrintNextLine: null,
      );
    }
  }

// ************************ (end) Internal command generators ************************
}
