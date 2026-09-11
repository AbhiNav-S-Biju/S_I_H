import 'package:hive/hive.dart';
import 'dart:typed_data';

class HiveFamilyPhoto extends HiveObject {
  HiveFamilyPhoto({
    required this.id,
    required this.patientId,
    required this.name,
    required this.relationship,
    required this.photoUrl,
    this.localPath,
    this.localBytes,
    required this.displayOrder,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  String id;
  String patientId;
  String name;
  String relationship;
  String photoUrl;
  String? localPath;
  Uint8List? localBytes;
  int displayOrder;
  bool isDeleted;
  DateTime createdAt;
  DateTime updatedAt;
}
