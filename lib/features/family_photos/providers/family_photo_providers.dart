import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../database/hive_database.dart';
import '../../caregiver/providers/caregiver_providers.dart';
import '../models/family_photo.dart';
import '../repositories/family_photo_repository.dart';
import '../../games/models/family_member_item.dart';

final familyPhotoRepositoryProvider = Provider<IFamilyPhotoRepository>((ref) {
  final repository = ref.watch(caregiverRepositoryProvider);
  return repository as IFamilyPhotoRepository;
});

/// Resolves the active patient for both paired devices and caregiver sessions.
/// The paired patient takes precedence; caregivers use their selected patient.
final familyPhotoPatientIdProvider = Provider<String?>((ref) {
  final pairedPatientId = HiveDatabase.pairedPatientId;
  if (pairedPatientId != null && pairedPatientId.isNotEmpty) {
    return pairedPatientId;
  }
  return ref.watch(selectedPatientProvider)?.id;
});

final familyPhotosProvider = FutureProvider.autoDispose<List<FamilyPhoto>>((
  ref,
) async {
  final patientId = ref.watch(familyPhotoPatientIdProvider) ?? '';
  if (patientId.isEmpty) return [];
  return ref
      .watch(familyPhotoRepositoryProvider)
      .getFamilyPhotoModels(patientId);
});

final whoIsThisFamilyMembersProvider =
    FutureProvider.autoDispose<List<FamilyMemberItem>>((ref) async {
      final photos = await ref.watch(familyPhotosProvider.future);
      return photos
          .where(
            (photo) => photo.isActive && !photo.isDeleted && photo.hasPhoto,
          )
          .map(FamilyMemberItem.fromFamilyPhoto)
          .toList(growable: false);
    });

class FamilyPhotoActionsNotifier extends StateNotifier<AsyncValue<void>> {
  FamilyPhotoActionsNotifier(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  final IFamilyPhotoRepository _repository;
  final Ref _ref;

  Future<FamilyPhoto?> save(FamilyPhoto photo, {XFile? image}) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.saveFamilyPhoto(
        photo: photo,
        image: image,
      );
      _ref.invalidate(familyPhotosProvider);
      _ref.invalidate(whoIsThisFamilyMembersProvider);
      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  Future<bool> remove(String photoId) async {
    state = const AsyncValue.loading();
    try {
      final patientId = _ref.read(familyPhotoPatientIdProvider) ?? '';
      if (patientId.isEmpty) throw StateError('No patient is paired');
      await _repository.softDeleteFamilyPhoto(
        patientId: patientId,
        photoId: photoId,
      );
      _ref.invalidate(familyPhotosProvider);
      _ref.invalidate(whoIsThisFamilyMembersProvider);
      state = const AsyncValue.data(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }
}

final familyPhotoActionsProvider =
    StateNotifierProvider<FamilyPhotoActionsNotifier, AsyncValue<void>>((ref) {
      return FamilyPhotoActionsNotifier(
        ref.watch(familyPhotoRepositoryProvider),
        ref,
      );
    });
