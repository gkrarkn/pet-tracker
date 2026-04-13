import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, PlatformException, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pet_model.dart';
import 'pet_repository.dart';
import 'pet_form_page.dart';
import '../caregiver/caregiver_page.dart';
import '../caregiver/caregiver_repository.dart';
import '../care/care_page.dart';
import '../care/care_repository.dart';
import '../care/care_task_model.dart';
import '../documents/document_gallery_page.dart';
import '../documents/document_repository.dart';
import '../symptoms/symptom_page.dart';
import '../symptoms/symptom_repository.dart';
import '../travel/travel_mode_page.dart';
import '../vet_visit/vet_visit_repository.dart';
import '../vet_visit/vet_visit_list_page.dart';
import '../vet_visit/vet_visit_model.dart';
import '../vaccine/vaccine_repository.dart';
import '../vaccine/vaccine_list_page.dart';
import '../vaccine/vaccine_model.dart';
import '../weight/weight_repository.dart';
import '../weight/weight_page.dart';
import '../medication/medication_repository.dart';
import '../medication/medication_list_page.dart';
import '../medication/medication_model.dart';
import '../shared/app_utils.dart';

class PetProfilePage extends StatefulWidget {
  final Pet pet;
  final PetRepository repository;
  final DocumentRepository documentRepository;
  final VetVisitRepository vetVisitRepository;
  final VaccineRepository vaccineRepository;
  final WeightRepository weightRepository;
  final MedicationRepository medicationRepository;
  final CareRepository careRepository;
  final SymptomRepository symptomRepository;
  final CaregiverRepository caregiverRepository;

