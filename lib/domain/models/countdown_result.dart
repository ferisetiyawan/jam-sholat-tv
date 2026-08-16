/// Result of computing the next prayer from a jadwal (prayer times) map.
class CountdownResult {
  /// Display name of the next upcoming prayer.
  final String nextName;

  /// Formatted countdown string in `HH:mm:ss` format.
  final String countdown;

  const CountdownResult({required this.nextName, required this.countdown});
}
