class UniversityModel {
  final String id;
  final String name;
  final String code;
  final String? city;
  final int? establishedYear;
  final bool isActive;

  const UniversityModel({
    required this.id,
    required this.name,
    required this.code,
    this.city,
    this.establishedYear,
    this.isActive = true,
  });

  factory UniversityModel.fromMap(Map<String, dynamic> m) => UniversityModel(
        id: m['id'] as String,
        name: m['name'] as String,
        code: m['code'] as String,
        city: m['city'] as String?,
        establishedYear: m['established_year'] as int?,
        isActive: m['is_active'] as bool? ?? true,
      );
}
