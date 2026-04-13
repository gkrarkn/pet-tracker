import 'package:flutter/material.dart';
import '../documents/document_model.dart';
import '../documents/document_repository.dart';
import '../shared/app_utils.dart';
import '../vaccine/vaccine_model.dart';
import '../vaccine/vaccine_repository.dart';

class TravelModePage extends StatefulWidget {
  final String petId;
  final String petName;
  final VaccineRepository vaccineRepository;
  final DocumentRepository documentRepository;

  const TravelModePage({
    super.key,
    required this.petId,
    required this.petName,
    required this.vaccineRepository,
    required this.documentRepository,
  });

  @override
  State<TravelModePage> createState() => _TravelModePageState();
}

class _TravelModePageState extends State<TravelModePage> {
  static const _destinations = [
    'Yunanistan',
    'Almanya',
    'İngiltere',
    'ABD',
    'Kanada',
    'Fransa',
    'Hollanda',
    'İtalya',
    'İspanya',
    'THY ile Uçuş',
    'Pegasus ile Uçuş',
    'AJet ile Uçuş',
    'Lufthansa ile Uçuş',
  ];

  String _selectedDestination = _destinations.first;

  _TravelInfoNote _buildInfoNote() {
    switch (_selectedDestination) {
      case 'Yunanistan':
      case 'Almanya':
      case 'Fransa':
      case 'Hollanda':
      case 'İtalya':
      case 'İspanya':
        return const _TravelInfoNote(
          title: 'AB içinde seyahat',
          body:
              'AB ülkelerinde pet pasaportu, kuduz aşı kaydı ve mikroçip bilgisi en kritik kalemlerdir.',
        );
      case 'İngiltere':
        return const _TravelInfoNote(
          title: 'Belge kontrolü sıkı olabilir',
          body:
              'İngiltere rotasında kuduz, mikroçip ve resmi evrakları birlikte hazır tutmak güvenli olur.',
        );
      case 'ABD':
      case 'Kanada':
        return const _TravelInfoNote(
          title: 'Giriş kuralları rota bazlı değişebilir',
          body:
              'Kuzey Amerika rotalarında havayolu ve eyalet/ülke kuralları farklılaşabilir; sağlık sertifikası önemli olabilir.',
        );
      case 'THY ile Uçuş':
      case 'Pegasus ile Uçuş':
      case 'AJet ile Uçuş':
      case 'Lufthansa ile Uçuş':
        return const _TravelInfoNote(
          title: 'Hava yolu evrak kontrolü',
          body:
              'Uçuş öncesi aşı özeti, sağlık sertifikası ve gerekiyorsa pasaport belgesini tek yerde hazır tutman check-in sürecini hızlandırır.',
        );
      default:
        return const _TravelInfoNote(
          title: 'Mikroçip önemli',
          body:
              'Seyahat modunda en çok kontrol edilen alanlar kuduz kaydı, mikroçip ve resmi belgelerdir.',
        );
    }
  }

  bool _hasNamedItem(Iterable<String> values, List<String> keywords) {
    return values.any((value) {
      final lower = value.toLowerCase();
      return keywords.any(lower.contains);
    });
  }

