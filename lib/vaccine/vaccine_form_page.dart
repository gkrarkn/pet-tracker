import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'vaccine_model.dart';
import 'vaccine_repository.dart';
import 'vaccine_scan_page.dart';
import '../notifications/notification_service.dart';
import '../shared/app_utils.dart';

class VaccineFormPage extends StatefulWidget {
  final VaccineRepository repository;
  final String petId;
  final String petName;
  final Vaccine? existing;

  const VaccineFormPage({
    super.key,
    required this.repository,
    required this.petId,
    required this.petName,
    this.existing,
  });

  @override
  State<VaccineFormPage> createState() => _VaccineFormPageState();
}

class _VaccineFormPageState extends State<VaccineFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _vetNameController;
  late final TextEditingController _notesController;
  DateTime? _administeredDate;
  DateTime? _nextDueDate;
  bool _saving = false;
  bool _scheduleNotification = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  int _reminderDaysBefore = 3;

  // Yaygın aşı önerileri: teknik adı + halk arasındaki daha bilinen karşılığı
  static const _suggestions = [
    'Karma Aşı (DHPP / gençlik aşısı)',
    'Kuduz Aşısı (kuduz)',
    'Leptospiroz (bakteriyel enfeksiyon aşısı)',
    'Bordetella (kennel cough / köpek öksürüğü aşısı)',
    'Lyme (kene kaynaklı Lyme hastalığı aşısı)',
    'Feline Herpesvirus (kedi nezlesi etkeni)',
    'Feline Calicivirus (üst solunum yolu virüsü)',
    'Feline Panleukopenia (kedi gençlik hastalığı)',
    'FeLV (kedi lösemi aşısı)',
    'Parazit Uygulaması (iç / dış parazit)',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _nameController = TextEditingController(text: v?.name ?? '');
    _vetNameController = TextEditingController(text: v?.vetName ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');
    _administeredDate = v?.administeredDate;
    _nextDueDate = v?.nextDueDate;
    _scheduleNotification = v?.reminderEnabled ?? true;
    _reminderDaysBefore = v?.reminderDaysBefore ?? 3;
    _reminderTime =
        parseTimeOfDay(v?.reminderTime) ?? const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _vetNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isAdministered}) async {
    final initial = isAdministered
        ? (_administeredDate ?? DateTime.now())
        : (_nextDueDate ?? DateTime.now().add(const Duration(days: 365)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isAdministered ? DateTime(2000) : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF2EC4B6)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isAdministered) {
        _administeredDate = picked;
      } else {
        _nextDueDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_administeredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen uygulama tarihini seçin')),
      );
      return;
    }
    setState(() => _saving = true);

    final vaccine = Vaccine(
      id: widget.existing?.id ?? const Uuid().v4(),
      petId: widget.petId,
      name: _nameController.text.trim(),
      administeredDate: _administeredDate!,
      nextDueDate: _nextDueDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      vetName: _vetNameController.text.trim().isEmpty
          ? null
          : _vetNameController.text.trim(),
      reminderTime: _nextDueDate != null && _scheduleNotification
          ? formatTimeOfDay(_reminderTime)
          : null,
      reminderEnabled: _nextDueDate != null && _scheduleNotification,
      reminderDaysBefore: _reminderDaysBefore,
    );

    if (widget.existing == null) {
      await widget.repository.add(vaccine);
    } else {
      await widget.repository.update(vaccine);
    }

    // Önceki bildirimi iptal et, yenisini kur
    final notifId = NotificationService.idFromString(vaccine.id);
    await NotificationService.instance.cancel(notifId);
    if (vaccine.reminderEnabled && vaccine.nextDueDate != null) {
      await NotificationService.instance.scheduleVaccineReminder(
        id: notifId,
        petName: widget.petName,
        vaccineName: vaccine.name,
        dueDate: vaccine.nextDueDate!,
        time: _reminderTime,
        daysBefore: _reminderDaysBefore,
      );
    }

    if (mounted) Navigator.of(context).pop(vaccine);
  }

  Future<void> _scanCard() async {
    final draft = await Navigator.of(context).push<VaccineScanDraft>(
      MaterialPageRoute(builder: (_) => const VaccineScanPage()),
    );
    if (draft == null) return;
    setState(() {
      if (!draft.vaccineName.toLowerCase().contains('bulunamadı')) {
        _nameController.text = draft.vaccineName;
      }
      _administeredDate = draft.administeredDate ?? _administeredDate;
      _nextDueDate = draft.nextDueDate ?? _nextDueDate;
      if (draft.rawText.isNotEmpty) {
        _notesController.text = draft.rawText;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Aşıyı Düzenle' : 'Aşı Ekle'),
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
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2EC4B6), Color(0xFF56CFE1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.vaccines_outlined,
                    size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _scanCard,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Aşı Karnesini Tara'),
            ),
            const SizedBox(height: 32),
            _label('Aşı Adı'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'ör. Karma Aşı (gençlik aşısı)',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Aşı adı gerekli' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Kolay seçim için teknik adıyla birlikte günlük kullanım adını da gösteriyoruz.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            // Hızlı seçim chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _suggestions
                  .map((s) => GestureDetector(
                        onTap: () =>
                            setState(() => _nameController.text = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _nameController.text == s
                                ? const Color(0xFF2EC4B6)
                                : const Color(0xFF2EC4B6)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(s,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: _nameController.text == s
                                      ? Colors.white
                                      : const Color(0xFF2EC4B6))),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            _label('Uygulama Tarihi'),
            const SizedBox(height: 6),
            _dateTile(
              value: _administeredDate,
              hint: 'Tarih seçin',
              onTap: () => _pickDate(isAdministered: true),
            ),
            const SizedBox(height: 20),
            _label('Sonraki Doz Tarihi (opsiyonel)'),
            const SizedBox(height: 6),
            _dateTile(
              value: _nextDueDate,
              hint: 'Hatırlatıcı için tarih seçin',
              onTap: () => _pickDate(isAdministered: false),
              trailing: _nextDueDate != null
                  ? GestureDetector(
                      onTap: () => setState(() => _nextDueDate = null),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.grey),
                    )
                  : null,
            ),
            if (_nextDueDate != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        size: 18, color: Color(0xFF2EC4B6)),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('3 gün önce hatırlat',
                          style: TextStyle(fontSize: 14)),
                    ),
                    Switch(
                      value: _scheduleNotification,
                      activeThumbColor: const Color(0xFF2EC4B6),
                      onChanged: (v) =>
                          setState(() => _scheduleNotification = v),
                    ),
                  ],
                ),
              ),
              if (_scheduleNotification) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() => _reminderTime = picked);
                    }
                  },
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
                        const Icon(Icons.access_time,
                            size: 18, color: Color(0xFF2EC4B6)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hatırlatma saati: ${formatTimeOfDay(_reminderTime)}',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _reminderDaysBefore,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Aynı gün')),
                        DropdownMenuItem(value: 1, child: Text('1 gün önce')),
                        DropdownMenuItem(value: 3, child: Text('3 gün önce')),
                        DropdownMenuItem(value: 7, child: Text('7 gün önce')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _reminderDaysBefore = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            _label('Veteriner Adı (opsiyonel)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _vetNameController,
              decoration:
                  const InputDecoration(hintText: 'ör. Dr. Ayşe Kaya'),
            ),
            const SizedBox(height: 20),
            _label('Notlar (opsiyonel)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Yan etkiler, marka…'),
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
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEdit ? 'Güncelle' : 'Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile({
    required DateTime? value,
    required String hint,
    required VoidCallback onTap,
    Widget? trailing,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              Expanded(
                child: Text(
                  value == null
                      ? hint
                      : value.toLocal().toString().split(' ')[0],
                  style: TextStyle(
                    color: value == null
                        ? Colors.grey.shade400
                        : const Color(0xFF1A1A2E),
                    fontSize: 15,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      );

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
