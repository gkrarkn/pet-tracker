class Pet {
  final String id;
  final String name;
  final String species;
  final String breed;
  final DateTime birthDate;
  final String? photoUrl;
  final String themeColor;
  final String themeIcon;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.birthDate,
    this.photoUrl,
    this.themeColor = 'teal',
    this.themeIcon = 'pets',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'birthDate': birthDate.toIso8601String(),
      'photoUrl': photoUrl,
      'themeColor': themeColor,
      'themeIcon': themeIcon,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as String,
      name: map['name'] as String,
      species: map['species'] as String,
      breed: map['breed'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
      photoUrl: map['photoUrl'] as String?,
      themeColor: map['themeColor'] as String? ?? 'teal',
      themeIcon: map['themeIcon'] as String? ?? 'pets',
    );
  }

  Pet copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    DateTime? birthDate,
    String? photoUrl,
    String? themeColor,
    String? themeIcon,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      birthDate: birthDate ?? this.birthDate,
      photoUrl: photoUrl ?? this.photoUrl,
      themeColor: themeColor ?? this.themeColor,
      themeIcon: themeIcon ?? this.themeIcon,
    );
  }
}
