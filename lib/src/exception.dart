class RenderException implements Exception {
  final String message;
  final Object? details;

  const RenderException(this.message, {this.details});

  @override
  String toString() => 'RenderException($message, details: $details)';
}
