import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/elder_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../models/family_photo.dart';
import '../providers/family_photo_providers.dart';

class FamilyPhotosScreen extends ConsumerWidget {
  const FamilyPhotosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final photos = ref.watch(familyPhotosProvider);
    return Scaffold(
      backgroundColor: ElderColors.background,
      appBar: AppBar(
        title: Text(l10n.familyPhotosTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: photos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MessageState(
          message: l10n.familyPhotosLoadError,
          action: TextButton(
            onPressed: () => ref.invalidate(familyPhotosProvider),
            child: Text(l10n.tryAgainShort),
          ),
        ),
        data: (items) => _FamilyPhotosBody(photos: items),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: Text(l10n.addFamilyMemberButton),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {FamilyPhoto? photo}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FamilyPhotoEditor(photo: photo),
    );
  }
}

class _FamilyPhotosBody extends ConsumerWidget {
  const _FamilyPhotosBody({required this.photos});

  final List<FamilyPhoto> photos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (photos.isEmpty) {
      final l10n = context.l10n;
      return _MessageState(
        message: l10n.noFamilyPhotosMessage,
        action: FilledButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const _FamilyPhotoEditor(),
          ),
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: Text(l10n.addFamilyMemberButton),
        ),
      );
    }

    // Give each tile a little more height when the system font scale is large so
    // the caption never clips against the photo.
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final aspectRatio = 0.78 / textScale.clamp(1.0, 1.6);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: aspectRatio.clamp(0.5, 0.9),
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) => _FamilyPhotoCard(photo: photos[index]),
    );
  }
}

class _FamilyPhotoCard extends ConsumerWidget {
  const _FamilyPhotoCard({required this.photo});

  final FamilyPhoto photo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _FamilyPhotoEditor(photo: photo),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ElderColors.background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: const Offset(8, 8),
              blurRadius: 18,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              offset: const Offset(-8, -8),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _PhotoImage(photo: photo)),
            const SizedBox(height: 12),
            Text(
              photo.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ElderColors.textPrimary,
              ),
            ),
            Text(
              photo.relationship,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                color: ElderColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({required this.photo});

  final FamilyPhoto photo;

  @override
  Widget build(BuildContext context) {
    final image = photo.photoUrl.startsWith('http')
        ? Image.network(photo.photoUrl, fit: BoxFit.cover)
        : photo.localBytes != null
        ? Image.memory(photo.localBytes!, fit: BoxFit.cover)
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: image == null
          ? const ColoredBox(
              color: ElderColors.primaryContainer,
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 64,
                  color: ElderColors.primary,
                ),
              ),
            )
          : Image(
              image: image.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: ElderColors.primaryContainer,
                child: Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 48,
                    color: ElderColors.primary,
                  ),
                ),
              ),
            ),
    );
  }
}

class _FamilyPhotoEditor extends ConsumerStatefulWidget {
  const _FamilyPhotoEditor({this.photo});

  final FamilyPhoto? photo;

  @override
  ConsumerState<_FamilyPhotoEditor> createState() => _FamilyPhotoEditorState();
}

class _FamilyPhotoEditorState extends ConsumerState<_FamilyPhotoEditor> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _selectedImage;
  bool _saving = false;

  bool get _editing => widget.photo != null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.photo?.name ?? '';
    _relationshipController.text = widget.photo?.relationship ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (mounted && image != null) setState(() => _selectedImage = image);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate() ||
        (!_editing && _selectedImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.familyPhotoMissingDetails)),
      );
      return;
    }
    final patientId = ref.read(familyPhotoPatientIdProvider) ?? '';
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.familyPhotosFindPatientError)),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.photo;
    final photo =
        (existing ??
                FamilyPhoto(
                  id: const Uuid().v4(),
                  patientId: patientId,
                  name: '',
                  relationship: '',
                  photoUrl: '',
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              name: _nameController.text.trim(),
              relationship: _relationshipController.text.trim(),
              updatedAt: now,
            );

    final saved = await ref
        .read(familyPhotoActionsProvider.notifier)
        .save(photo, image: _selectedImage);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.familyPhotosAddError)),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editing ? l10n.familyMemberUpdated : l10n.familyMemberAdded,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.removeFamilyMemberTitle),
        content: Text(l10n.removeFamilyMemberMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.removeButton),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    final success = await ref
        .read(familyPhotoActionsProvider.notifier)
        .remove(widget.photo!.id);
    if (!mounted) return;
    if (success) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final existingImage = widget.photo;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: ElderColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _editing
                        ? l10n.editFamilyMemberTitle
                        : l10n.addFamilyMemberTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ElderColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 180,
                    child: _selectedImage != null
                        ? _PickedPhotoPreview(file: _selectedImage!)
                        : existingImage != null
                        ? _PhotoImage(photo: existingImage)
                        : OutlinedButton.icon(
                            onPressed: _choosePhoto,
                            icon: const Icon(Icons.add_a_photo_rounded),
                            label: Text(l10n.tapToAddPhoto),
                          ),
                  ),
                  if (_selectedImage != null || existingImage != null)
                    TextButton.icon(
                      onPressed: _choosePhoto,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: Text(l10n.chooseDifferentPhoto),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.nameLabel),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.enterNameValidator
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _relationshipController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.relationshipLabel,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.enterRelationshipValidator
                        : null,
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _saving
                          ? l10n.savingLabel
                          : l10n.saveFamilyMemberButton,
                    ),
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(l10n.removeFamilyMemberButton),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PickedPhotoPreview extends StatelessWidget {
  const _PickedPhotoPreview({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: ElderColors.primaryContainer,
              child: Center(child: Icon(Icons.broken_image_rounded, size: 48)),
            ),
          ),
        );
      },
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, required this.action});

  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_album_rounded,
              size: 64,
              color: ElderColors.primary,
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: ElderColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            action,
          ],
        ),
      ),
    );
  }
}
