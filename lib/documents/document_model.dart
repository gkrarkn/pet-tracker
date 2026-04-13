class PetDocument {
  final String id;
  final String petId;
  final String title;
  final String? description;
  final String filePath;
  final String fileType; // 'image', 'pdf'
  final DateTime createdAt;

  const PetDocument({
    required this.id,
    required this.petId,
    required this.title,
    this.description,
    required this.filePath,
    required this.fileType,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'petId': petId,
        'title': title,
        'description': description,
        'filePath': filePath,
        'fileType': fileType,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PetDocument.fromMap(Map<String, dynamic> map) => PetDocument(
        id: map['id'] as String,
        petId: map['petId'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        filePath: map['filePath'] as String,
        fileType: map['fileType'] as String? ?? 'image',
        createdAt: DateTime.parse(map['createdAt'] as String),
      );

  bool get isImage => fileType == 'image';
  bool get isPdf => fileType == 'pdf';
}
