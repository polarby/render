class RenderException implements Exception {
  final String message;
  final Object? details;
  final bool fatal;

  const RenderException(this.message, {this.details, this.fatal = false});

  @override
  String toString() => 'RenderException($message, details: $details)';
}
