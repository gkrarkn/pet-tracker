import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'medication_model.dart';
import 'medication_repository.dart';
import '../notifications/notification_service.dart';
import '../shared/app_utils.dart';

class MedicationFormPage extends StatefulWidget {
  final MedicationRepository repository;
  final String petId;
  final String petName;
  final Medication? existing;

  const MedicationFormPage({
    super.key,
    required this.repository,
    required this.petId,
    required this.petName,
    this.existing,
  });

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _notesController;
  String _frequency = 'Günde 1';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;
  bool _scheduleReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  static const _frequencies = [
    'Günde 1',
    'Günde 2',
    'Günde 3',
    'Haftada 1',
    'Haftada 2',
    '2 haftada 1',
    'Ayda 1',
    'Gerektiğinde',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _nameController = TextEditingController(text: m?.name ?? '');
    _dosageController = TextEditingController(text: m?.dosage ?? '');
    _notesController = TextEditingController(text: m?.notes ?? '');
    _frequency = m?.frequency ?? 'Günde 1';
    _startDate = m?.startDate;
    _endDate = m?.endDate;
    _scheduleReminder = m?.reminderEnabled ?? false;
    _reminderTime =
        parseTimeOfDay(m?.reminderTime) ?? const TimeOfDay(hour: 9, minute: 0);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 7)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFFFF6B6B)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Başlangıç tarihini seçin')));
      return;
    }
    setState(() => _saving = true);

    final med = Medication(
      id: widget.existing?.id ?? const Uuid().v4(),
      petId: widget.petId,
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequency,
      startDate: _startDate!,
      endDate: _endDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isActive: true,
      reminderTime:
          _scheduleReminder ? formatTimeOfDay(_reminderTime) : null,
      reminderEnabled: _scheduleReminder,
    );

    if (widget.existing == null) {
      await widget.repository.add(med);
    } else {
      await widget.repository.update(med);
    }

    final notifId = NotificationService.idFromString(med.id);
    await NotificationService.instance.cancel(notifId);
    if (_scheduleReminder) {
      await NotificationService.instance.scheduleMedicationReminder(
        id: notifId,
        medicationId: med.id,
        petName: widget.petName,
        medicationName: med.name,
        dosage: med.dosage,
        time: _reminderTime,
      );
    }

    if (mounted) Navigator.of(context).pop(med);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'İlacı Düzenle' : 'İlaç Ekle'),
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
                    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.medication_outlined,
                    size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            _label('İlaç Adı'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration:
                  const InputDecoration(hintText: 'ör. Amoksisilin'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'İlaç adı gerekli'
                  : null,
            ),
            const SizedBox(height: 20),
            _label('Doz'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _dosageController,
              decoration:
                  const InputDecoration(hintText: 'ör. 250mg, 1 tablet'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Doz gerekli'
                  : null,
            ),
            const SizedBox(height: 20),
            _label('Sıklık'),
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _frequency,
                  isExpanded: true,
                  items: _frequencies
                      .map((f) => DropdownMenuItem(
                          value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _frequency = v ?? _frequency),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _label('Başlangıç Tarihi'),
            const SizedBox(height: 6),
            _dateTile(
              value: _startDate,
              hint: 'Tarih seçin',
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: 20),
            _label('Bitiş Tarihi (opsiyonel)'),
            const SizedBox(height: 6),
            _dateTile(
              value: _endDate,
              hint: 'Süresiz ise boş bırakın',
              onTap: () => _pickDate(isStart: false),
              trailing: _endDate != null
                  ? GestureDetector(
                      onTap: () => setState(() => _endDate = null),
                      child: const Icon(Icons.close,
                          size: 18, color: Colors.grey),
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            // Günlük hatırlatma toggle
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
                      size: 18, color: Color(0xFFFF6B6B)),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Günlük hatırlatma',
                          style: TextStyle(fontSize: 14))),
                  Switch(
                    value: _scheduleReminder,
                    activeThumbColor: const Color(0xFFFF6B6B),
                    onChanged: (v) => setState(() => _scheduleReminder = v),
                  ),
                ],
              ),
            ),
            if (_scheduleReminder) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: Color(0xFFFF6B6B)),
                      ),
                      child: child!,
                    ),
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
                          size: 18, color: Color(0xFFFF6B6B)),
                      const SizedBox(width: 10),
                      Text(
                        'Saat: ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _label('Notlar (opsiyonel)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Yan etkiler, dikkat edilmesi gerekenler…'),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                ),
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
                  size: 18, color: Color(0xFFFF6B6B)),
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
