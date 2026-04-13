import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/app_utils.dart';
import 'vet_visit_model.dart';
import 'vet_visit_repository.dart';
import 'vet_visit_form_page.dart';

class VetVisitListPage extends StatefulWidget {
  final String petId;
  final String petName;
  final VetVisitRepository repository;

  const VetVisitListPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.repository,
  });

  @override
  State<VetVisitListPage> createState() => _VetVisitListPageState();
}

class _VetVisitListPageState extends State<VetVisitListPage> {
  late Future<List<VetVisit>> _visitsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _showActions(VetVisit visit) async {
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
                _openForm(existing: visit);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _delete(visit);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _reload() {
    _visitsFuture = widget.repository.getByPetId(widget.petId);
  }

  Future<void> _openForm({VetVisit? existing}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => VetVisitFormPage(
        repository: widget.repository,
        petId: widget.petId,
        petName: widget.petName,
        existing: existing,
      ),
    ));
    setState(_reload);
  }

  void _delete(VetVisit v) {
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
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.delete_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('"${v.reason}" silinsin mi?',
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
      body: FutureBuilder<List<VetVisit>>(
        future: _visitsFuture,
        builder: (context, snapshot) {
          final visits = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              _buildHeader(visits.length),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (visits.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _VisitCard(
                        visit: visits[i],
                        onTap: () => _showDetail(visits[i]),
                        onOpenActions: () => _showActions(visits[i]),
                      ),
                      childCount: visits.length,
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
        label: const Text('Yeni Ziyaret',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3D8BFF), Color(0xFF2EC4B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, MediaQuery.of(context).padding.top + 16, 24, 28),
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
            const Text('Veteriner Ziyaretleri',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              count == 0 ? 'Henüz ziyaret eklenmedi' : '$count ziyaret kayıtlı',
              style:
                  const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_outlined,
                size: 48, color: Color(0xFF2EC4B6)),
          ),
          const SizedBox(height: 20),
          const Text('Henüz ziyaret eklenmedi',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Text('Kontrol, aşı veya hastalık ziyaretlerini\ntarih ve hatırlatmalarla burada yönet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, height: 1.5)),
        ],
      ),
    );
  }

  void _showDetail(VetVisit v) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(v.reason,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _detailRow(Icons.category_outlined, visitCategoryLabel(v.category)),
            _detailRow(Icons.calendar_today_outlined,
                formatDate(v.visitDate)),
            if (v.vetName != null)
              _detailRow(Icons.person_outline, v.vetName!),
            if (v.clinicPhone != null)
              _detailRow(Icons.phone_outlined, v.clinicPhone!),
            if (v.clinicAddress != null)
              _detailRow(Icons.location_on_outlined, v.clinicAddress!),
            if (v.reminderEnabled && v.reminderTime != null)
              _detailRow(
                Icons.notifications_outlined,
                '${v.reminderTime} · ${v.reminderDaysBefore} gün önce',
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copyVisitDetails(v),
                  icon: const Icon(Icons.copy_all_outlined),
                  label: const Text('Kopyala'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _shareCalendarInvite(v),
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Takvime Ekle'),
                ),
                if (v.clinicPhone != null)
                  ElevatedButton.icon(
                    onPressed: () => _launchPhone(v.clinicPhone!),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Ara'),
                  ),
                if (v.clinicAddress != null)
                  OutlinedButton.icon(
                    onPressed: () => _launchDirections(v.clinicAddress!),
                    icon: const Icon(Icons.directions_outlined),
                    label: const Text('Yol Tarifi Al'),
                  ),
              ],
            ),
            if (v.notes != null && v.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notlar',
                  style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(v.notes!,
                  style: const TextStyle(fontSize: 15, height: 1.5)),
            ],
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

  Rect? get _shareOrigin {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final origin = renderObject.localToGlobal(Offset.zero);
    return origin & renderObject.size;
  }

  Future<void> _copyVisitDetails(VetVisit visit) async {
    final details = <String>[
      '${widget.petName} - Veteriner Ziyareti',
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

  Future<void> _shareCalendarInvite(VetVisit visit) async {
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
      'SUMMARY:${_escapeIcsText("${widget.petName} - ${visit.reason}")}',
      'DESCRIPTION:${_escapeIcsText(_calendarDescription(visit))}',
      if (visit.clinicAddress != null && visit.clinicAddress!.isNotEmpty)
        'LOCATION:${_escapeIcsText(visit.clinicAddress!)}',
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ].join('\r\n');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '${widget.petName} veteriner ziyareti',
      text: '${widget.petName} için takvim daveti hazırlandı.',
      sharePositionOrigin: _shareOrigin,
    );
  }

  String _calendarDescription(VetVisit visit) {
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

  Widget _detailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2EC4B6)),
            const SizedBox(width: 10),
            Text(text,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
          ],
        ),
      );
}

class _VisitCard extends StatelessWidget {
  final VetVisit visit;
  final VoidCallback onTap;
  final VoidCallback onOpenActions;

  const _VisitCard({
    required this.visit,
    required this.onTap,
    required this.onOpenActions,
  });

  @override
  Widget build(BuildContext context) {
    final color = visitCategoryColor(visit.category);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.medical_services_outlined,
                      color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(visit.reason,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface)),
                      const SizedBox(height: 4),
                      Text(
                        [
                          visitCategoryLabel(visit.category),
                          formatDate(visit.visitDate),
                          if (visit.vetName != null) visit.vetName!,
                        ].join(' · '),
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
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
      ),
    );
  }
}
