import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../notifications/notification_service.dart';
import '../shared/app_utils.dart';
import 'vet_visit_model.dart';
import 'vet_visit_repository.dart';

class VetVisitFormPage extends StatefulWidget {
  final VetVisitRepository repository;
  final String petId;
  final String petName;
  final VetVisit? existing;

  const VetVisitFormPage({
    super.key,
    required this.repository,
    required this.petId,
    required this.petName,
    this.existing,
  });

  @override
  State<VetVisitFormPage> createState() => _VetVisitFormPageState();
}

class _VetVisitFormPageState extends State<VetVisitFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;
  late final TextEditingController _notesController;
  late final TextEditingController _vetNameController;
  late final TextEditingController _clinicAddressController;
  late final TextEditingController _clinicPhoneController;
  DateTime? _visitDate;
  String _category = 'kontrol';
  bool _saving = false;
  bool _scheduleReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 10, minute: 0);
  int _reminderDaysBefore = 1;

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _reasonController = TextEditingController(text: v?.reason ?? '');
    _notesController = TextEditingController(text: v?.notes ?? '');
    _vetNameController = TextEditingController(text: v?.vetName ?? '');
    _clinicAddressController =
        TextEditingController(text: v?.clinicAddress ?? '');
    _clinicPhoneController = TextEditingController(text: v?.clinicPhone ?? '');
    _visitDate = v?.visitDate;
    _category = v?.category ?? 'kontrol';
    _scheduleReminder = v?.reminderEnabled ?? false;
    _reminderDaysBefore = v?.reminderDaysBefore ?? 1;
    _reminderTime =
        parseTimeOfDay(v?.reminderTime) ?? const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _notesController.dispose();
    _vetNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: Color(0xFF2EC4B6)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ziyaret tarihini seçin')),
      );
      return;
    }
    setState(() => _saving = true);
    final visit = VetVisit(
      id: widget.existing?.id ?? const Uuid().v4(),
      petId: widget.petId,
      visitDate: _visitDate!,
      category: _category,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      vetName: _vetNameController.text.trim().isEmpty
          ? null
          : _vetNameController.text.trim(),
      clinicAddress: _clinicAddressController.text.trim().isEmpty
          ? null
          : _clinicAddressController.text.trim(),
      clinicPhone: _clinicPhoneController.text.trim().isEmpty
          ? null
          : _clinicPhoneController.text.trim(),
      reminderTime:
          _scheduleReminder ? formatTimeOfDay(_reminderTime) : null,
      reminderEnabled: _scheduleReminder,
      reminderDaysBefore: _reminderDaysBefore,
    );
    if (widget.existing == null) {
      await widget.repository.add(visit);
    } else {
      await widget.repository.update(visit);
    }
    final notifId = NotificationService.idFromString(visit.id);
    await NotificationService.instance.cancel(notifId);
    if (visit.reminderEnabled) {
      await NotificationService.instance.scheduleVetReminder(
        id: notifId,
        petName: widget.petName,
        reason: visit.reason,
        visitDate: visit.visitDate,
        time: _reminderTime,
        daysBefore: _reminderDaysBefore,
      );
    }
    if (mounted) Navigator.of(context).pop(visit);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ziyareti Düzenle' : 'Yeni Ziyaret Ekle'),
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
            // icon header
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D8BFF), Color(0xFF2EC4B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    size: 36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            _label('Ziyaret Turu'),
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
                  value: _category,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'asi', child: Text('Aşı')),
                    DropdownMenuItem(value: 'kontrol', child: Text('Kontrol')),
                    DropdownMenuItem(value: 'hastalik', child: Text('Hastalık')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _category = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            _label('Ziyaret Nedeni'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(hintText: 'ör. Rutin kontrol'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Neden gerekli' : null,
            ),
            const SizedBox(height: 20),
            _label('Veteriner Adı (opsiyonel)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _vetNameController,
              decoration: const InputDecoration(hintText: 'ör. Dr. Ahmet Yılmaz'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF2EC4B6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Veteriner raporunda telefon ve adres bilgileri de görünsün istiyorsan aşağıdaki alanları doldurabilirsin.',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _label('Klinik Telefonu (opsiyonel)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _clinicPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: 'ör. 0212 555 12 34'),
            ),
            const SizedBox(height: 20),
            _label('Klinik Adresi (opsiyonel)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _clinicAddressController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'ör. Bağdat Caddesi No:12 Kadıköy / İstanbul',
              ),
            ),
            const SizedBox(height: 20),
            _label('Ziyaret Tarihi'),
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
                      _visitDate == null
                          ? 'Tarih seçin'
                          : _visitDate!
                              .toLocal()
                              .toString()
                              .split(' ')[0],
                      style: TextStyle(
                        color: _visitDate == null
                            ? Colors.grey.shade400
                            : const Color(0xFF1A1A2E),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                    child: Text('Hatırlatma kur', style: TextStyle(fontSize: 14)),
                  ),
                  Switch(
                    value: _scheduleReminder,
                    activeThumbColor: const Color(0xFF2EC4B6),
                    onChanged: (value) =>
                        setState(() => _scheduleReminder = value),
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
                      Text(
                        'Saat: ${formatTimeOfDay(_reminderTime)}',
                        style: const TextStyle(fontSize: 15),
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
                      DropdownMenuItem(value: 2, child: Text('2 gün önce')),
                      DropdownMenuItem(value: 3, child: Text('3 gün önce')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _reminderDaysBefore = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _label('Notlar (opsiyonel)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Muayene notları, ilaçlar…',
                alignLabelWithHint: true,
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
