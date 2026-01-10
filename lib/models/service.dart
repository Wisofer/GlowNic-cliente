import '../utils/money_formatter.dart';

class ServiceDto {
  final int id;
  final String name;
  final double price;
  final int durationMinutes;
  final bool isActive;

  ServiceDto({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.isActive = true,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> json) => ServiceDto(
        id: json['id'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        durationMinutes: json['durationMinutes'],
        isActive: json['isActive'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'durationMinutes': durationMinutes,
        'isActive': isActive,
      };

  String get formattedPrice {
    // Usar MoneyFormatter para formato con separadores de miles
    final rounded = price.round();
    return 'C\$${MoneyFormatter.formatWithThousands(rounded)}';
  }
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '$durationMinutes min';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (minutes == 0) {
      return '$hours h';
    }
    return '$hours h $minutes min';
  }
}

