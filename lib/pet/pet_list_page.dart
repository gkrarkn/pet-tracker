import 'dart:io';
import 'package:flutter/material.dart';
import 'pet_model.dart';
import 'pet_repository.dart';
import 'pet_form_page.dart';
import 'pet_profile_page.dart';
import '../documents/document_repository.dart';
import '../vet_visit/vet_visit_repository.dart';
import '../vet_visit/vet_visit_model.dart';
import '../vet_visit/vet_visit_list_page.dart';
import '../vaccine/vaccine_repository.dart';
import '../vaccine/vaccine_list_page.dart';
import '../vaccine/vaccine_model.dart';
import '../weight/weight_repository.dart';
import '../medication/medication_repository.dart';
import '../care/care_repository.dart';
import '../symptoms/symptom_repository.dart';
import '../caregiver/caregiver_repository.dart';
import '../shared/app_utils.dart';

class PetListPage extends StatefulWidget {
  final PetRepository repository;
  final DocumentRepository documentRepository;
  final VetVisitRepository vetVisitRepository;
  final VaccineRepository vaccineRepository;
  final WeightRepository weightRepository;
  final MedicationRepository medicationRepository;
  final CareRepository careRepository;
  final SymptomRepository symptomRepository;
  final CaregiverRepository caregiverRepository;

  const PetListPage({
    super.key,
    required this.repository,
    required this.documentRepository,
    required this.vetVisitRepository,
    required this.vaccineRepository,
    required this.weightRepository,
    required this.medicationRepository,
    required this.careRepository,
    required this.symptomRepository,
    required this.caregiverRepository,
  });

