import 'package:flutter/material.dart';
import '../shared/app_utils.dart';
import 'vaccine_model.dart';
import 'vaccine_repository.dart';
import 'vaccine_form_page.dart';

class VaccineListPage extends StatefulWidget {
  final String petId;
  final String petName;
  final VaccineRepository repository;

  const VaccineListPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.repository,
  });

  @override
  State<VaccineListPage> createState() => _VaccineListPageState();
}

class _VaccineListPageState extends State<VaccineListPage> {
  late Future<List<Vaccine>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _showActions(Vaccine vaccine) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(ctx);
                _openForm(existing: vaccine);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _delete(vaccine);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reload() {
    _future = widget.repository.getByPetId(widget.petId);
  }

  Future<void> _openForm({Vaccine? existing}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VaccineFormPage(
        repository: widget.repository,
        petId: widget.petId,
        petName: widget.petName,
        existing: existing,
      ),
    ));
    setState(_reload);
  }

  void _delete(Vaccine v) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.delete_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('"${v.name}" silinsin mi?',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Bu işlem geri alınamaz.',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                  onPressed: () async {
                      await widget.repository.delete(v.id);
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(_reload);
                    },
                    style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sil'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Vaccine>>(
        future: _future,
        builder: (context, snapshot) {
          final vaccines = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              _buildHeader(vaccines.length),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (vaccines.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _VaccineCard(
                        vaccine: vaccines[i],
                        onOpenActions: () => _showActions(vaccines[i]),
                      ),
                      childCount: vaccines.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Aşı Ekle',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return SliverToBoxAdapter(
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
            24, MediaQuery.of(context).padding.top + 16, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(children: [
                const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(widget.petName,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 12),
            const Text('Aşı Takibi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              count == 0 ? 'Henüz aşı eklenmedi' : '$count aşı kayıtlı',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vaccines_outlined,
                  size: 48, color: Color(0xFF2EC4B6)),
            ),
            const SizedBox(height: 20),
            const Text('Henüz aşı eklenmedi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text('İlk aşıyı ekleyerek sonraki doz tarihini,\nkalan günü ve hatırlatmalarını burada izle.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade500, height: 1.5)),
          ],
        ),
      );
}

class _VaccineCard extends StatelessWidget {
  final Vaccine vaccine;
  final VoidCallback onOpenActions;

  const _VaccineCard({
    required this.vaccine,
    required this.onOpenActions,
  });

  @override
  Widget build(BuildContext context) {
    final days = vaccine.daysUntilDue;
    final statusColor = vaccine.nextDueDate == null
        ? Colors.grey
        : vaccine.isOverdue
            ? Colors.red
            : vaccine.isDueToday
                ? Colors.deepOrange
                : vaccine.isUpcoming
                    ? Colors.orange
                    : const Color(0xFF2EC4B6);

    final statusLabel = vaccine.nextDueDate == null
        ? 'Tek doz'
        : vaccine.isOverdue
            ? 'Gecikti'
            : vaccine.isDueToday
                ? 'Bugün'
                : vaccine.isUpcoming
                    ? '$days gün kaldı'
                    : '${formatDate(vaccine.nextDueDate!)} · $days gün';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.vaccines_outlined,
                    color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vaccine.name,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Uygulandi: ${formatDate(vaccine.administeredDate)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vaccine.nextDueDate == null
                            ? statusLabel
                            : 'Sonraki doz: $statusLabel',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor),
                      ),
                    ),
                    if (vaccine.reminderEnabled && vaccine.reminderTime != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Hatırlatma: ${vaccine.reminderTime} · ${vaccine.reminderDaysBefore} gün önce',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenActions,
                icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
