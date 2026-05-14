class RevenuePoint {
  final String label;
  final double value;

  RevenuePoint({
    required this.label,
    required this.value,
  });

  factory RevenuePoint.fromJson(Map<String, dynamic> json) {
    return RevenuePoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}

class BookingPoint {
  final String label;
  final double value;

  BookingPoint({
    required this.label,
    required this.value,
  });

  factory BookingPoint.fromJson(Map<String, dynamic> json) {
    return BookingPoint(
      label: json['label'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
    );
  }
}