  @override
  State<PetListPage> createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _dataFuture = _loadData();
  }

  Future<_DashboardData> _loadData() async {
    final pets = await widget.repository.getAll();
    final now = DateTime.now();
    final today = startOfDay(now);
    final thisMonth = pets.isEmpty
        ? <VetVisit>[]
        : (await Future.wait(
            pets.map((p) => widget.vetVisitRepository.getByPetId(p.id)),
          ))
            .expand((v) => v)
            .where((v) =>
                v.visitDate.year == now.year &&
                v.visitDate.month == now.month)
            .toList();

    // son 5 ziyaret (tüm hayvanlar)
    final allVisits = pets.isEmpty
        ? <VetVisit>[]
        : (await Future.wait(
            pets.map((p) => widget.vetVisitRepository.getByPetId(p.id)),
          ))
            .expand((v) => v)
            .toList()
          ..sort((a, b) => b.visitDate.compareTo(a.visitDate));

    final petMap = {for (final pet in pets) pet.id: pet};
    final upcomingTasks = <_UpcomingTask>[];
    final petTaskMap = <String, List<_UpcomingTask>>{};

    final upcomingVaccines = pets.isEmpty
        ? <Vaccine>[]
        : (await Future.wait(
            pets.map((p) => widget.vaccineRepository.getByPetId(p.id)),
          ))
            .expand((v) => v)
            .where((v) =>
                v.nextDueDate != null &&
                (v.isOverdue || (v.daysUntilDue != null && v.daysUntilDue! <= 14)))
            .toList();

    for (final vaccine in upcomingVaccines) {
      final pet = petMap[vaccine.petId];
      final days = vaccine.daysUntilDue;
      upcomingTasks.add(
        _UpcomingTask(
          pet: pet,
          type: 'vaccine',
          title: vaccine.name,
          subtitle: vaccine.isOverdue
              ? 'Aşı dozu gecikti'
              : vaccine.isDueToday
                  ? 'Bugün uygulanacak'
                  : '$days gün sonra doz var',
          dueDate: vaccine.nextDueDate!,
          accent: vaccine.isOverdue
              ? Colors.red
              : vaccine.isUpcoming || vaccine.isDueToday
                  ? Colors.orange
                  : const Color(0xFF2EC4B6),
          icon: Icons.vaccines_outlined,
        ),
      );
      petTaskMap.putIfAbsent(vaccine.petId, () => []).add(upcomingTasks.last);
    }

    final activeMeds = await widget.medicationRepository.getAllActive();
    for (final med in activeMeds.where((m) => m.isScheduledToday)) {
      final pet = petMap[med.petId];
      final log = await widget.medicationRepository.getLogForDate(
        medicationId: med.id,
        scheduledDate: today,
      );
      upcomingTasks.add(
        _UpcomingTask(
          pet: pet,
          type: 'medication',
          title: med.name,
          subtitle: log == null
              ? 'Bugünkü doz bekliyor'
              : log.isTaken
                  ? 'Bugünkü doz alındı'
                  : 'Bugünkü doz alınmadı',
          dueDate: combineDateAndTime(today, med.reminderTime),
          accent: log == null
              ? const Color(0xFFFF6B6B)
              : log.isTaken
                  ? const Color(0xFF2EC4B6)
                  : Colors.red,
          icon: Icons.medication_outlined,
        ),
      );
      petTaskMap.putIfAbsent(med.petId, () => []).add(upcomingTasks.last);
    }

    final upcomingVisits = await widget.vetVisitRepository.getUpcoming(withinDays: 14);
    for (final visit in upcomingVisits) {
      final pet = petMap[visit.petId];
      upcomingTasks.add(
        _UpcomingTask(
          pet: pet,
          type: 'visit',
          title: visit.reason,
          subtitle:
              '${visitCategoryLabel(visit.category)} ziyareti · ${daysBetween(today, visit.visitDate)} gün sonra',
          dueDate: visit.visitDate,
          accent: visitCategoryColor(visit.category),
          icon: Icons.medical_services_outlined,
        ),
      );
      petTaskMap.putIfAbsent(visit.petId, () => []).add(upcomingTasks.last);
    }

    final careTasks = await widget.careRepository.getAllActive();
    for (final task in careTasks) {
      final pet = petMap[task.petId];
      final dueDate = effectiveCareDueDate(
        startDate: task.startDate,
        lastCompletedAt: task.lastCompletedAt,
        skippedUntil: task.skippedUntil,
        frequency: task.frequency,
      );
      if (daysBetween(today, dueDate) <= 7) {
        upcomingTasks.add(
          _UpcomingTask(
            pet: pet,
            type: 'care',
            title: task.title,
            subtitle:
                '${careTypeLabel(task.type)} · ${daysBetween(today, dueDate) <= 0 ? 'Bugün bakım zamanı' : '${daysBetween(today, dueDate)} gün sonra'}',
            dueDate: dueDate,
            accent: careTypeColor(task.type),
            icon: Icons.spa_outlined,
          ),
        );
        petTaskMap.putIfAbsent(task.petId, () => []).add(upcomingTasks.last);
      }
    }

    upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final insights = <_SmartInsight>[];
    for (final pet in pets) {
      final latest = await widget.weightRepository.getLatest(pet.id);
      final weights = await widget.weightRepository.getByPetId(pet.id);
      final monthAgo = now.subtract(const Duration(days: 30));
      final monthWeights =
          weights.where((record) => record.recordedAt.isAfter(monthAgo)).toList();
      String weightText = 'Son 30 günde yeterli kilo verisi yok';
      if (monthWeights.length >= 2) {
        final delta = monthWeights.last.weightKg - monthWeights.first.weightKg;
        weightText =
            '${pet.name}: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg değişim';
      }

      final medicationMissed = await Future.wait(
        (await widget.medicationRepository.getByPetId(pet.id))
            .map((med) => widget.medicationRepository.getLogsByMedication(med.id)),
      );
      final missedCount = medicationMissed
          .expand((logs) => logs)
          .where((log) =>
              log.isMissed &&
              log.scheduledDate.isAfter(now.subtract(const Duration(days: 30))))
          .length;

      final sevenDayPlan = (petTaskMap[pet.id] ?? [])
          .where((task) => daysBetween(today, task.dueDate) <= 7)
          .length;

      insights.add(
        _SmartInsight(
          petName: pet.name,
          weightSummary: weightText,
          missedDoseSummary: '$missedCount atlanan doz',
          planSummary: '$sevenDayPlan görev / 7 gün',
          latestWeight: latest?.weightKg,
        ),
      );
    }

    return _DashboardData(
      pets: pets,
      thisMonthVisits: thisMonth.length,
      recentVisits: allVisits.take(5).toList(),
      upcomingTasks: upcomingTasks.take(8).toList(),
      insights: insights,
    );
  }

  Future<void> _openForm({Pet? existing}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          PetFormPage(repository: widget.repository, existing: existing),
    ));
    setState(_reload);
  }

  void _goToProfile(Pet pet) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PetProfilePage(
        pet: pet,
        repository: widget.repository,
        documentRepository: widget.documentRepository,
        vetVisitRepository: widget.vetVisitRepository,
        vaccineRepository: widget.vaccineRepository,
        weightRepository: widget.weightRepository,
        medicationRepository: widget.medicationRepository,
        careRepository: widget.careRepository,
        symptomRepository: widget.symptomRepository,
        caregiverRepository: widget.caregiverRepository,
      ),
    ));
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_DashboardData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ??
              _DashboardData(
                pets: [],
                thisMonthVisits: 0,
                recentVisits: [],
                upcomingTasks: [],
                insights: [],
              );
          return CustomScrollView(
            slivers: [
              _buildHeader(data),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(data),
                    const SizedBox(height: 24),
                    _buildPetsSection(data.pets),
                    const SizedBox(height: 24),
                    _buildUpcomingTasks(data),
                    const SizedBox(height: 24),
                    _buildSmartInsights(data),
                    const SizedBox(height: 24),
                    _buildRecentVisits(data),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(_DashboardData data) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Günaydın'
        : hour < 18
            ? 'İyi günler'
            : 'İyi akşamlar';

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2EC4B6), Color(0xFF3D8BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(36)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, MediaQuery.of(context).padding.top + 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 2),
                    const Text('Pet Tracker',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _openForm(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── STATS ────────────────────────────────────────────────────────────────────
  Widget _buildStatsRow(_DashboardData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
            icon: Icons.pets,
            label: 'Hayvan',
              value: '${data.pets.length}',
              color: const Color(0xFF2EC4B6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
            icon: Icons.medical_services_outlined,
            label: 'Bu ay ziyaret',
              value: '${data.thisMonthVisits}',
              color: const Color(0xFF3D8BFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
            icon: Icons.notifications_active_outlined,
            label: 'Yaklaşan görev',
              value: '${data.upcomingTasks.length}',
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasks(_DashboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bugün / Yakında Yapılacaklar',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 14),
          if (data.upcomingTasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.task_alt, color: Color(0xFFFF6B6B)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Bugün için acil görev yok. Yeni aşı, ilaç veya kontrol planlayarak bu alanı aktif kullanabilirsin.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...data.upcomingTasks.map((task) => GestureDetector(
                  onTap: () => _openTask(task),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: task.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(task.icon, color: task.accent, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${task.pet?.name ?? 'Bilinmeyen'} · ${task.subtitle}',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatShortDate(task.dueDate),
                          style: TextStyle(
                            color: task.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildSmartInsights(_DashboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Akıllı Özetler',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 14),
          if (data.insights.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Özet kartları veri geldikçe burada görünecek.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.insights.length,
                separatorBuilder: (_, index) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final insight = data.insights[index];
                  return Container(
                    width: 250,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(insight.petName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 12),
                        _summaryRow(Icons.monitor_weight_outlined, insight.weightSummary),
                        const SizedBox(height: 8),
                        _summaryRow(Icons.medication_outlined, insight.missedDoseSummary),
                        const SizedBox(height: 8),
                        _summaryRow(Icons.event_note_outlined, insight.planSummary),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2EC4B6)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
          ),
        ],
      );

  void _openTask(_UpcomingTask task) {
    final pet = task.pet;
    if (pet == null) return;
    if (task.type == 'visit') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VetVisitListPage(
          petId: pet.id,
          petName: pet.name,
          repository: widget.vetVisitRepository,
        ),
      ));
      return;
    }
    if (task.type == 'vaccine') {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VaccineListPage(
          petId: pet.id,
          petName: pet.name,
          repository: widget.vaccineRepository,
        ),
      ));
      return;
    }
    _goToProfile(pet);
  }

  // ── PETS SECTION ─────────────────────────────────────────────────────────────
  Widget _buildPetsSection(List<Pet> pets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Evcil Hayvanlarım',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              if (pets.isNotEmpty)
                GestureDetector(
                  onTap: () => _openForm(),
                  child: const Text('+ Ekle',
                      style: TextStyle(
                          color: Color(0xFF2EC4B6),
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (pets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _EmptyPetCard(onTap: () => _openForm()),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: pets.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                if (i == pets.length) {
                  return _AddPetCard(onTap: () => _openForm());
                }
                return _PetBigCard(
                  pet: pets[i],
                  onTap: () => _goToProfile(pets[i]),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── RECENT VISITS ─────────────────────────────────────────────────────────────
  Widget _buildRecentVisits(_DashboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Son Veteriner Ziyaretleri',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 14),
          if (data.recentVisits.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D8BFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medical_services_outlined,
                        color: Color(0xFF3D8BFF), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Text('Henüz ziyaret kaydedilmedi.',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                ],
              ),
            )
          else
            ...data.recentVisits.map((v) {
              final pet = data.pets.firstWhere(
                (p) => p.id == v.petId,
                orElse: () => Pet(
                  id: '',
                  name: '?',
                  species: '',
                  breed: '',
                  birthDate: DateTime.now(),
                  themeColor: 'teal',
                  themeIcon: 'pets',
                ),
              );
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => VetVisitListPage(
                    petId: pet.id,
                    petName: pet.name,
                    repository: widget.vetVisitRepository,
                  ),
                )),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      // pet mini avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: pet.photoUrl == null
                              ? LinearGradient(
                                  colors: [
                                    petThemePrimary(pet.themeColor),
                                    petThemeSecondary(pet.themeColor)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          image: pet.photoUrl != null
                              ? DecorationImage(
                                  image: FileImage(File(pet.photoUrl!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: pet.photoUrl == null
                            ? Center(
                                child: Text(
                                  pet.name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.reason,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: petThemePrimary(pet.themeColor)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(pet.name,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: petThemePrimary(pet.themeColor))),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  v.visitDate
                                      .toLocal()
                                      .toString()
                                      .split(' ')[0],
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFFD0D0D0), size: 20),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── DATA CLASS ────────────────────────────────────────────────────────────────
class _DashboardData {
  final List<Pet> pets;
  final int thisMonthVisits;
  final List<VetVisit> recentVisits;
  final List<_UpcomingTask> upcomingTasks;
  final List<_SmartInsight> insights;

  _DashboardData({
    required this.pets,
    required this.thisMonthVisits,
    required this.recentVisits,
    required this.upcomingTasks,
    required this.insights,
  });
}

class _UpcomingTask {
  final Pet? pet;
  final String type;
  final String title;
  final String subtitle;
  final DateTime dueDate;
  final Color accent;
  final IconData icon;

  _UpcomingTask({
    required this.pet,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.dueDate,
    required this.accent,
    required this.icon,
  });
}

class _SmartInsight {
  final String petName;
  final String weightSummary;
  final String missedDoseSummary;
  final String planSummary;
  final double? latestWeight;

  _SmartInsight({
    required this.petName,
    required this.weightSummary,
    required this.missedDoseSummary,
    required this.planSummary,
    this.latestWeight,
  });
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── PET BIG CARD ──────────────────────────────────────────────────────────────
class _PetBigCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const _PetBigCard({required this.pet, required this.onTap});

  int get _age {
    final now = DateTime.now();
    int a = now.year - pet.birthDate.year;
    if (now.month < pet.birthDate.month ||
        (now.month == pet.birthDate.month && now.day < pet.birthDate.day)) {
      a--;
    }
    return a;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: petThemePrimary(pet.themeColor).withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // gradient background (always visible; covered by photo if exists)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      petThemePrimary(pet.themeColor),
                      petThemeSecondary(pet.themeColor)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // photo on top
              if (pet.photoUrl != null)
                Image.file(
                  File(pet.photoUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => const SizedBox.shrink(),
                ),
              // dark bottom gradient for text readability
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 90,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              if (pet.photoUrl == null)
                Positioned(
                  top: 28,
                  left: 0,
                  right: 0,
                  child: Icon(
                    petThemeIcon(pet.themeIcon),
                    size: 48,
                    color: Colors.white38,
                  ),
                ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('$_age yaş · ${pet.species}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ADD PET CARD ──────────────────────────────────────────────────────────────
class _AddPetCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: const Color(0xFF2EC4B6).withValues(alpha: 0.4),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add,
                  color: Color(0xFF2EC4B6), size: 24),
            ),
            const SizedBox(height: 8),
            const Text('Ekle',
                style: TextStyle(
                    color: Color(0xFF2EC4B6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── EMPTY PET CARD ────────────────────────────────────────────────────────────
class _EmptyPetCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyPetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2EC4B6).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add,
                  color: Color(0xFF2EC4B6), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('İlk evcil hayvanını ekle',
                style: TextStyle(
                    color: Color(0xFF2EC4B6),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
