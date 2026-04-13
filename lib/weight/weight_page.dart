import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../shared/app_utils.dart';
import 'weight_model.dart';
import 'weight_repository.dart';

class WeightPage extends StatefulWidget {
  final String petId;
  final String petName;
  final WeightRepository repository;

  const WeightPage({
    super.key,
    required this.petId,
    required this.petName,
    required this.repository,
  });

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  late Future<List<WeightRecord>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.repository.getByPetId(widget.petId);
  }

  void _addWeight() {
    final controller = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Kilo Ekle',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Ağırlık (kg)',
                  hintText: 'ör. 4.2',
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tarih seçici
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF2EC4B6))),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFF2EC4B6)),
                      const SizedBox(width: 10),
                      Text(
                        selectedDate.toLocal().toString().split(' ')[0],
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notlar (opsiyonel)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                onPressed: () async {
                    final kg = double.tryParse(
                        controller.text.replaceAll(',', '.'));
                    if (kg == null || kg <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Geçerli bir ağırlık girin')));
                      return;
                    }
                    await widget.repository.add(WeightRecord(
                      id: const Uuid().v4(),
                      petId: widget.petId,
                      weightKg: kg,
                      recordedAt: selectedDate,
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    ));
                    if (ctx.mounted) Navigator.pop(ctx);
                    setState(_reload);
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _delete(WeightRecord r) async {
    await widget.repository.delete(r.id);
    if (!mounted) return;
    setState(_reload);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${r.weightKg.toStringAsFixed(1)} kg kaydı silindi'),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () async {
            await widget.repository.add(r);
            if (mounted) setState(_reload);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<WeightRecord>>(
        future: _future,
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              _buildHeader(records),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()))
              else if (records.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _buildChart(records),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('Geçmiş',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.onSurface)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final r = records.reversed.toList()[i];
                        final prev = i < records.length - 1
                            ? records.reversed.toList()[i + 1]
                            : null;
                        final diff = prev == null
                            ? null
                            : r.weightKg - prev.weightKg;
                        return _WeightTile(
                          record: r,
                          diff: diff,
                          onDelete: () => _delete(r),
                        );
                      },
                      childCount: records.length,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWeight,
        icon: const Icon(Icons.add),
        label: const Text('Kilo Ekle',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(List<WeightRecord> records) {
    final latest = records.isEmpty ? null : records.last;
    final prev =
        records.length >= 2 ? records[records.length - 2] : null;
    final diff =
        latest != null && prev != null ? latest.weightKg - prev.weightKg : null;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3D8BFF)],
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
            const Text('Kilo Takibi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800)),
            if (latest != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _statPill('${latest.weightKg.toStringAsFixed(1)} kg',
                      'Son ölçüm'),
                  const SizedBox(width: 12),
                  if (diff != null)
                    _statPill(
                      '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                      'Önceki ölçüme göre',
                      color: diff > 0
                          ? Colors.orange
                          : diff < 0
                              ? Colors.greenAccent
                              : Colors.white,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statPill(String value, String label, {Color color = Colors.white}) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      );

  Widget _buildChart(List<WeightRecord> records) {
    final spots = records.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weightKg))
        .toList();
    final xInterval = records.length <= 4
        ? 1.0
        : records.length <= 8
            ? 2.0
            : (records.length / 4).ceilToDouble();

    final minY =
        (records.map((r) => r.weightKg).reduce((a, b) => a < b ? a : b) - 0.5)
            .clamp(0.0, double.infinity);
    final maxY =
        records.map((r) => r.weightKg).reduce((a, b) => a > b ? a : b) + 0.5;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade100,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: xInterval,
                reservedSize: 30,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= records.length || (v - i).abs() > 0.001) {
                    return const SizedBox.shrink();
                  }
                  final d = records[i].recordedAt;
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      formatShortDate(d),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF6C63FF),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF6C63FF),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.2),
                    const Color(0xFF6C63FF).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.monitor_weight_outlined,
                  size: 48, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: 20),
            Text('Henüz kilo kaydedilmedi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('İlk ölçümü ekleyerek ağırlık değişimini\ngün ve tarih bazlı daha net takip et.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade500, height: 1.5)),
          ],
        ),
      );
}

class _WeightTile extends StatelessWidget {
  final WeightRecord record;
  final double? diff;
  final VoidCallback onDelete;

  const _WeightTile({
    required this.record,
    required this.diff,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final diffColor = diff == null
        ? Colors.grey
        : diff! > 0
            ? Colors.orange
            : diff! < 0
                ? const Color(0xFF2EC4B6)
                : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.monitor_weight_outlined,
                  color: Color(0xFF6C63FF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${record.weightKg.toStringAsFixed(1)} kg',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        formatDate(record.recordedAt),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                      ),
                      if (diff != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${diff! >= 0 ? '+' : ''}${diff!.toStringAsFixed(1)} kg',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: diffColor),
                        ),
                      ],
                    ],
                  ),
                  if (record.notes != null)
                    Text(record.notes!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            IconButton(
            icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
            onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
