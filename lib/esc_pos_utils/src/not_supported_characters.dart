class NotSupportedCharacter {
  NotSupportedCharacter({
    required this.asci,
    this.replacteTo = '@',
  });
  final int asci;
  final String replacteTo;
}

List<NotSupportedCharacter> notSupportedCharactersForBidi = [
  NotSupportedCharacter(asci: 8207, replacteTo: ''),
];

List<NotSupportedCharacter> notSupportedCharactersForPrint = [
  NotSupportedCharacter(asci: 8364),
  NotSupportedCharacter(asci: 8218),
  NotSupportedCharacter(asci: 402),
  NotSupportedCharacter(asci: 8222),
  NotSupportedCharacter(asci: 8230),
  NotSupportedCharacter(asci: 8224),
  NotSupportedCharacter(asci: 8225),
  NotSupportedCharacter(asci: 710),
  NotSupportedCharacter(asci: 8240),
  NotSupportedCharacter(asci: 8249),
  NotSupportedCharacter(asci: 8216),
  NotSupportedCharacter(asci: 8217),
  NotSupportedCharacter(asci: 8220),
  NotSupportedCharacter(asci: 8221),
  NotSupportedCharacter(asci: 8226),
  NotSupportedCharacter(asci: 8211),
  NotSupportedCharacter(asci: 8212),
  NotSupportedCharacter(asci: 732),
  NotSupportedCharacter(asci: 8482),
  NotSupportedCharacter(asci: 8250),
  NotSupportedCharacter(asci: 161),
  NotSupportedCharacter(asci: 8362),
  NotSupportedCharacter(asci: 191),
  NotSupportedCharacter(asci: 1456),
  NotSupportedCharacter(asci: 1457),
  NotSupportedCharacter(asci: 1458),
  NotSupportedCharacter(asci: 1459),
  NotSupportedCharacter(asci: 1460),
  NotSupportedCharacter(asci: 1461),
  NotSupportedCharacter(asci: 1462),
  NotSupportedCharacter(asci: 1463),
  NotSupportedCharacter(asci: 1464),
  NotSupportedCharacter(asci: 1467),
  NotSupportedCharacter(asci: 1468),
  NotSupportedCharacter(asci: 1469),
  NotSupportedCharacter(asci: 1470),
  NotSupportedCharacter(asci: 1471),
  NotSupportedCharacter(asci: 1472),
  NotSupportedCharacter(asci: 1473),
  NotSupportedCharacter(asci: 1474),
  NotSupportedCharacter(asci: 1475),
  NotSupportedCharacter(asci: 1520),
  NotSupportedCharacter(asci: 1521),
  NotSupportedCharacter(asci: 1522),
  NotSupportedCharacter(asci: 1523),
  NotSupportedCharacter(asci: 1524),
  NotSupportedCharacter(asci: 8207, replacteTo: ''),
  NotSupportedCharacter(asci: 160, replacteTo: ''),
];