  const PetProfilePage({
    super.key,
    required this.pet,
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
  State<PetProfilePage> createState() => _PetProfilePageState();
}

class _PetProfilePageState extends State<PetProfilePage> {
  late Pet _pet;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  int get _ageInYears {
    final now = DateTime.now();
    int age = now.year - _pet.birthDate.year;
    if (now.month < _pet.birthDate.month ||
        (now.month == _pet.birthDate.month && now.day < _pet.birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _editPet() async {
    final updated = await Navigator.of(context).push<Pet>(
      MaterialPageRoute(
        builder: (_) =>
            PetFormPage(repository: widget.repository, existing: _pet),
      ),
    );
    if (updated != null) setState(() => _pet = updated);
  }

  Future<void> _shareSummary() async {
    final data = await _buildShareSummaryData();
    final shareOrigin = _shareOrigin;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
              leading: const Icon(Icons.text_snippet_outlined),
              title: const Text('Metin olarak paylaş'),
              subtitle: const Text('Hızlı paylaşım için kısa sağlık özeti'),
              onTap: () async {
                Navigator.pop(ctx);
                await Share.share(
                  data.summaryText.trim(),
                  subject: '${_pet.name} sağlık özeti',
                  sharePositionOrigin: shareOrigin,
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF olarak paylaş'),
              subtitle: const Text('Veteriner için düzenli bir çıktı oluştur'),
              onTap: () async {
                Navigator.pop(ctx);
                await _shareSummaryPdf(data, shareOrigin);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama başlatılamadı.')),
        );
      }
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arama servisi henüz hazır değil. Uygulamayı yeniden başlatıp tekrar dene.'),
        ),
      );
    }
  }

  Future<void> _launchDirections(String address) async {
    final encoded = Uri.encodeComponent(address);
    final appleMaps = Uri.parse('http://maps.apple.com/?daddr=$encoded');
    final googleMaps = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$encoded&travelmode=driving',
    );
    try {
      if (await launchUrl(appleMaps, mode: LaunchMode.externalApplication)) {
        return;
      }
      final launched =
          await launchUrl(googleMaps, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harita açılamadı.')),
        );
      }
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harita servisi henüz hazır değil. Uygulamayı yeniden başlatıp tekrar dene.'),
        ),
      );
    }
  }

  Future<void> _copyVisitDetails(VetVisit visit) async {
    final details = <String>[
      '${_pet.name} - Veteriner Ziyareti',
      'Tür: ${visitCategoryLabel(visit.category)}',
      'Sebep: ${visit.reason}',
      'Tarih: ${formatDate(visit.visitDate)}',
      if (visit.vetName != null && visit.vetName!.isNotEmpty)
        'Veteriner: ${visit.vetName!}',
      if (visit.clinicPhone != null && visit.clinicPhone!.isNotEmpty)
        'Telefon: ${visit.clinicPhone!}',
      if (visit.clinicAddress != null && visit.clinicAddress!.isNotEmpty)
        'Adres: ${visit.clinicAddress!}',
      if (visit.notes != null && visit.notes!.isNotEmpty)
        'Not: ${visit.notes!}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: details));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veteriner bilgileri kopyalandı.')),
    );
  }

  Future<void> _shareVisitCalendarInvite(VetVisit visit) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${visit.id}_veteriner_ziyareti.ics');
    final start = visit.visitDate;
    final end = start.add(const Duration(hours: 1));
    final content = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Pet Tracker//Vet Visit//TR',
      'BEGIN:VEVENT',
      'UID:${visit.id}@pettracker',
      'DTSTAMP:${_icsDate(DateTime.now().toUtc())}',
      'DTSTART:${_icsDate(start.toUtc())}',
      'DTEND:${_icsDate(end.toUtc())}',
      'SUMMARY:${_escapeIcsText("${_pet.name} - ${visit.reason}")}',
      'DESCRIPTION:${_escapeIcsText(_visitCalendarDescription(visit))}',
      if (visit.clinicAddress != null && visit.clinicAddress!.isNotEmpty)
        'LOCATION:${_escapeIcsText(visit.clinicAddress!)}',
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ].join('\r\n');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${_pet.name} veteriner ziyareti',
      text: '${_pet.name} için takvim daveti hazırlandı.',
      sharePositionOrigin: _shareOrigin,
    );
  }

  String _visitCalendarDescription(VetVisit visit) {
    return [
      'Kategori: ${visitCategoryLabel(visit.category)}',
      if (visit.vetName != null && visit.vetName!.isNotEmpty)
        'Veteriner: ${visit.vetName!}',
      if (visit.clinicPhone != null && visit.clinicPhone!.isNotEmpty)
        'Telefon: ${visit.clinicPhone!}',
      if (visit.notes != null && visit.notes!.isNotEmpty)
        'Not: ${visit.notes!}',
    ].join('\n');
  }

  String _icsDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$year$month${day}T$hour$minute${second}Z';
  }

  String _escapeIcsText(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }

  Rect? get _shareOrigin {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  Future<_ShareSummaryData> _buildShareSummaryData() async {
    final vaccines = await widget.vaccineRepository.getByPetId(_pet.id);
    final meds = await widget.medicationRepository.getByPetId(_pet.id);
    final activeCare = await widget.careRepository.getByPetId(_pet.id);
    final latestWeight = await widget.weightRepository.getLatest(_pet.id);
    final recentVisits = await widget.vetVisitRepository.getByPetId(_pet.id);

    final overdueVaccines = vaccines.where((v) => v.isOverdue).length;
    final activeMedications = meds.where((m) => m.isActive && m.isOngoing).length;
    final careCount = activeCare.where((task) => task.isActive).length;
    final latestVisit = recentVisits.isEmpty ? null : recentVisits.first;
    final visitSummary = latestVisit == null
        ? 'Son veteriner ziyareti yok'
        : 'Son ziyaret: ${latestVisit.reason} (${formatDate(latestVisit.visitDate)})';

    final summary = '''
${_pet.name} için sağlık özeti
Tür: ${_pet.species} · Irk: ${_pet.breed}
Doğum tarihi: ${formatDate(_pet.birthDate)}

Son kilo: ${latestWeight == null ? 'Kayıt yok' : '${latestWeight.weightKg.toStringAsFixed(1)} kg'}
Geciken aşı: $overdueVaccines
Aktif ilaç: $activeMedications
Aktif bakım rutini: $careCount
$visitSummary
''';
    return _ShareSummaryData(
      summaryText: summary,
      overdueVaccines: overdueVaccines,
      activeMedications: activeMedications,
      activeCareCount: careCount,
      latestWeightLabel:
          latestWeight == null ? 'Kayıt yok' : '${latestWeight.weightKg.toStringAsFixed(1)} kg',
      latestVisit: latestVisit,
      nextVaccines: vaccines.where((v) => v.nextDueDate != null).take(3).toList(),
      activeMedicationList: meds.where((m) => m.isActive && m.isOngoing).take(3).toList(),
    );
  }

  Future<void> _shareSummaryPdf(_ShareSummaryData data, Rect? shareOrigin) async {
    final regularFontData =
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final document = pw.Document();
    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);
    final primary = _pdfColor(_primaryColor);
    final secondary = _pdfColor(_secondaryColor);

    document.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [primary, secondary],
                  ),
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 54,
                      height: 54,
                      decoration: pw.BoxDecoration(
                        color: pdf.PdfColor(1, 1, 1, 0.18),
                        borderRadius: pw.BorderRadius.circular(16),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        _pet.name.isEmpty ? '?' : _pet.name.substring(0, 1).toUpperCase(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 22,
                          color: pdf.PdfColors.white,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${_pet.name} Sağlık Raporu',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 24,
                              color: pdf.PdfColors.white,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            '${_pet.species} · ${_pet.breed} · $_ageInYears yaş',
                            style: pw.TextStyle(
                              font: regularFont,
                              fontSize: 12,
                              color: pdf.PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),
              pw.Row(
                children: [
                  _pdfMetricCard('Son Kilo', data.latestWeightLabel, boldFont, regularFont),
                  pw.SizedBox(width: 10),
                  _pdfMetricCard('Geciken Aşı', '${data.overdueVaccines}', boldFont, regularFont),
                  pw.SizedBox(width: 10),
                  _pdfMetricCard('Aktif İlaç', '${data.activeMedications}', boldFont, regularFont),
                  pw.SizedBox(width: 10),
                  _pdfMetricCard('Bakım', '${data.activeCareCount}', boldFont, regularFont),
                ],
              ),
              pw.SizedBox(height: 18),
              _pdfSection(
                title: 'Genel Bilgiler',
                boldFont: boldFont,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _pdfLine('Doğum Tarihi', formatDate(_pet.birthDate), regularFont),
                    _pdfLine('Tür / Irk', '${_pet.species} / ${_pet.breed}', regularFont),
                    _pdfLine('Oluşturulma', formatDate(DateTime.now()), regularFont),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              _pdfSection(
                title: 'Veteriner İletişimi',
                boldFont: boldFont,
                child: data.latestVisit == null
                    ? pw.Text('Kayıtlı veteriner ziyareti bulunmuyor.',
                        style: pw.TextStyle(font: regularFont, fontSize: 11))
                    : pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfLine('Son Ziyaret', data.latestVisit!.reason, regularFont),
                          _pdfLine('Tarih', formatDate(data.latestVisit!.visitDate), regularFont),
                          _pdfLine(
                              'Veteriner', data.latestVisit!.vetName ?? 'Belirtilmedi', regularFont),
                          _pdfLine(
                              'Telefon', data.latestVisit!.clinicPhone ?? 'Belirtilmedi', regularFont),
                          _pdfLine(
                              'Adres', data.latestVisit!.clinicAddress ?? 'Belirtilmedi', regularFont),
                        ],
                      ),
              ),
              pw.SizedBox(height: 14),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _pdfSection(
                      title: 'Yaklaşan Aşılar',
                      boldFont: boldFont,
                      child: data.nextVaccines.isEmpty
                          ? pw.Text('Yaklaşan aşı kaydı yok.',
                              style: pw.TextStyle(font: regularFont, fontSize: 11))
                          : pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: data.nextVaccines
                                  .map(
                                    (v) => pw.Padding(
                                      padding: const pw.EdgeInsets.only(bottom: 6),
                                      child: pw.Text(
                                        '• ${v.name} · ${v.nextDueDate == null ? '-' : formatDate(v.nextDueDate!)}',
                                        style:
                                            pw.TextStyle(font: regularFont, fontSize: 11),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _pdfSection(
                      title: 'Aktif İlaçlar',
                      boldFont: boldFont,
                      child: data.activeMedicationList.isEmpty
                          ? pw.Text('Aktif ilaç bulunmuyor.',
                              style: pw.TextStyle(font: regularFont, fontSize: 11))
                          : pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: data.activeMedicationList
                                  .map(
                                    (m) => pw.Padding(
                                      padding: const pw.EdgeInsets.only(bottom: 6),
                                      child: pw.Text(
                                        '• ${m.name} · ${m.dosage} · ${m.frequency}',
                                        style:
                                            pw.TextStyle(font: regularFont, fontSize: 11),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${_pet.name}_saglik_ozeti.pdf');
    await file.writeAsBytes(await document.save());
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${_pet.name} sağlık özeti PDF',
      text: '${_pet.name} için hazırlanan sağlık özeti PDF dosyası.',
      sharePositionOrigin: shareOrigin,
    );
  }

  pdf.PdfColor _pdfColor(Color color) => pdf.PdfColor.fromInt(color.toARGB32());

  pw.Widget _pdfMetricCard(
    String title,
    String value,
    pw.Font boldFont,
    pw.Font regularFont,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: pdf.PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(14),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(font: regularFont, fontSize: 9)),
            pw.SizedBox(height: 6),
            pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfSection({
    required String title,
    required pw.Font boldFont,
    required pw.Widget child,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: pdf.PdfColors.blueGrey100),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 13)),
          pw.SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  pw.Widget _pdfLine(String label, String value, pw.Font regularFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          text: '$label: ',
          style: pw.TextStyle(font: regularFont, fontSize: 11),
          children: [
            pw.TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: 20),
                  _buildLaunchToolsSection(),
                  const SizedBox(height: 20),
                  _buildSmartSummarySection(),
                  const SizedBox(height: 20),
                  _buildVisitsSection(),
                  const SizedBox(height: 20),
                  _buildVaccinesSection(),
                  const SizedBox(height: 20),
                  _buildWeightSection(),
                  const SizedBox(height: 20),
                  _buildMedicationsSection(),
                  const SizedBox(height: 20),
                  _buildCareSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color get _primaryColor => petThemePrimary(_pet.themeColor);
  Color get _secondaryColor => petThemeSecondary(_pet.themeColor);
  IconData get _themeIcon => petThemeIcon(_pet.themeIcon);

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _editPet,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('Düzenle',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: _shareSummary,
          child: Container(
            margin: const EdgeInsets.all(8),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.ios_share, color: Colors.white, size: 18),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_pet.photoUrl != null)
              Image.file(File(_pet.photoUrl!), fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(_themeIcon, size: 80, color: Colors.white24),
              ),
            // bottom fade
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(blurRadius: 8, color: Colors.black26),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _headerChip(_pet.species),
                      const SizedBox(width: 6),
                      _headerChip(_pet.breed),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bilgiler',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 16),
          _infoRow(Icons.cake_outlined, 'Doğum Tarihi',
              formatDate(_pet.birthDate)),
          const Divider(height: 20),
          _infoRow(Icons.access_time_outlined, 'Yaş', '$_ageInYears yaş'),
          const Divider(height: 20),
          _infoRow(Icons.category_outlined, 'Tür', _pet.species),
          const Divider(height: 20),
          _infoRow(Icons.style_outlined, 'Irk', _pet.breed),
        ],
      ),
    );
  }

  Widget _buildLaunchToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Akıllı Araçlar',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _toolCard(
              icon: Icons.document_scanner_outlined,
              title: 'Belgeler',
              subtitle: 'Karne, tahlil, pasaport',
              color: const Color(0xFF6C63FF),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DocumentGalleryPage(
                    petId: _pet.id,
                    petName: _pet.name,
                    repository: widget.documentRepository,
                  ),
                ),
              ),
            ),
            _toolCard(
              icon: Icons.flight_takeoff_outlined,
              title: 'Pati Pasaportu',
              subtitle: 'Seyahat kontrol listesi',
              color: const Color(0xFF3D8BFF),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TravelModePage(
                    petId: _pet.id,
                    petName: _pet.name,
                    vaccineRepository: widget.vaccineRepository,
                    documentRepository: widget.documentRepository,
                  ),
                ),
              ),
            ),
            _toolCard(
              icon: Icons.health_and_safety_outlined,
              title: 'Semptom Günlüğü',
              subtitle: 'Veteriner öncesi hazırlık',
              color: const Color(0xFFFF7A59),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SymptomPage(
                    petId: _pet.id,
                    petName: _pet.name,
                    repository: widget.symptomRepository,
                  ),
                ),
              ),
            ),
            _toolCard(
              icon: Icons.group_outlined,
              title: 'Bakıcı Erişimi',
              subtitle: 'Kod paylaş, işlem kaydet',
              color: const Color(0xFF2EC4B6),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CaregiverPage(
                    petId: _pet.id,
                    petName: _pet.name,
                    repository: widget.caregiverRepository,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _toolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmartSummarySection() {
    return FutureBuilder<List<Object?>>(
      future: Future.wait([
        widget.weightRepository.getByPetId(_pet.id),
        widget.medicationRepository.getByPetId(_pet.id),
        widget.careRepository.getByPetId(_pet.id),
      ]),
      builder: (context, snapshot) {
        final weights = (snapshot.data?[0] as List?)?.cast<dynamic>() ?? [];
        final meds = (snapshot.data?[1] as List?)?.cast<Medication>() ?? [];
        final careTasks = (snapshot.data?[2] as List?)?.cast<CareTask>() ?? [];
        String weightSummary = 'Son 30 günde kilo verisi yetersiz';
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        final monthWeights =
            weights.where((r) => r.recordedAt.isAfter(monthAgo)).toList();
        if (monthWeights.length >= 2) {
          final delta = monthWeights.last.weightKg - monthWeights.first.weightKg;
          weightSummary = '30 gün kilo trendi: ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg';
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Akıllı Özet',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 14),
              _summaryTile(Icons.monitor_weight_outlined, weightSummary),
              const SizedBox(height: 10),
              _summaryTile(
                Icons.medication_outlined,
                'Atlanan doz: ${meds.where((m) => m.isActive).isEmpty ? 'Veri yok' : 'İlaç ekranındaki loglardan takip ediliyor'}',
              ),
              const SizedBox(height: 10),
              _summaryTile(
                Icons.spa_outlined,
                'Aktif bakım rutini: ${careTasks.where((task) => task.isActive).length}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildVaccinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Aşı Takibi',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => VaccineListPage(
                  petId: _pet.id,
                  petName: _pet.name,
                  repository: widget.vaccineRepository,
                ),
              )),
              child: const Text('Tümünü Gör',
                  style: TextStyle(
                      color: Color(0xFF2EC4B6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Vaccine>>(
          future: widget.vaccineRepository.getByPetId(_pet.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final vaccines = snapshot.data ?? [];
            if (vaccines.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vaccines_outlined,
                        color: Color(0xFF2EC4B6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Henüz aşı kaydedilmedi. İlk dozu ekleyip hatırlatma kur.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: vaccines.take(3).map((v) {
                final isOverdue = v.isOverdue;
                final days = v.daysUntilDue;
                final statusColor = v.nextDueDate == null
                    ? Colors.grey
                    : isOverdue
                        ? Colors.red
                        : v.isDueToday
                            ? Colors.deepOrange
                            : v.isUpcoming
                            ? Colors.orange
                            : const Color(0xFF2EC4B6);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
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
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.vaccines_outlined,
                            color: statusColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 2),
                            Text(
                              v.nextDueDate == null
                                  ? 'Uygulandi: ${formatDate(v.administeredDate)}'
                                  : isOverdue
                                      ? 'Sonraki doz gecikti'
                                      : v.isDueToday
                                          ? 'Bugün uygulanacak'
                                          : 'Sonraki: ${formatDate(v.nextDueDate!)} · $days gün',
                              style: TextStyle(
                                  color: statusColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMedicationsSection() {
    return FutureBuilder<List<Medication>>(
      future: widget.medicationRepository.getActive(_pet.id),
      builder: (context, snapshot) {
        final meds = snapshot.data ?? [];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => MedicationListPage(
              petId: _pet.id,
              petName: _pet.name,
              repository: widget.medicationRepository,
            ),
          )),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.medication_outlined,
                              color: Color(0xFFFF6B6B), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text('İlaç Takibi',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFFD0D0D0), size: 20),
                  ],
                ),
                if (meds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...meds.take(2).map((m) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B6B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${m.name}  ·  ${m.dosage}  ·  ${m.frequency}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Aktif ilaç yok.',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12)),
                  ),
                if (meds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Saatli ilaç planı ekleyerek günlük takibi başlat.',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 12)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCareSection() {
    return FutureBuilder<List<CareTask>>(
      future: widget.careRepository.getByPetId(_pet.id),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CarePage(
              petId: _pet.id,
              petName: _pet.name,
              repository: widget.careRepository,
            ),
          )),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.spa_outlined,
                          color: Color(0xFF2EC4B6), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text('Bakım Rutinleri',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Color(0xFFD0D0D0), size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  Text('Henüz bakım rutini yok. Mama, su veya banyo planı ekleyebilirsin.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
                else
                  ...tasks.take(3).map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '• ${task.title} · ${careFrequencyLabel(task.frequency)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryTile(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2EC4B6)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
          ),
        ],
      );

  Widget _buildWeightSection() {
    return FutureBuilder(
      future: widget.weightRepository.getLatest(_pet.id),
      builder: (context, snapshot) {
        final latest = snapshot.data;
        return GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WeightPage(
              petId: _pet.id,
              petName: _pet.name,
              repository: widget.weightRepository,
            ),
          )),
          child: Container(
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
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.monitor_weight_outlined,
                      color: Color(0xFF6C63FF), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kilo Takibi',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text(
                        latest == null
                            ? 'Henüz kayıt yok'
                            : 'Son: ${latest.weightKg.toStringAsFixed(1)} kg  ·  ${formatDate(latest.recordedAt)}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
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
      },
    );
  }

  Widget _buildVisitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Veteriner Ziyaretleri',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => VetVisitListPage(
                  petId: _pet.id,
                  petName: _pet.name,
                  repository: widget.vetVisitRepository,
                ),
              )),
              child: const Text('Tümünü Gör',
                  style: TextStyle(
                      color: Color(0xFF2EC4B6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<VetVisit>>(
          future: widget.vetVisitRepository.getByPetId(_pet.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final visits = snapshot.data ?? [];
            if (visits.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        color: Color(0xFF2EC4B6)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Henüz ziyaret kaydedilmedi. Kontrol veya aşı planlayabilirsin.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: visits
                  .take(3)
                  .map((v) => _VisitTile(
                        visit: v,
                        onCopy: () => _copyVisitDetails(v),
                        onCalendar: () => _shareVisitCalendarInvite(v),
                        onCall: v.clinicPhone == null
                            ? null
                            : () => _launchPhone(v.clinicPhone!),
                        onMap: v.clinicAddress == null
                            ? null
                            : () => _launchDirections(v.clinicAddress!),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _VisitTile extends StatelessWidget {
  final VetVisit visit;
  final VoidCallback? onCopy;
  final VoidCallback? onCalendar;
  final VoidCallback? onCall;
  final VoidCallback? onMap;

  const _VisitTile({
    required this.visit,
    this.onCopy,
    this.onCalendar,
    this.onCall,
    this.onMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
              color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medical_services_outlined,
                color: Color(0xFF2EC4B6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visit.reason,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text(
                  [
                    visitCategoryLabel(visit.category),
                    formatDate(visit.visitDate),
                    if (visit.vetName != null) visit.vetName!,
                    if (visit.clinicPhone != null) visit.clinicPhone!,
                  ].join(' · '),
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12),
                ),
                if (onCopy != null ||
                    onCalendar != null ||
                    onCall != null ||
                    onMap != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      if (onCopy != null)
                        TextButton.icon(
                          onPressed: onCopy,
                          icon: const Icon(Icons.copy_all_outlined, size: 16),
                          label: Text('Kopyala'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.onSurface,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (onCalendar != null)
                        TextButton.icon(
                          onPressed: onCalendar,
                          icon:
                              const Icon(Icons.event_available_outlined, size: 16),
                          label: const Text('Takvime Ekle'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF7A59),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (onCall != null)
                        TextButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Icons.call_outlined, size: 16),
                          label: const Text('Ara'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2EC4B6),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      if (onMap != null)
                        TextButton.icon(
                          onPressed: onMap,
                          icon: const Icon(Icons.directions_outlined, size: 16),
                          label: const Text('Yol Tarifi Al'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3D8BFF),
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareSummaryData {
  final String summaryText;
  final int overdueVaccines;
  final int activeMedications;
  final int activeCareCount;
  final String latestWeightLabel;
  final VetVisit? latestVisit;
  final List<Vaccine> nextVaccines;
  final List<Medication> activeMedicationList;

  const _ShareSummaryData({
    required this.summaryText,
    required this.overdueVaccines,
    required this.activeMedications,
    required this.activeCareCount,
    required this.latestWeightLabel,
    required this.latestVisit,
    required this.nextVaccines,
    required this.activeMedicationList,
  });
}
