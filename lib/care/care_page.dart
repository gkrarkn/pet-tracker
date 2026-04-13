import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../notifications/notification_service.dart';
import '../shared/app_utils.dart';
import 'care_repository.dart';
import 'care_task_model.dart';

class CarePage extends StatefulWidget {
  final String petId;
  final String petName;
  final CareRepository repository;

  const CarePage({
    super.key,
    required this.petId,
    required this.petName,
    required this.repository,
  });

  @override
  State<CarePage> createState() => _CarePageState();
}

class _CarePageState extends State<CarePage> {
  late Future<List<CareTask>> _future;

  static const _types = [
    ('food', 'Mama'),
    ('water', 'Su'),
    ('toilet', 'Tuvalet'),
    ('grooming', 'Tüy bakımı'),
    ('bath', 'Banyo'),
    ('parasite', 'Parazit damlası'),
  ];

  static const _frequencies = [
    ('daily', 'Her gün'),
    ('twice_daily', 'Günde 2 kez'),
    ('every_3_days', '3 günde 1'),
    ('weekly', 'Haftada 1'),
    ('biweekly', '2 haftada 1'),
    ('monthly', 'Ayda 1'),
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.repository.getByPetId(widget.petId);
  }

  Future<void> _syncTaskNotification(CareTask task) async {
    final notificationId = NotificationService.idFromString(task.id);
    await NotificationService.instance.cancel(notificationId);
    if (!task.reminderEnabled) return;
    final reminderTime = NotificationService.parseReminderTime(task.reminderTime);
    final dueDate = effectiveCareDueDate(
      startDate: task.startDate,
      lastCompletedAt: task.lastCompletedAt,
      skippedUntil: task.skippedUntil,
      frequency: task.frequency,
    );
    await NotificationService.instance.scheduleCareReminder(
      id: notificationId,
      petName: widget.petName,
      taskTitle: task.title,
      dueDate: dueDate,
      taskId: task.id,
      time: reminderTime,
    );
  }

