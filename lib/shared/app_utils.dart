import 'package:flutter/material.dart';

String formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}

String formatShortDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? parseTimeOfDay(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? 0,
    minute: int.tryParse(parts[1]) ?? 0,
  );
}

DateTime combineDateAndTime(DateTime date, String? time) {
  final parsed = parseTimeOfDay(time);
  return DateTime(
    date.year,
    date.month,
    date.day,
    parsed?.hour ?? 9,
    parsed?.minute ?? 0,
  );
}

DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

int daysBetween(DateTime from, DateTime to) =>
    startOfDay(to).difference(startOfDay(from)).inDays;

Color visitCategoryColor(String category) {
  switch (category) {
    case 'asi':
      return const Color(0xFF2EC4B6);
    case 'hastalik':
      return const Color(0xFFFF6B6B);
    case 'kontrol':
    default:
      return const Color(0xFF3D8BFF);
  }
}

String visitCategoryLabel(String category) {
  switch (category) {
    case 'asi':
      return 'Aşı';
    case 'hastalik':
      return 'Hastalık';
    case 'kontrol':
    default:
      return 'Kontrol';
  }
}

String careTypeLabel(String type) {
  switch (type) {
    case 'food':
      return 'Mama';
    case 'water':
      return 'Su';
    case 'toilet':
      return 'Tuvalet';
    case 'grooming':
      return 'Tüy bakımı';
    case 'bath':
      return 'Banyo';
    case 'parasite':
      return 'Parazit damlası';
    default:
      return 'Bakım';
  }
}

Color careTypeColor(String type) {
  switch (type) {
    case 'food':
      return const Color(0xFFFF9F1C);
    case 'water':
      return const Color(0xFF3D8BFF);
    case 'toilet':
      return const Color(0xFF8D6E63);
    case 'grooming':
      return const Color(0xFF9B5DE5);
    case 'bath':
      return const Color(0xFF2EC4B6);
    case 'parasite':
      return const Color(0xFFFF6B6B);
    default:
      return const Color(0xFF2EC4B6);
  }
}

String careFrequencyLabel(String frequency) {
  switch (frequency) {
    case 'daily':
      return 'Her gün';
    case 'twice_daily':
      return 'Günde 2 kez';
    case 'every_3_days':
      return '3 günde 1';
    case 'weekly':
      return 'Haftada 1';
    case 'biweekly':
      return '2 haftada 1';
    case 'monthly':
      return 'Ayda 1';
    default:
      return 'Rutin';
  }
}

Duration careFrequencyDuration(String frequency) {
  switch (frequency) {
    case 'daily':
      return const Duration(days: 1);
    case 'twice_daily':
      return const Duration(hours: 12);
    case 'every_3_days':
      return const Duration(days: 3);
    case 'weekly':
      return const Duration(days: 7);
    case 'biweekly':
      return const Duration(days: 14);
    case 'monthly':
      return const Duration(days: 30);
    default:
      return const Duration(days: 7);
  }
}

DateTime nextCareDueDate({
  required DateTime startDate,
  DateTime? lastCompletedAt,
  required String frequency,
}) {
  final base = lastCompletedAt ?? startDate;
  return base.add(careFrequencyDuration(frequency));
}

DateTime effectiveCareDueDate({
  required DateTime startDate,
  DateTime? lastCompletedAt,
  DateTime? skippedUntil,
  required String frequency,
}) {
  final computed = nextCareDueDate(
    startDate: startDate,
    lastCompletedAt: lastCompletedAt,
    frequency: frequency,
  );
  if (skippedUntil == null) return computed;
  return skippedUntil.isAfter(computed) ? skippedUntil : computed;
}

Color petThemePrimary(String key) {
  switch (key) {
    case 'coral':
      return const Color(0xFFFF6B6B);
    case 'sky':
      return const Color(0xFF3D8BFF);
    case 'gold':
      return const Color(0xFFFFB703);
    case 'mint':
      return const Color(0xFF56CFE1);
    case 'teal':
    default:
      return const Color(0xFF2EC4B6);
  }
}

Color petThemeSecondary(String key) {
  switch (key) {
    case 'coral':
      return const Color(0xFFFF8E53);
    case 'sky':
      return const Color(0xFF6C63FF);
    case 'gold':
      return const Color(0xFFFFD166);
    case 'mint':
      return const Color(0xFF80FFDB);
    case 'teal':
    default:
      return const Color(0xFF3D8BFF);
  }
}

IconData petThemeIcon(String key) {
  switch (key) {
    case 'bone':
      return Icons.pets;
    case 'paw':
      return Icons.pets;
    case 'heart':
      return Icons.favorite;
    case 'shield':
      return Icons.health_and_safety_outlined;
    case 'sparkle':
      return Icons.auto_awesome;
    case 'pets':
    default:
      return Icons.pets;
  }
}
