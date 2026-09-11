import 'package:flutter/foundation.dart';
import '../../../database/models/hive_family_photo.dart';

@immutable
class FamilyPhoto {
  const FamilyPhoto({
    required this.id,
    required this.patientId,
    required this.name,
    required this.relationship,
    required this.photoUrl,
    this.localPath,
    this.localBytes,
    this.audioNoteUrl,
    this.displayOrder = 0,
    this.isActive = true,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final String name;
  final String relationship;
  final String photoUrl;
  final String? localPath;
  final Uint8List? localBytes;
  final String? audioNoteUrl;
  final int displayOrder;
  final bool isActive;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasPhoto =>
      photoUrl.isNotEmpty ||
      (localPath?.isNotEmpty ?? false) ||
      (localBytes?.isNotEmpty ?? false);

  factory FamilyPhoto.fromMap(Map<String, dynamic> map) {
    final created =
        DateTime.tryParse('${map['created_at'] ?? ''}') ?? DateTime.now();
    final updated = DateTime.tryParse('${map['updated_at'] ?? ''}') ?? created;
    return FamilyPhoto(
      id: '${map['id'] ?? ''}',
      patientId: '${map['patient_id'] ?? ''}',
      name: '${map['title'] ?? map['name'] ?? ''}',
      relationship: '${map['relationship'] ?? ''}',
      photoUrl: '${map['photo_url'] ?? ''}',
      localPath: map['local_path'] as String?,
      localBytes: map['local_bytes'] is Uint8List
          ? map['local_bytes'] as Uint8List
          : null,
      audioNoteUrl: map['audio_note_url'] as String?,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      isDeleted: map['is_deleted'] as bool? ?? false,
      createdAt: created,
      updatedAt: updated,
    );
  }

  factory FamilyPhoto.fromHive(HiveFamilyPhoto photo) => FamilyPhoto(
    id: photo.id,
    patientId: photo.patientId,
    name: photo.name,
    relationship: photo.relationship,
    photoUrl: photo.photoUrl,
    localPath: photo.localPath,
    localBytes: photo.localBytes,
    displayOrder: photo.displayOrder,
    isDeleted: photo.isDeleted,
    createdAt: photo.createdAt,
    updatedAt: photo.updatedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patient_id': patientId,
    'title': name,
    'relationship': relationship,
    'photo_url': photoUrl,
    'local_path': localPath,
    'audio_note_url': audioNoteUrl,
    'display_order': displayOrder,
    'is_active': isActive,
    'is_deleted': isDeleted,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  FamilyPhoto copyWith({
    String? name,
    String? relationship,
    String? photoUrl,
    String? localPath,
    Uint8List? localBytes,
    String? audioNoteUrl,
    int? displayOrder,
    bool? isActive,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return FamilyPhoto(
      id: id,
      patientId: patientId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      photoUrl: photoUrl ?? this.photoUrl,
      localPath: localPath ?? this.localPath,
      localBytes: localBytes ?? this.localBytes,
      audioNoteUrl: audioNoteUrl ?? this.audioNoteUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
