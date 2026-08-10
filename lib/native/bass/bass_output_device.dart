class BassOutputDevice {
  const BassOutputDevice({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final int id;
  final String name;
  final bool isDefault;

  String get label => isDefault ? '$name（默认）' : name;
}