  Future<void> _openForm({CareTask? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String selectedType = existing?.type ?? 'food';
    String selectedFrequency = existing?.frequency ?? 'daily';
    bool reminderEnabled = existing?.reminderEnabled ?? false;
    TimeOfDay reminderTime =
        parseTimeOfDay(existing?.reminderTime) ?? const TimeOfDay(hour: 9, minute: 0);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  existing == null ? 'Bakım rutini ekle' : 'Bakım rutinini düzenle',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                _label('Rutin türü'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _types.map((item) {
                    final active = selectedType == item.$1;
                    final color = careTypeColor(item.$1);
                    return ChoiceChip(
                      label: Text(item.$2),
                      selected: active,
                      selectedColor: color.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: active ? color : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) => setModalState(() => selectedType = item.$1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _label('Başlık'),
                const SizedBox(height: 6),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'ör. Akşam maması veya aylık damla',
                  ),
                ),
                const SizedBox(height: 16),
                _label('Sıklık'),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedFrequency,
                      isExpanded: true,
                      items: _frequencies
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.$1,
                              child: Text(f.$2),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedFrequency = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Color(0xFF2EC4B6), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Hatırlatma kur')),
                      Switch(
                        value: reminderEnabled,
                        activeThumbColor: const Color(0xFF2EC4B6),
                        onChanged: (value) =>
                            setModalState(() => reminderEnabled = value),
                      ),
                    ],
                  ),
                ),
                if (reminderEnabled) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: reminderTime,
                      );
                      if (picked != null) {
                        setModalState(() => reminderTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 18, color: Color(0xFF2EC4B6)),
                          const SizedBox(width: 10),
                          Text('Saat: ${formatTimeOfDay(reminderTime)}'),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _label('Notlar'),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Miktar, ürün adı veya bakım notu',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      final task = CareTask(
                        id: existing?.id ?? const Uuid().v4(),
                        petId: widget.petId,
                        type: selectedType,
                        title: titleController.text.trim(),
                        frequency: selectedFrequency,
                        notes: notesController.text.trim().isEmpty
                            ? null
                            : notesController.text.trim(),
                        reminderEnabled: reminderEnabled,
                        reminderTime:
                            reminderEnabled ? formatTimeOfDay(reminderTime) : null,
                        isActive: existing?.isActive ?? true,
                        startDate: existing?.startDate ?? DateTime.now(),
                        lastCompletedAt: existing?.lastCompletedAt,
                        skippedUntil: existing?.skippedUntil,
                      );
                      if (existing == null) {
                        await widget.repository.add(task);
                      } else {
                        await widget.repository.update(task);
                      }
                      await _syncTaskNotification(task);
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(_reload);
                    },
                    child: Text(existing == null ? 'Kaydet' : 'Güncelle'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showActions(CareTask task) async {
    showModalBottomSheet(
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Tamamlandı olarak işaretle'),
              onTap: () async {
                final completedAt = DateTime.now();
                await widget.repository.markCompleted(task.id, completedAt);
                await _syncTaskNotification(
                  task.copyWith(lastCompletedAt: completedAt),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                setState(_reload);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(ctx);
                _openForm(existing: task);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                task.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                color: const Color(0xFF2EC4B6),
              ),
              title: Text(task.isActive ? 'Pasife al' : 'Yeniden etkinleştir'),
              onTap: () async {
                await widget.repository.setActive(task.id, !task.isActive);
                if (task.isActive) {
                  await NotificationService.instance
                      .cancel(NotificationService.idFromString(task.id));
                } else {
                  await _syncTaskNotification(task.copyWith(isActive: true));
                }
                if (ctx.mounted) Navigator.pop(ctx);
                setState(_reload);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await widget.repository.delete(task.id);
                await NotificationService.instance
                    .cancel(NotificationService.idFromString(task.id));
                if (ctx.mounted) Navigator.pop(ctx);
                setState(_reload);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CareTask>>(
        future: _future,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          final active = tasks.where((task) => task.isActive).toList();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2EC4B6), Color(0xFF56CFE1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 16,
                    24,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(widget.petName,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bakım Rutinleri',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        active.isEmpty
                            ? 'Mama, su, bakım ve damla rutinlerini planla'
                            : '${active.length} aktif bakım rutini var',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              if (tasks.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.spa_outlined,
                                size: 42, color: Color(0xFF2EC4B6)),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz bakım rutini yok',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Mama, su, tuvalet, banyo veya parazit damlası gibi tekrar eden işleri buradan takip edebilirsin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) {
                        final task = tasks[index];
                        final color = careTypeColor(task.type);
                        final due = effectiveCareDueDate(
                          startDate: task.startDate,
                          lastCompletedAt: task.lastCompletedAt,
                          skippedUntil: task.skippedUntil,
                          frequency: task.frequency,
                        );
                        final dueLabel = daysBetween(DateTime.now(), due) <= 0
                            ? 'Bugün'
                            : '${daysBetween(DateTime.now(), due)} gün sonra';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(Icons.spa_outlined, color: color),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(task.title,
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700)),
                                            Text(
                                              '${careTypeLabel(task.type)} · ${careFrequencyLabel(task.frequency)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _showActions(task),
                                        icon: Icon(Icons.more_horiz,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _pill('Sonraki bakım: $dueLabel', color),
                                      if (task.reminderEnabled && task.reminderTime != null)
                                        _pill('Hatırlatma ${task.reminderTime}', color),
                                      if (task.lastCompletedAt != null)
                                        _pill('Son tamamlanma ${formatDate(task.lastCompletedAt!)}',
                                            Colors.grey.shade600),
                                    ],
                                  ),
                                  if (task.notes != null && task.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(task.notes!,
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.grey.shade500)),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: tasks.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Rutin Ekle'),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      );
}
