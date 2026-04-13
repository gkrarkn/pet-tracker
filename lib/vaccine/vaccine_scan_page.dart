import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../shared/app_utils.dart';

class VaccineScanDraft {
  final String vaccineName;
  final DateTime? administeredDate;
  final DateTime? nextDueDate;
  final String rawText;

  const VaccineScanDraft({
    required this.vaccineName,
    required this.administeredDate,
    required this.nextDueDate,
    required this.rawText,
  });
}

class VaccineScanPage extends StatefulWidget {
  const VaccineScanPage({super.key});

  @override
  State<VaccineScanPage> createState() => _VaccineScanPageState();
}

class _VaccineScanPageState extends State<VaccineScanPage> {
  XFile? _image;
  VaccineScanDraft? _draft;
  final _ocrTextController = TextEditingController();

  static const _vaccineMatchers = {
    'karma aşı (dhpp / gençlik aşısı)': ['dhpp', 'karma', 'distemper', 'parvo'],
    'kuduz aşısı (kuduz)': ['kuduz', 'rabies'],
    'bordetella (öksürük aşısı)': ['bordetella'],
    'felv (kedi lösemi aşısı)': ['felv', 'lösemi', 'losemi'],
    'parazit uygulaması (iç / dış parazit)': ['parazit', 'antiparaziter', 'ic parazit', 'dis parazit'],
  };

  @override
  void dispose() {
    _ocrTextController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source, imageQuality: 90);
    if (image == null) return;
    setState(() {
      _image = image;
      _draft = null;
    });
  }

  VaccineScanDraft _parseText(String text) {
    final lower = text.toLowerCase();
    var vaccineName = 'Tarama sonucu aşı adı bulunamadı';
    for (final entry in _vaccineMatchers.entries) {
      if (entry.value.any(lower.contains)) {
        vaccineName = entry.key;
        break;
      }
    }

    final regex = RegExp(
      r'(\d{1,2}[./-]\d{1,2}[./-]\d{2,4})|(\d{4}[./-]\d{1,2}[./-]\d{1,2})',
    );
    final matches = regex
        .allMatches(text)
        .map((m) => m.group(0)!)
        .map(_tryParseDate)
        .whereType<DateTime>()
        .toList();

    matches.sort((a, b) => a.compareTo(b));
    return VaccineScanDraft(
      vaccineName: vaccineName,
      administeredDate: matches.isEmpty ? null : matches.first,
      nextDueDate: matches.length > 1 ? matches.last : null,
      rawText: text,
    );
  }

  DateTime? _tryParseDate(String input) {
    final normalized = input.replaceAll('.', '/').replaceAll('-', '/');
    final parts = normalized.split('/');
    if (parts.length != 3) return null;
    try {
      if (parts[0].length == 4) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
      final year = parts[2].length == 2 ? '20${parts[2]}' : parts[2];
      return DateTime(
        int.parse(year),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aşı Karnesini Tara')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2EC4B6), Color(0xFF56CFE1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'Kamerayla aşı karnesini çek. Şimdilik simulator uyumlu sürümde fotoğrafı referans olarak gösterip metni elle yapıştırarak akıllı ayrıştırma yapıyoruz.',
              style: TextStyle(color: Colors.white, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeriden Seç'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(_image!.path),
                height: 240,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _ocrTextController,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Okunan metin / elle yapıştır',
              hintText:
                  'Örn: Karma Aşı 14.04.2026 Sonraki Doz 14.05.2026',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _draft = _parseText(_ocrTextController.text);
                  });
                },
                icon: const Icon(Icons.auto_awesome_outlined),
              ),
            ),
            onChanged: (_) {
              setState(() {
                _draft = _parseText(_ocrTextController.text);
              });
            },
          ),
          if (_draft != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bulduklarımız',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _line('Aşı', _draft!.vaccineName),
                  _line(
                    'Uygulama',
                    _draft!.administeredDate == null
                        ? 'Bulunamadı'
                        : formatDate(_draft!.administeredDate!),
                  ),
                  _line(
                    'Sonraki tarih',
                    _draft!.nextDueDate == null
                        ? 'Bulunamadı'
                        : formatDate(_draft!.nextDueDate!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, _draft),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Bu Verileri Kullan'),
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Okunan ham metni göster'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(_draft!.rawText.isEmpty ? 'Metin bulunamadı.' : _draft!.rawText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w700),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}
