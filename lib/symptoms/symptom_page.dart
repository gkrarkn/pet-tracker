import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../shared/app_utils.dart';
import 'symptom_log_model.dart';
import 'symptom_repository.dart';

class SymptomPage extends StatefulWidget {
  final String petId;
  final String petName;
  final SymptomRepository repository;

  const SymptomPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.repository,
  });

  @override
  State<SymptomPage> createState() => _SymptomPageState();
}

class _SymptomPageState extends State<SymptomPage> {
  static const _symptoms = [
    'İştahsızlık',
    'Öksürük',
    'Kusma',
    'İshal',
    'Topallama',
    'Halsizlik',
    'Kaşıntı',
  ];

  late Future<List<SymptomLog>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.repository.getByPetId(widget.petId);
  }

  Future<void> _addLog({String? initialSymptom}) async {
    final noteCtrl = TextEditingController();
    String symptom = initialSymptom ?? _symptoms.first;
    String severity = 'orta';
    DateTime observedAt = DateTime.now();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
              DropdownButtonFormField<String>(
                initialValue: symptom,
                decoration: const InputDecoration(labelText: 'Semptom'),
                items: _symptoms
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => symptom = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: severity,
                decoration: const InputDecoration(labelText: 'Şiddet'),
                items: const [
                  DropdownMenuItem(value: 'hafif', child: Text('Hafif')),
                  DropdownMenuItem(value: 'orta', child: Text('Orta')),
                  DropdownMenuItem(value: 'yüksek', child: Text('Yüksek')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => severity = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Not',
                  hintText: 'Ne zaman başladı, ne kadar sürdü?',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: Text('Kayıt zamanı: ${formatDate(observedAt)}'),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: observedAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => observedAt = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await widget.repository.add(
                      SymptomLog(
                        id: const Uuid().v4(),
                        petId: widget.petId,
                        symptom: symptom,
                        severity: severity,
                        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                        observedAt: observedAt,
                      ),
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) {
      setState(_reload);
    }
  }

  Future<void> _shareReport(List<SymptomLog> logs) async {
    final report = StringBuffer()
      ..writeln('${widget.petName} - Semptom Günlüğü')
      ..writeln();
    for (final log in logs) {
      report.writeln(
        '${formatDate(log.observedAt)} · ${log.symptom} · ${log.severity}'
        '${log.note == null ? '' : ' · ${log.note}'}',
      );
    }
    await Share.share(report.toString().trim(), subject: '${widget.petName} semptom raporu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semptom Günlüğü'),
        actions: [
          FutureBuilder<List<SymptomLog>>(
            future: _future,
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => _shareReport(logs.reversed.toList()),
                icon: const Icon(Icons.ios_share_outlined),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addLog,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Semptom Ekle'),
      ),
      body: FutureBuilder<List<SymptomLog>>(
        future: _future,
        builder: (context, snapshot) {
          final logs = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _symptoms
                    .map(
                      (symptom) => ActionChip(
                        label: Text(symptom),
                        onPressed: () => _addLog(initialSymptom: symptom),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              if (logs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Henüz semptom kaydı yok. Veterinere gitmeden önce hızlı not düşmek burada çok işine yarar.',
                  ),
                ),
              ...logs.map(
                (log) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              log.symptom,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          _severityBadge(log.severity),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatDate(log.observedAt),
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      if (log.note != null) ...[
                        const SizedBox(height: 8),
                        Text(log.note!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _severityBadge(String severity) {
    final color = switch (severity) {
      'hafif' => const Color(0xFF2EC4B6),
      'yüksek' => const Color(0xFFFF6B6B),
      _ => Colors.orange,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        severity,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
