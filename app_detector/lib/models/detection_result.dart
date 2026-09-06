class DetectionResult {
  final List<String> summary;
  final String message;
  final String image;
  final int elapsedMs;

  const DetectionResult({
    required this.summary,
    required this.message,
    required this.image,
    required this.elapsedMs,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) {
    return DetectionResult(
      summary: List<String>.from(json['summary'] ?? []),
      message: json['message'] ?? '',
      image: json['image'] ?? '',
      elapsedMs: json['elapsed_ms'] ?? 0,
    );
  }
}