  List<_TravelCheckItem> _buildChecklist(
    List<Vaccine> vaccines,
    List<PetDocument> documents,
  ) {
    final vaccineNames = vaccines.map((v) => v.name.toLowerCase()).toList();
    final docNames = documents
        .expand((doc) => [doc.title, if (doc.description != null) doc.description!])
        .map((value) => value.toLowerCase())
        .toList();

    final rabiesVaccine = vaccines.where((v) {
      final lower = v.name.toLowerCase();
      return lower.contains('kuduz') || lower.contains('rabies');
    }).toList()
      ..sort((a, b) => b.administeredDate.compareTo(a.administeredDate));

    final latestRabies = rabiesVaccine.isEmpty ? null : rabiesVaccine.first;
    final rabiesValid = latestRabies != null &&
        DateTime.now().difference(latestRabies.administeredDate).inDays <= 365;

    final hasPassport =
        _hasNamedItem(docNames, ['pasaport', 'passport', 'pet passport']);
    final hasChip =
        _hasNamedItem(docNames, ['microchip', 'mikroçip', 'mikrocip', 'chip']);
    final hasTiter =
        _hasNamedItem(docNames, ['titrasyon', 'titer', 'titre']);
    final hasHealthCertificate = _hasNamedItem(
      docNames,
      ['sağlık sertifikası', 'saglik sertifikasi', 'health certificate'],
    );
    final hasParasiteProof = _hasNamedItem(
      vaccineNames.followedBy(docNames),
      ['parazit', 'iç / dış parazit', 'ic / dis parazit'],
    );

    switch (_selectedDestination) {
      case 'Yunanistan':
        return [
          _TravelCheckItem(
            title: 'Kuduz aşısı güncel olmalı',
            subtitle: rabiesValid
                ? 'Kayıt bulundu: ${formatDate(latestRabies.administeredDate)}'
                : 'Bu rota için kuduz aşısını yenilemen gerekebilir.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Pet pasaportu / AB evcil hayvan belgesi',
            subtitle: hasPassport
                ? 'Belge arşivinde pasaport kaydı bulundu.'
                : 'Seyahatten önce pasaport belgesini eklemen iyi olur.',
            isDone: hasPassport,
          ),
          _TravelCheckItem(
            title: 'Mikroçip kaydı',
            subtitle: hasChip
                ? 'Mikroçip kaydı mevcut görünüyor.'
                : 'Mikroçip belgesi veya notunu eklemelisin.',
            isDone: hasChip,
          ),
          _TravelCheckItem(
            title: 'Titrasyon testi gerekiyorsa hazır olsun',
            subtitle: hasTiter
                ? 'Belge arşivinde titrasyon sonucu bulundu.'
                : 'Bazı seyahat senaryolarında titrasyon sonucu istenebilir.',
            isDone: hasTiter,
          ),
        ];
      case 'Almanya':
        return [
          _TravelCheckItem(
            title: 'Kuduz aşısı kontrolü',
            subtitle: rabiesValid
                ? 'Aşı tarihi uygun görünüyor.'
                : 'Kuduz kaydı güncel görünmüyor.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'AB pasaportu veya sağlık sertifikası',
            subtitle: (hasPassport || hasHealthCertificate)
                ? 'Gerekli evraklardan en az biri mevcut.'
                : 'Pasaport veya sağlık sertifikası eklenmeli.',
            isDone: hasPassport || hasHealthCertificate,
          ),
          _TravelCheckItem(
            title: 'Parazit uygulaması notu',
            subtitle: hasParasiteProof
                ? 'Parazit kaydı bulundu.'
                : 'Seyahat öncesi iç/dış parazit uygulamasını not etmek faydalı olur.',
            isDone: hasParasiteProof,
          ),
        ];
      case 'İngiltere':
        return [
          _TravelCheckItem(
            title: 'Kuduz aşısı güncel olmalı',
            subtitle: rabiesValid
                ? 'Kuduz kaydı uygun görünüyor.'
                : 'İngiltere için kuduz aşısı kritik kontrol kalemi.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Pet pasaportu veya sağlık sertifikası',
            subtitle: (hasPassport || hasHealthCertificate)
                ? 'Gerekli seyahat evrağı bulundu.'
                : 'İngiltere girişinde resmi belge göstermen gerekebilir.',
            isDone: hasPassport || hasHealthCertificate,
          ),
          _TravelCheckItem(
            title: 'Mikroçip kaydı',
            subtitle: hasChip
                ? 'Mikroçip kaydı hazır.'
                : 'İngiltere için mikroçip kaydı mutlaka görünür olmalı.',
            isDone: hasChip,
          ),
          _TravelCheckItem(
            title: 'Titrasyon / ek laboratuvar belgeleri',
            subtitle: hasTiter
                ? 'Arşivde titrasyon sonucu var.'
                : 'Rota ve kurala göre ek test sonucu istenebilir.',
            isDone: hasTiter,
          ),
        ];
      case 'ABD':
        return [
          _TravelCheckItem(
            title: 'Kuduz aşı kaydı',
            subtitle: rabiesValid
                ? 'Aşı tarihi yakın dönemde uygulanmış.'
                : 'Bazı eyaletler ve havayolları kuduz kaydını özellikle kontrol eder.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Sağlık sertifikası',
            subtitle: hasHealthCertificate
                ? 'Belge arşivinde sağlık sertifikası bulundu.'
                : 'Uçuş öncesi veterinerden sağlık sertifikası alman gerekebilir.',
            isDone: hasHealthCertificate,
          ),
          _TravelCheckItem(
            title: 'Taşıyıcı / havayolu belge kontrolü',
            subtitle: vaccines.isNotEmpty
                ? 'Aşı kaydı mevcut, paylaşım çıktısı kullanıma hazır.'
                : 'Aşı kayıtlarını eksiksiz tutmak check-in sürecini kolaylaştırır.',
            isDone: vaccines.isNotEmpty,
          ),
        ];
      case 'Fransa':
        return [
          _TravelCheckItem(
            title: 'AB seyahat belgesi',
            subtitle: hasPassport
                ? 'Pet pasaportu kaydı bulundu.'
                : 'Fransa için AB evcil hayvan pasaportu çok işini kolaylaştırır.',
            isDone: hasPassport,
          ),
          _TravelCheckItem(
            title: 'Kuduz aşı kontrolü',
            subtitle: rabiesValid
                ? 'Kuduz aşısı güncel görünüyor.'
                : 'Fransa yolculuğu öncesi kuduz aşı tarihini gözden geçir.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Mikroçip ve kimlik doğrulama',
            subtitle: hasChip
                ? 'Mikroçip bilgisi mevcut.'
                : 'Mikroçip kaydı eklemek iyi olur.',
            isDone: hasChip,
          ),
        ];
      case 'Kanada':
        return [
          _TravelCheckItem(
            title: 'Kuduz aşı kaydı',
            subtitle: rabiesValid
                ? 'Kanada için temel aşı kontrolü uygun.'
                : 'Kanada girişinde kuduz aşı belgesi kritik olabilir.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Sağlık sertifikası / veteriner onayı',
            subtitle: hasHealthCertificate
                ? 'Belge arşivinde sağlık sertifikası mevcut.'
                : 'Uçuştan önce veteriner sağlık raporu almak iyi olur.',
            isDone: hasHealthCertificate,
          ),
          _TravelCheckItem(
            title: 'Mikroçip ve kimlik bilgisi',
            subtitle: hasChip
                ? 'Kimlik doğrulama kaydı hazır.'
                : 'Mikroçip kaydı eklemek sınır geçişlerini kolaylaştırır.',
            isDone: hasChip,
          ),
        ];
      case 'Hollanda':
        return [
          _TravelCheckItem(
            title: 'AB evcil hayvan pasaportu',
            subtitle: hasPassport
                ? 'Pasaport kaydı bulundu.'
                : 'Hollanda için AB pet passport hazırlaman faydalı olur.',
            isDone: hasPassport,
          ),
          _TravelCheckItem(
            title: 'Kuduz aşısı güncelliği',
            subtitle: rabiesValid
                ? 'Kuduz aşı tarihi uygun.'
                : 'Hollanda için kuduz aşı tarihini yenilemek gerekebilir.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Parazit / genel sağlık takibi',
            subtitle: hasParasiteProof
                ? 'Parazit uygulama kaydı bulundu.'
                : 'İç/dış parazit uygulamasını belgelemek iyi olur.',
            isDone: hasParasiteProof,
          ),
        ];
      case 'İtalya':
        return [
          _TravelCheckItem(
            title: 'Pet pasaportu / AB belgesi',
            subtitle: hasPassport
                ? 'Pasaport kaydı mevcut.'
                : 'İtalya için pasaport veya eşdeğer belge hazırlaman iyi olur.',
            isDone: hasPassport,
          ),
          _TravelCheckItem(
            title: 'Kuduz aşısı',
            subtitle: rabiesValid
                ? 'Kuduz kaydı uygun.'
                : 'Seyahat öncesi kuduz aşı tarihini yenilemen gerekebilir.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Parazit uygulaması notu',
            subtitle: hasParasiteProof
                ? 'Parazit uygulama kaydı bulundu.'
                : 'İç/dış parazit uygulamasını belgelemek iyi bir hazırlık olur.',
            isDone: hasParasiteProof,
          ),
        ];
      case 'İspanya':
        return [
          _TravelCheckItem(
            title: 'AB pasaportu veya eşdeğer belge',
            subtitle: hasPassport
                ? 'Belge arşivinde pasaport mevcut.'
                : 'İspanya için AB evcil hayvan belgesi hazırlaman iyi olur.',
            isDone: hasPassport,
          ),
          _TravelCheckItem(
            title: 'Kuduz aşı kaydı',
            subtitle: rabiesValid
                ? 'Kuduz aşısı uygun görünüyor.'
                : 'İspanya için kuduz aşı belgesini güncel tutmalısın.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Mikroçip kaydı',
            subtitle: hasChip
                ? 'Mikroçip bilgisi hazır.'
                : 'Mikroçip kaydını eklemen önerilir.',
            isDone: hasChip,
          ),
        ];
      case 'THY ile Uçuş':
        return [
          _TravelCheckItem(
            title: 'Aşı kartı / sağlık özeti hazır mı?',
            subtitle: vaccines.isNotEmpty
                ? '${vaccines.length} aşı kaydı mevcut, PDF paylaşımı hazır.'
                : 'En azından temel aşı kayıtlarını girmen iyi olur.',
            isDone: vaccines.isNotEmpty,
          ),
          _TravelCheckItem(
            title: 'Kuduz kaydı',
            subtitle: rabiesValid
                ? 'Uçuş öncesi temel kontrol tamam.'
                : 'Kuduz aşısını teyit etmen gerekir.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Taşıma ve belge kontrol listesi',
            subtitle: hasHealthCertificate || hasPassport
                ? 'Belge arşivinde uçuşa yardımcı evrak var.'
                : 'Belge arşivine sağlık sertifikası veya pasaport ekleyebilirsin.',
            isDone: hasHealthCertificate || hasPassport,
          ),
        ];
      case 'Pegasus ile Uçuş':
        return [
          _TravelCheckItem(
            title: 'Taşıma öncesi aşı özeti hazır olsun',
            subtitle: vaccines.isNotEmpty
                ? 'Aşı kayıtların paylaşım için hazır.'
                : 'Pegasus öncesi aşı özetini uygulamada tamamlaman iyi olur.',
            isDone: vaccines.isNotEmpty,
          ),
          _TravelCheckItem(
            title: 'Kuduz kaydı',
            subtitle: rabiesValid
                ? 'Temel uçuş kontrolü tamam.'
                : 'Kuduz aşı belgesini doğrulaman gerekir.',
            isDone: rabiesValid,
          ),
          _TravelCheckItem(
            title: 'Sağlık sertifikası / veteriner notu',
            subtitle: hasHealthCertificate
                ? 'Veteriner belgesi bulundu.'
                : 'Havayolu talep ederse hızlı göstermek için sağlık sertifikası ekle.',
            isDone: hasHealthCertificate,
          ),
        ];
      case 'AJet ile Uçuş':
        return [
          _TravelCheckItem(
            title: 'Aşı kayıtları eksiksiz olmalı',
            subtitle: vaccines.isNotEmpty
                ? '${vaccines.length} aşı kaydı mevcut.'
                : 'Uçuş öncesi aşı kartını doldurman iyi olur.',
            isDone: vaccines.isNotEmpty,
          ),
          _TravelCheckItem(
            title: 'Kuduz ve sağlık belgesi',
            subtitle: rabiesValid && hasHealthCertificate
                ? 'Temel uçuş evrakları hazır.'
                : 'Kuduz kaydı ve sağlık sertifikasını birlikte hazırlamak iyi olur.',
            isDone: rabiesValid && hasHealthCertificate,
          ),
          _TravelCheckItem(
            title: 'Taşıma / check-in kontrolü',
            subtitle: hasPassport || hasHealthCertificate
                ? 'Belge arşivinde check-in sırasında işine yarayacak evrak var.'
                : 'Belge arşivine veteriner onayı ekleyebilirsin.',
            isDone: hasPassport || hasHealthCertificate,
          ),
        ];
      case 'Lufthansa ile Uçuş':
        return [
          _TravelCheckItem(
            title: 'Kuduz aşısı ve kimlik bilgisi',
            subtitle: rabiesValid && hasChip
                ? 'Kimlik ve aşı tarafı güçlü görünüyor.'
                : 'Lufthansa öncesi kuduz kaydı ve mikroçip kontrolü yap.',
            isDone: rabiesValid && hasChip,
          ),
          _TravelCheckItem(
            title: 'Sağlık sertifikası',
            subtitle: hasHealthCertificate
                ? 'Veteriner onayı arşivde mevcut.'
                : 'Uluslararası uçuş için sağlık sertifikası hazırlamak iyi olur.',
            isDone: hasHealthCertificate,
          ),
          _TravelCheckItem(
            title: 'Pet passport / AB belgesi',
            subtitle: hasPassport
                ? 'AB tipi belge hazır.'
                : 'Avrupa bağlantılı uçuşlarda pasaport büyük kolaylık sağlar.',
            isDone: hasPassport,
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pati Pasaportu')),
      body: FutureBuilder<List<Object>>(
        future: Future.wait([
          widget.vaccineRepository.getByPetId(widget.petId),
          widget.documentRepository.getByPetId(widget.petId),
        ]),
        builder: (context, snapshot) {
          final vaccines = snapshot.data == null
              ? <Vaccine>[]
              : snapshot.data![0] as List<Vaccine>;
          final documents = snapshot.data == null
              ? <PetDocument>[]
              : snapshot.data![1] as List<PetDocument>;
          final checklist = _buildChecklist(vaccines, documents);
          final infoNote = _buildInfoNote();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3D8BFF), Color(0xFF2EC4B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seyahat modu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.petName} için rota seç, uygulama mevcut aşı ve belge kayıtlarını hızlıca kontrol etsin.',
                      style: const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String>(
                initialValue: _selectedDestination,
                decoration: const InputDecoration(
                  labelText: 'Nereye / hangi taşıyıcı ile?',
                ),
                items: _destinations
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDestination = value);
                  }
                },
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D8BFF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF3D8BFF),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            infoNote.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            infoNote.body,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFFFB84D).withValues(alpha: 0.55),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.gpp_maybe_outlined,
                      color: Color(0xFFFF9800),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bu liste hızlı hazırlık içindir. Son kontrolü resmi ülke / havayolu kurallarından yapın.',
                        style: TextStyle(
                          color: Color(0xFF5F3A00),
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...checklist.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        item.isDone
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: item.isDone ? const Color(0xFF2EC4B6) : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
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
}

class _TravelCheckItem {
  final String title;
  final String subtitle;
  final bool isDone;

  const _TravelCheckItem({
    required this.title,
    required this.subtitle,
    required this.isDone,
  });
}

class _TravelInfoNote {
  final String title;
  final String body;

  const _TravelInfoNote({
    required this.title,
    required this.body,
  });
}
