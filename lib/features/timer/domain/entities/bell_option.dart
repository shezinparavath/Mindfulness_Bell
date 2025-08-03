class BellOption {
  final String name;
  final String icon;

  BellOption(this.name, this.icon);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BellOption &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          icon == other.icon;

  @override
  int get hashCode => name.hashCode ^ icon.hashCode;
}
