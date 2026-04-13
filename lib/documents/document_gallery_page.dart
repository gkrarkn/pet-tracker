import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../shared/app_utils.dart';
import 'document_model.dart';
import 'document_repository.dart';

class DocumentGalleryPage extends StatefulWidget {
  final String petId;
  final String petName;
  final DocumentRepository repository;

  const DocumentGalleryPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.repository,
  });

  @override
  State<DocumentGalleryPage> createState() => _DocumentGalleryPageState();
}

class _DocumentGalleryPageState extends State<DocumentGalleryPage> {
  late Future<List<PetDocument>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.repository.getByPetId(widget.petId);
  }

  Future<String> _saveToAppDir(String sourcePath, String ext) async {
    final dir = await getApplicationDocumentsDirectory();
    final dest =
        '${dir.path}/docs_${widget.petId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<void> _addDocument() async {
    final result = await showModalBottomSheet<String>(
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
            const Text('Belge Ekle',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFF2EC4B6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF2EC4B6)),
              ),
              title: const Text('Fotoğraf çek'),
              subtitle: const Text('Belgeyi kamerayla fotoğrafla'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFF3D8BFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF3D8BFF)),
              ),
              title: const Text('Galeriden seç'),
              subtitle: const Text('Var olan fotoğrafı ekle'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.picture_as_pdf_outlined,
                    color: Color(0xFFFF6B6B)),
              ),
              title: const Text('PDF dosyası'),
              subtitle: const Text('Dosyalardan PDF seç'),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;

    String? filePath;
    String fileType = 'image';

    try {
      if (result == 'camera') {
        final picked = await ImagePicker()
            .pickImage(source: ImageSource.camera, imageQuality: 85);
        if (picked == null) return;
        filePath = await _saveToAppDir(picked.path, 'jpg');
      } else if (result == 'gallery') {
        final picked = await ImagePicker()
            .pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked == null) return;
        filePath = await _saveToAppDir(picked.path, 'jpg');
      } else if (result == 'pdf') {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (res == null || res.files.single.path == null) return;
        filePath = await _saveToAppDir(res.files.single.path!, 'pdf');
        fileType = 'pdf';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya eklenemedi: $e')),
        );
      }
      return;
    }

    if (filePath == null) return;

    if (!mounted) return;
    final title = await _askTitle(fileType);
    if (title == null) return;

    await widget.repository.add(PetDocument(
      id: const Uuid().v4(),
      petId: widget.petId,
      title: title,
      filePath: filePath,
      fileType: fileType,
      createdAt: DateTime.now(),
    ));
    setState(_reload);
  }

  Future<String?> _askTitle(String fileType) async {
    final ctrl = TextEditingController(
        text: fileType == 'pdf' ? 'Belge' : 'Fotoğraf');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Belge Adı'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ör. Aşı Kartı'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty
                  ? (fileType == 'pdf' ? 'Belge' : 'Fotoğraf')
                  : ctrl.text.trim()),
              child: const Text('Kaydet')),
        ],
      ),
    );
  }

  void _deleteDocument(PetDocument doc) {
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
            Text('"${doc.title}" silinsin mi?',
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
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await widget.repository.delete(doc.id);
                      try {
                        await File(doc.filePath).delete();
                      } catch (_) {}
                      if (ctx.mounted) Navigator.pop(ctx);
                      setState(_reload);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  Future<void> _viewDocument(PetDocument doc) async {
    if (doc.isImage) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _ImageViewPage(doc: doc),
      ));
    } else if (doc.isPdf) {
      final uri = Uri.file(doc.filePath);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication)
          .catchError((_) => false);
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF açılamadı.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<PetDocument>>(
        future: _future,
        builder: (context, snapshot) {
          final docs = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              _buildHeader(docs.length),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (docs.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _DocCard(
                        doc: docs[i],
                        onTap: () => _viewDocument(docs[i]),
                        onDelete: () => _deleteDocument(docs[i]),
                      ),
                      childCount: docs.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDocument,
        icon: const Icon(Icons.add),
        label: const Text('Belge Ekle',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3D8BFF)],
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
            const Text('Belgeler & Fotoğraflar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              count == 0 ? 'Henüz belge eklenmedi' : '$count belge',
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
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_outlined,
                  size: 48, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 20),
            const Text('Henüz belge eklenmedi',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                'Aşı kartı, pasaport veya\ndiğer sağlık belgelerini buraya ekle.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
          ],
        ),
      );
}

class _DocCard extends StatelessWidget {
  final PetDocument doc;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DocCard(
      {required this.doc, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: doc.isImage
                    ? Image.file(
                        File(doc.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _pdfPlaceholder(context),
                      )
                    : _pdfPlaceholder(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(formatDate(doc.createdAt),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.more_vert,
                          size: 16, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfPlaceholder(BuildContext context) => Container(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.08),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_outlined,
                color: Color(0xFFFF6B6B), size: 48),
            SizedBox(height: 8),
            Text('PDF',
                style: TextStyle(
                    color: Color(0xFFFF6B6B), fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _ImageViewPage extends StatelessWidget {
  final PetDocument doc;
  const _ImageViewPage({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(doc.title,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat',
                style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
      body: InteractiveViewer(
        child: Center(
          child: Image.file(
            File(doc.filePath),
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 80,
            ),
          ),
        ),
      ),
    );
  }
}
