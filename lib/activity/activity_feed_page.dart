import 'package:flutter/material.dart';
import '../shared/app_utils.dart';
import '../vet_visit/vet_visit_repository.dart';
import '../vaccine/vaccine_repository.dart';
import '../weight/weight_repository.dart';
import '../medication/medication_repository.dart';
import '../care/care_repository.dart';

class _FeedItem {
  final String type;
  final String title;
  final String subtitle;
  final DateTime date;
  final Color color;
  final IconData icon;

  const _FeedItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.color,
    required this.icon,
  });
}

class ActivityFeedPage extends StatefulWidget {
  final String petId;
  final String petName;
  final VetVisitRepository vetVisitRepository;
  final VaccineRepository vaccineRepository;
  final WeightRepository weightRepository;
  final MedicationRepository medicationRepository;
  final CareRepository careRepository;

  const ActivityFeedPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.vetVisitRepository,
    required this.vaccineRepository,
    required this.weightRepository,
    required this.medicationRepository,
    required this.careRepository,
  });

  @override
  State<ActivityFeedPage> createState() => _ActivityFeedPageState();
}

class _ActivityFeedPageState extends State<ActivityFeedPage> {
  late Future<List<_FeedItem>> _future;
  String _filter = 'all';

  static const _filters = [
    ('all', 'Tümü'),
    ('visit', 'Ziyaret'),
    ('vaccine', 'Aşı'),
    ('weight', 'Kilo'),
    ('medication', 'İlaç'),
    ('care', 'Bakım'),
  ];

  @override
  void initState() {
    super.initState();
    _future = _loadFeed();
  }

  Future<List<_FeedItem>> _loadFeed() async {
    final items = <_FeedItem>[];

    final visits = await widget.vetVisitRepository.getByPetId(widget.petId);
    for (final v in visits) {
      items.add(_FeedItem(
        type: 'visit',
        title: v.reason,
        subtitle: [
          visitCategoryLabel(v.category),
          if (v.vetName != null) v.vetName!,
        ].join(' · '),
        date: v.visitDate,
        color: visitCategoryColor(v.category),
        icon: Icons.medical_services_outlined,
      ));
    }

    final vaccines = await widget.vaccineRepository.getByPetId(widget.petId);
    for (final v in vaccines) {
      items.add(_FeedItem(
        type: 'vaccine',
        title: v.name,
        subtitle: 'Uygulama tarihi',
        date: v.administeredDate,
        color: const Color(0xFF2EC4B6),
        icon: Icons.vaccines_outlined,
      ));
    }

    final weights = await widget.weightRepository.getByPetId(widget.petId);
    for (final w in weights) {
      items.add(_FeedItem(
        type: 'weight',
        title: '${w.weightKg.toStringAsFixed(1)} kg',
        subtitle: w.notes ?? 'Kilo ölçümü',
        date: w.recordedAt,
        color: const Color(0xFF6C63FF),
        icon: Icons.monitor_weight_outlined,
      ));
    }

    final meds = await widget.medicationRepository.getByPetId(widget.petId);
    for (final m in meds) {
      items.add(_FeedItem(
        type: 'medication',
        title: m.name,
        subtitle: '${m.dosage} · ${m.frequency}',
        date: m.startDate,
        color: const Color(0xFFFF6B6B),
        icon: Icons.medication_outlined,
      ));
    }

    final careTasks = await widget.careRepository.getByPetId(widget.petId);
    for (final c in careTasks) {
      if (c.lastCompletedAt != null) {
        items.add(_FeedItem(
          type: 'care',
          title: c.title,
          subtitle: careTypeLabel(c.type),
          date: c.lastCompletedAt!,
          color: careTypeColor(c.type),
          icon: Icons.spa_outlined,
        ));
      }
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  List<_FeedItem> _applyFilter(List<_FeedItem> items) {
    if (_filter == 'all') return items;
    return items.where((i) => i.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<_FeedItem>>(
        future: _future,
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          final items = _applyFilter(all);

          return CustomScrollView(
            slivers: [
              _buildHeader(all.length),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final selected = _filter == f.$1;
                      return ChoiceChip(
                        label: Text(f.$2),
                        selected: selected,
                        selectedColor: const Color(0xFF2EC4B6),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : null,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (_) =>
                            setState(() => _filter = f.$1),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (items.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, index) {
                        final item = items[index];
                        final showDate = index == 0 ||
                            !_isSameDay(items[index - 1].date, item.date);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showDate)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 16, 0, 8),
                                child: Text(
                                  _dateHeader(item.date),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            _FeedCard(item: item),
                          ],
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(int total) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2EC4B6), Color(0xFF3D8BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, MediaQuery.of(context).padding.top + 16, 24, 24),
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
            const Text('Aktivite Geçmişi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              '$total kayıt',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
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
              child: const Icon(Icons.history, size: 48, color: Color(0xFF2EC4B6)),
            ),
            const SizedBox(height: 20),
            const Text('Kayıt bulunamadı',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                _filter == 'all'
                    ? 'Aşı, kilo, ilaç veya ziyaret ekledikçe\nburada görünür.'
                    : 'Bu kategoride kayıt yok.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
          ],
        ),
      );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'BUGÜN';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'DÜN';
    return formatDate(date).toUpperCase();
  }
}

class _FeedCard extends StatelessWidget {
  final _FeedItem item;
  const _FeedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface)),
                if (item.subtitle.isNotEmpty)
                  Text(item.subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(
            formatDate(item.date),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
