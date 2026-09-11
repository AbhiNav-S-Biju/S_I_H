import 'package:image_picker/image_picker.dart';
import '../models/family_photo.dart';

abstract class IFamilyPhotoRepository {
  Future<List<FamilyPhoto>> getFamilyPhotoModels(String patientId);

  Future<FamilyPhoto> saveFamilyPhoto({
    required FamilyPhoto photo,
    XFile? image,
  });

  Future<void> softDeleteFamilyPhoto({
    required String patientId,
    required String photoId,
  });
}
