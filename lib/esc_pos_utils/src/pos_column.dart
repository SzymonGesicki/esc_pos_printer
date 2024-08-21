/*
 * esc_pos_utils
 * Created by Andrey U.
 * 
 * Copyright (c) 2019-2020. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'dart:typed_data' show Uint8List;

import 'package:intl/intl.dart';

import 'pos_styles.dart';

/// Column contains text, styles and width (an integer in 1..12 range)

sealed class PosColumn {
  PosColumn({
    required this.width,
    required this.styles,
  }) {
    if (width < 1 || width > 12) {
      throw Exception('Column width must be between 1..12');
    }
  }
  int width;
  PosStyles styles;

  bool get isRtl;
}

class TextPosColumn extends PosColumn {
  TextPosColumn({
    required this.text,
    required super.styles,
    required super.width,
  });

  String text;

  @override
  bool get isRtl => Bidi.detectRtlDirectionality(text);
}

class TextEncodedPosColumn extends PosColumn {
  TextEncodedPosColumn({
    required this.textEncoded,
    required this.textIsRtl,
    required super.styles,
    required super.width,
  });

  Uint8List textEncoded;
  bool textIsRtl;

  @override
  bool get isRtl => textIsRtl;
}
