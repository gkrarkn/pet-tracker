import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../shared/app_utils.dart';
import 'pet_model.dart';
import 'pet_repository.dart';

class PetFormPage extends StatefulWidget {
  final PetRepository repository;
  final Pet? existing;

  const PetFormPage({super.key, required this.repository, this.existing});

  @override
  State<PetFormPage> createState() => _PetFormPageState();
}

class _PetFormPageState extends State<PetFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _speciesController;
  late final TextEditingController _breedController;
  DateTime? _birthDate;
  String? _photoPath;
  String _themeColor = 'teal';
  String _themeIcon = 'pets';
  bool _saving = false;

  static const _themeColors = ['teal', 'coral', 'sky', 'gold', 'mint'];
  static const _themeIcons = ['pets', 'heart', 'shield', 'sparkle'];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameController = TextEditingController(text: p?.name ?? '');
    _speciesController = TextEditingController(text: p?.species ?? '');
    _breedController = TextEditingController(text: p?.breed ?? '');
    _birthDate = p?.birthDate;
    _photoPath = p?.photoUrl;
    _themeColor = p?.themeColor ?? 'teal';
    _themeIcon = p?.themeIcon ?? 'pets';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF2EC4B6),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Fotoğraf Seç',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey.shade50,
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF2EC4B6)),
              title: const Text('Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey.shade50,
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF2EC4B6)),
              title: const Text('Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final xFile = await ImagePicker()
        .pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (xFile != null) setState(() => _photoPath = xFile.path);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen doğum tarihini seçin')),
      );
      return;
    }
    setState(() => _saving = true);
    final pet = Pet(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      species: _speciesController.text.trim(),
      breed: _breedController.text.trim(),
      birthDate: _birthDate!,
      photoUrl: _photoPath,
      themeColor: _themeColor,
      themeIcon: _themeIcon,
    );
    if (widget.existing == null) {
      await widget.repository.add(pet);
    } else {
      await widget.repository.update(pet);
    }
    if (mounted) Navigator.of(context).pop(pet);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Hayvanı Düzenle' : 'Yeni Hayvan Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // Avatar picker
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: _photoPath == null
                            ? LinearGradient(
                                colors: [
                                  petThemePrimary(_themeColor),
                                  petThemeSecondary(_themeColor)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        image: _photoPath != null
                            ? DecorationImage(
                                image: FileImage(File(_photoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _photoPath == null
                          ? Icon(
                              petThemeIcon(_themeIcon),
                              size: 44,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: petThemePrimary(_themeColor),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _label('Ad'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'ör. Pamuk'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ad gerekli' : null,
            ),
            const SizedBox(height: 20),
            _label('Tür'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _speciesController,
              decoration: const InputDecoration(hintText: 'ör. Kedi'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Tür gerekli' : null,
            ),
            const SizedBox(height: 20),
            _label('Irk'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _breedController,
              decoration: const InputDecoration(hintText: 'ör. British Shorthair'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Irk gerekli' : null,
            ),
            const SizedBox(height: 20),
            _label('Tema Rengi'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _themeColors.map((colorKey) {
                final color = petThemePrimary(colorKey);
                final selected = _themeColor == colorKey;
                return GestureDetector(
                  onTap: () => setState(() => _themeColor = colorKey),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.black87, width: 2)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _label('Tema İkonu'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _themeIcons.map((iconKey) {
                final selected = _themeIcon == iconKey;
                return GestureDetector(
                  onTap: () => setState(() => _themeIcon = iconKey),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: petThemePrimary(_themeColor).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? petThemePrimary(_themeColor)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      petThemeIcon(iconKey),
                      color: petThemePrimary(_themeColor),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _label('Doğum Tarihi'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF2EC4B6)),
                    const SizedBox(width: 10),
                    Text(
                      _birthDate == null
                          ? 'Tarih seçin'
                          : _birthDate!
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                      style: TextStyle(
                        color: _birthDate == null
                            ? Colors.grey.shade400
                            : const Color(0xFF1A1A2E),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Güncelle' : 'Ekle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
      );
}
