import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../shared/app_utils.dart';
import 'caregiver_access_model.dart';
import 'caregiver_repository.dart';

class CaregiverPage extends StatefulWidget {
  final String petId;
  final String petName;
  final CaregiverRepository repository;

  const CaregiverPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.repository,
  });

  @override
  State<CaregiverPage> createState() => _CaregiverPageState();
}

class _CaregiverPageState extends State<CaregiverPage> {
  late Future<List<CaregiverAccess>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.repository.getByPetId(widget.petId);
  }

  Future<void> _addCaregiver() async {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Aile Üyesi');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
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
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Bakıcı adı'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleCtrl,
              decoration: const InputDecoration(labelText: 'Rol'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  final caregiver = CaregiverAccess(
                    id: const Uuid().v4(),
                    petId: widget.petId,
                    name: nameCtrl.text.trim(),
                    role: roleCtrl.text.trim().isEmpty
                        ? 'Bakıcı'
                        : roleCtrl.text.trim(),
                    inviteCode: const Uuid().v4().substring(0, 8).toUpperCase(),
                  );
                  await widget.repository.add(caregiver);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: const Text('Erişim Oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
    if (saved == true) {
      setState(_reload);
    }
  }

  Future<void> _copyCode(CaregiverAccess caregiver) async {
    await Clipboard.setData(ClipboardData(text: caregiver.inviteCode));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${caregiver.name} için davet kodu kopyalandı.')),
    );
  }

  Future<void> _markAction(CaregiverAccess caregiver, String action) async {
    await widget.repository.update(
      caregiver.copyWith(
        lastAction: action,
        lastActiveAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action kayda işlendi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bakıcı Erişimi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCaregiver,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Bakıcı Ekle'),
      ),
      body: FutureBuilder<List<CaregiverAccess>>(
        future: _future,
        builder: (context, snapshot) {
          final caregivers = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '${widget.petName} için aile bireyi veya geçici bakıcı ekleyebilir, kod paylaşabilir ve yapılan son işi aynı kayıtta tutabilirsin.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5),
                ),
              ),
              const SizedBox(height: 16),
              if (caregivers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Henüz bakıcı eklenmedi. İlk erişim kodunu oluşturup eşinle veya bakıcınla paylaşabilirsin.',
                  ),
                ),
              ...caregivers.map(
                (caregiver) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  caregiver.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${caregiver.role} · Kod: ${caregiver.inviteCode}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _copyCode(caregiver),
                            child: const Text('Kopyala'),
                          ),
                        ],
                      ),
                      if (caregiver.lastAction != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Son işlem: ${caregiver.lastAction} · ${formatDate(caregiver.lastActiveAt ?? DateTime.now())}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _quickActionChip(
                            label: 'İlaç verildi',
                            onTap: () => _markAction(caregiver, 'İlaç verildi'),
                          ),
                          _quickActionChip(
                            label: 'Mama verildi',
                            onTap: () => _markAction(caregiver, 'Mama verildi'),
                          ),
                          _quickActionChip(
                            label: 'Yürüyüş yapıldı',
                            onTap: () => _markAction(caregiver, 'Yürüyüş yapıldı'),
                          ),
                        ],
                      ),
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

  Widget _quickActionChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2EC4B6).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2EC4B6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
