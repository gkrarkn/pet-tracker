import 'package:flutter/material.dart';
import '../notifications/notification_service.dart';
import '../shared/app_utils.dart';
import 'medication_form_page.dart';
import 'medication_log_model.dart';
import 'medication_model.dart';
import 'medication_repository.dart';

class MedicationListPage extends StatefulWidget {
  final String petId;
  final String petName;
  final MedicationRepository repository;

  const MedicationListPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.repository,
  });

  @override
  State<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Medication>> _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    _future = widget.repository.getByPetId(widget.petId);
  }

  Future<void> _openForm({Medication? existing}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MedicationFormPage(
          repository: widget.repository,
          petId: widget.petId,
          petName: widget.petName,
          existing: existing,
        ),
      ),
    );
    setState(_reload);
  }

  Future<void> _showDeleteSheet(Medication medication) async {
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
            _sheetHandle(),
            const SizedBox(height: 24),
            const Icon(Icons.delete_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              '"${medication.name}" silinsin mi?',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Silmeden önce bugünkü ilaç durumunu kontrol etmeni öneririz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await widget.repository.delete(medication.id);
                      await NotificationService.instance
                          .cancel(NotificationService.idFromString(medication.id));
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(_reload);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  Future<void> _showActions(Medication medication) async {
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
            _sheetHandle(),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(ctx);
                _openForm(existing: medication);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                medication.isActive ? Icons.pause_circle_outline : Icons.play_circle,
                color: const Color(0xFFFF6B6B),
              ),
              title: Text(medication.isActive ? 'Pasife al' : 'Yeniden etkinleştir'),
              onTap: () async {
                await widget.repository.setActive(medication.id, !medication.isActive);
                if (ctx.mounted) Navigator.pop(ctx);
                setState(_reload);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteSheet(medication);
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
      body: FutureBuilder<List<Medication>>(
        future: _future,
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          final active = all.where((m) => m.isActive && m.isOngoing).toList();
          final past = all.where((m) => !m.isActive || !m.isOngoing).toList();

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildHeader(active.length),
              SliverToBoxAdapter(
                child: Container(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFFF6B6B),
                    labelColor: const Color(0xFFFF6B6B),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    tabs: [
                      Tab(text: 'Aktif (${active.length})'),
                      Tab(text: 'Geçmiş (${past.length})'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildList(active, emptyTitle: 'Bugün için aktif ilaç yok'),
                _buildList(
                  past,
                  emptyTitle: 'Geçmiş ilaç kaydı yok',
                  emptyBody:
                      'Tamamlanan veya pasife alınan ilaçlar burada listelenecek.',
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFFFF6B6B),
        icon: const Icon(Icons.add),
        label: const Text('İlaç Ekle', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildList(
    List<Medication> meds, {
    required String emptyTitle,
    String emptyBody =
        'Tedaviyi baslatmak icin doz, saat ve bitis tarihini ekleyebilirsin.',
  }) {
    if (meds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 40,
                  color: Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptyBody,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: meds.length,
      itemBuilder: (_, i) => _MedicationCard(
        medication: meds[i],
        repository: widget.repository,
        onChanged: () => setState(_reload),
        onOpenActions: () => _showActions(meds[i]),
      ),
    );
  }

  Widget _buildHeader(int activeCount) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          MediaQuery.of(context).padding.top + 16,
          24,
          20,
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
                  Text(
                    widget.petName,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'İlaç Takibi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              activeCount == 0
                  ? 'Saatli tedavi ve günlük ilaç durumu burada takip edilir'
                  : '$activeCount aktif ilaç tedavisi var',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetHandle() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final MedicationRepository repository;
  final VoidCallback onChanged;
  final VoidCallback onOpenActions;

  const _MedicationCard({
    required this.medication,
    required this.repository,
    required this.onChanged,
    required this.onOpenActions,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = medication.isActive && medication.isOngoing;
    final color = isActive ? const Color(0xFFFF6B6B) : Colors.grey;
    final reminderText = medication.reminderTime == null
        ? 'Saat belirtilmedi'
        : 'Saat ${medication.reminderTime}';

    return FutureBuilder<MedicationLog?>(
      future: repository.getLogForDate(
        medicationId: medication.id,
        scheduledDate: DateTime.now(),
      ),
      builder: (context, snapshot) {
        final todayLog = snapshot.data;
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
                        child: Icon(Icons.medication_outlined, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medication.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${medication.dosage}  ·  ${medication.frequency}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onOpenActions,
                        icon: Icon(Icons.more_horiz, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(Icons.calendar_today_outlined, 'Başlangıç ${formatDate(medication.startDate)}'),
                      _pill(
                        Icons.notifications_outlined,
                        medication.reminderEnabled ? reminderText : 'Hatırlatma kapalı',
                        color: medication.reminderEnabled
                            ? const Color(0xFFFF6B6B)
                            : Colors.grey.shade500,
                      ),
                      _pill(
                        medication.endDate == null
                            ? Icons.all_inclusive
                            : Icons.event_available_outlined,
                        medication.endDate == null
                            ? 'Süresiz'
                            : 'Bitiş ${formatDate(medication.endDate!)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bugünün durumu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _todayStatusLabel(medication, todayLog),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: medication.isScheduledToday
                                  ? () async {
                                      await repository.markMedicationStatus(
                                        medication: medication,
                                        scheduledDate: DateTime.now(),
                                        taken: true,
                                      );
                                      onChanged();
                                    }
                                  : null,
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Alindi'),
                            ),
                            OutlinedButton.icon(
                              onPressed: medication.isScheduledToday
                                  ? () async {
                                      await repository.markMedicationStatus(
                                        medication: medication,
                                        scheduledDate: DateTime.now(),
                                        taken: false,
                                      );
                                      onChanged();
                                    }
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline, size: 16),
                              label: const Text('Alinmadi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (medication.notes != null && medication.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      medication.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _todayStatusLabel(Medication medication, MedicationLog? todayLog) {
    if (!medication.isScheduledToday) {
      return 'Bugün için planlı doz yok';
    }
    if (todayLog == null) {
      return 'Bugünkü dozu henüz işaretlenmedi';
    }
    if (todayLog.isTaken) {
      return 'Doz alındı';
    }
    if (todayLog.isMissed) {
      return 'Doz alınmadı';
    }
    return 'Durum bekleniyor';
  }

  Widget _pill(IconData icon, String label, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey.shade500).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color ?? Colors.grey.shade500),
            ),
          ],
        ),
      );
}
