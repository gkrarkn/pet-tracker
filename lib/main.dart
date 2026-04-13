import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pet/pet_repository.dart';
import 'pet/pet_list_page.dart';
import 'documents/document_repository.dart';
import 'vet_visit/vet_visit_repository.dart';
import 'vaccine/vaccine_repository.dart';
import 'weight/weight_repository.dart';
import 'medication/medication_repository.dart';
import 'care/care_repository.dart';
import 'symptoms/symptom_repository.dart';
import 'caregiver/caregiver_repository.dart';
import 'shared/app_utils.dart';
import 'notifications/notification_service.dart';
import 'onboarding/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermission();
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(PetTrackerApp(showOnboarding: !onboardingDone));
}

class PetTrackerApp extends StatelessWidget {
  final bool showOnboarding;
  PetTrackerApp({super.key, required this.showOnboarding});

  final petRepository = PetRepository();
  final documentRepository = DocumentRepository();
  final vetVisitRepository = VetVisitRepository();
  final vaccineRepository = VaccineRepository();
  final weightRepository = WeightRepository();
  final medicationRepository = MedicationRepository();
  final careRepository = CareRepository();
  final symptomRepository = SymptomRepository();
  final caregiverRepository = CaregiverRepository();

  static ThemeData _lightTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2EC4B6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A2E),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2EC4B6), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2EC4B6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2EC4B6),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      );

  static ThemeData _darkTheme() => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2EC4B6),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF2EC4B6), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2EC4B6),
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2EC4B6),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Tracker',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: ThemeMode.system,
      home: _AppRouter(
        showOnboarding: showOnboarding,
        petRepository: petRepository,
        documentRepository: documentRepository,
        vetVisitRepository: vetVisitRepository,
        vaccineRepository: vaccineRepository,
        weightRepository: weightRepository,
        medicationRepository: medicationRepository,
        careRepository: careRepository,
        symptomRepository: symptomRepository,
        caregiverRepository: caregiverRepository,
      ),
    );
  }
}

class _AppRouter extends StatefulWidget {
  final bool showOnboarding;
  final PetRepository petRepository;
  final DocumentRepository documentRepository;
  final VetVisitRepository vetVisitRepository;
  final VaccineRepository vaccineRepository;
  final WeightRepository weightRepository;
  final MedicationRepository medicationRepository;
  final CareRepository careRepository;
  final SymptomRepository symptomRepository;
  final CaregiverRepository caregiverRepository;

  const _AppRouter({
    required this.showOnboarding,
    required this.petRepository,
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
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
    _syncNotifications();
  }

  Future<void> _syncNotifications() async {
    final pets = await widget.petRepository.getAll();
    final petNames = {for (final pet in pets) pet.id: pet.name};

    final upcomingVaccines = await widget.vaccineRepository.getUpcoming();
    for (final vaccine in upcomingVaccines) {
      final reminderTime =
          NotificationService.parseReminderTime(vaccine.reminderTime);
      final id = NotificationService.idFromString(vaccine.id);
      await NotificationService.instance.cancel(id);
      if (vaccine.reminderEnabled && vaccine.nextDueDate != null) {
        await NotificationService.instance.scheduleVaccineReminder(
          id: id,
          petName: petNames[vaccine.petId] ?? 'Evcil hayvanin',
          vaccineName: vaccine.name,
          dueDate: vaccine.nextDueDate!,
          time: reminderTime,
          daysBefore: vaccine.reminderDaysBefore,
        );
      }
    }

    final activeMeds = await widget.medicationRepository.getAllActive();
    for (final med in activeMeds) {
      final reminderTime =
          NotificationService.parseReminderTime(med.reminderTime);
      final id = NotificationService.idFromString(med.id);
      await NotificationService.instance.cancel(id);
      if (med.reminderEnabled && reminderTime != null) {
        await NotificationService.instance.scheduleMedicationReminder(
          id: id,
          medicationId: med.id,
          petName: petNames[med.petId] ?? 'Evcil hayvanin',
          medicationName: med.name,
          dosage: med.dosage,
          time: reminderTime,
        );
      }
    }

    final upcomingVisits = await widget.vetVisitRepository.getUpcoming(withinDays: 90);
    for (final visit in upcomingVisits) {
      final reminderTime =
          NotificationService.parseReminderTime(visit.reminderTime);
      final id = NotificationService.idFromString(visit.id);
      await NotificationService.instance.cancel(id);
      if (visit.reminderEnabled) {
        await NotificationService.instance.scheduleVetReminder(
          id: id,
          petName: petNames[visit.petId] ?? 'Evcil hayvanin',
          reason: visit.reason,
          visitDate: visit.visitDate,
          time: reminderTime,
          daysBefore: visit.reminderDaysBefore,
        );
      }
    }

    final careTasks = await widget.careRepository.getAllActive();
    for (final task in careTasks) {
      final reminderTime =
          NotificationService.parseReminderTime(task.reminderTime);
      final id = NotificationService.idFromString(task.id);
      await NotificationService.instance.cancel(id);
      if (task.reminderEnabled) {
        final dueDate = effectiveCareDueDate(
          startDate: task.startDate,
          lastCompletedAt: task.lastCompletedAt,
          skippedUntil: task.skippedUntil,
          frequency: task.frequency,
        );
        await NotificationService.instance.scheduleCareReminder(
          id: id,
          petName: petNames[task.petId] ?? 'Evcil hayvanın',
          taskTitle: task.title,
          dueDate: dueDate,
          taskId: task.id,
          time: reminderTime,
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingPage(onDone: _completeOnboarding);
    }
    return PetListPage(
      repository: widget.petRepository,
      documentRepository: widget.documentRepository,
      vetVisitRepository: widget.vetVisitRepository,
      vaccineRepository: widget.vaccineRepository,
      weightRepository: widget.weightRepository,
      medicationRepository: widget.medicationRepository,
      careRepository: widget.careRepository,
      symptomRepository: widget.symptomRepository,
      caregiverRepository: widget.caregiverRepository,
    );
  }
}
