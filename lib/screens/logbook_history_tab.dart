import 'package:flutter/material.dart';
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/training_entry.dart';

class LogbookHistoryTab extends StatefulWidget {
  const LogbookHistoryTab({super.key, required this.s});

  final AppStrings s;

  @override
  State<LogbookHistoryTab> createState() => _LogbookHistoryTabState();
}

class _LogbookHistoryTabState extends State<LogbookHistoryTab> {
  static const _typeLabelKeys = {
    TrainingType.technique: 'trainingTypeTechnique',
    TrainingType.sparring: 'trainingTypeSparring',
    TrainingType.boxing: 'trainingTypeBoxing',
    TrainingType.muayThai: 'trainingTypeMuayThai',
    TrainingType.kickboxing: 'trainingTypeKickboxing',
    TrainingType.mma: 'trainingTypeMma',
    TrainingType.strength: 'trainingTypeStrength',
    TrainingType.cardio: 'trainingTypeCardio',
    TrainingType.other: 'trainingTypeOther',
  };

  static const _intensityLabelKeys = {
    TrainingIntensity.light: 'intensityLight',
    TrainingIntensity.medium: 'intensityMedium',
    TrainingIntensity.hard: 'intensityHard',
    TrainingIntensity.veryHard: 'intensityVeryHard',
  };

  String _query = '';
  TrainingType? _typeFilter;
  TrainingIntensity? _intensityFilter;
  int? _ratingFilter;
  DateTimeRange? _dateRangeFilter;

  bool get _hasActiveFilters =>
      _typeFilter != null || _intensityFilter != null || _ratingFilter != null || _dateRangeFilter != null;

  void _clearFilters() {
    setState(() {
      _typeFilter = null;
      _intensityFilter = null;
      _ratingFilter = null;
      _dateRangeFilter = null;
    });
  }

  String _fmtDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  String _typeEmoji(TrainingType type) {
    switch (type) {
      case TrainingType.technique:
      case TrainingType.sparring:
      case TrainingType.boxing:
        return '🥊';
      case TrainingType.muayThai:
      case TrainingType.kickboxing:
        return '🦵';
      case TrainingType.mma:
        return '🤼';
      case TrainingType.strength:
        return '🏋️';
      case TrainingType.cardio:
        return '🏃';
      case TrainingType.other:
        return '📋';
    }
  }

  String _intensityEmoji(TrainingIntensity intensity) {
    switch (intensity) {
      case TrainingIntensity.light:
        return '😌';
      case TrainingIntensity.medium:
        return '😐';
      case TrainingIntensity.hard:
        return '😤';
      case TrainingIntensity.veryHard:
        return '🔥';
    }
  }

  String _moodEmoji(Mood mood) {
    switch (mood) {
      case Mood.frustrated:
        return '😞';
      case Mood.neutral:
        return '😐';
      case Mood.good:
        return '🙂';
      case Mood.motivated:
        return '😤';
      case Mood.onFire:
        return '🔥';
    }
  }

  List<TrainingEntry> _filtered(List<TrainingEntry> all) {
    return all.where((e) {
      if (_typeFilter != null && e.trainingType != _typeFilter) return false;
      if (_intensityFilter != null && e.intensity != _intensityFilter) return false;
      if (_ratingFilter != null && e.rating != _ratingFilter) return false;
      if (_dateRangeFilter != null) {
        final day = DateTime(e.date.year, e.date.month, e.date.day);
        if (day.isBefore(_dateRangeFilter!.start) || day.isAfter(_dateRangeFilter!.end)) return false;
      }
      final query = _query.trim().toLowerCase();
      if (query.isNotEmpty) {
        final haystack = '${e.whatWentWell} ${e.whatWentBad} ${e.improvement}'.toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRangeFilter,
    );
    if (range != null) setState(() => _dateRangeFilter = range);
  }

  void _deleteEntry(BuildContext context, TrainingEntry entry) {
    LogbookData.deleteEntry(entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.s('entryDeleted')),
        action: SnackBarAction(label: widget.s('undo'), onPressed: () => LogbookData.restoreEntry(entry)),
      ),
    );
  }

  Widget _detailBlock(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  void _showEntryDetail(BuildContext context, TrainingEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_typeEmoji(entry.trainingType), style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      widget.s(_typeLabelKeys[entry.trainingType]!),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const Spacer(),
                    Text(_fmtDate(entry.date), style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= entry.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 20,
                        color: i <= entry.rating ? Colors.amber : Colors.grey.shade700,
                      ),
                    const SizedBox(width: 10),
                    Text(_intensityEmoji(entry.intensity), style: const TextStyle(fontSize: 20)),
                    if (entry.mood != null) ...[
                      const SizedBox(width: 10),
                      Text(_moodEmoji(entry.mood!), style: const TextStyle(fontSize: 20)),
                    ],
                  ],
                ),
                if (entry.whatWentWell.isNotEmpty)
                  _detailBlock(widget.s('whatWentWellLabel'), entry.whatWentWell),
                if (entry.whatWentBad.isNotEmpty)
                  _detailBlock(widget.s('whatWentBadLabel'), entry.whatWentBad),
                if (entry.improvement.isNotEmpty)
                  _detailBlock(widget.s('improvementLabel'), entry.improvement),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Widget filterHeading(String text) => Text(
                  text,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w700),
                );

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.s('filterLabel'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    filterHeading(widget.s('filterDateRange')),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _pickDateRange(sheetContext);
                        setSheetState(() {});
                      },
                      icon: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _dateRangeFilter == null
                            ? widget.s('filterDateRange')
                            : '${_fmtDate(_dateRangeFilter!.start)} - ${_fmtDate(_dateRangeFilter!.end)}',
                      ),
                    ),
                    const SizedBox(height: 18),
                    filterHeading(widget.s('filterTrainingType')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in TrainingType.values)
                          ChoiceChip(
                            label: Text(widget.s(_typeLabelKeys[type]!)),
                            selected: _typeFilter == type,
                            onSelected: (selected) => setSheetState(
                              () => setState(() => _typeFilter = selected ? type : null),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    filterHeading(widget.s('filterIntensity')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final intensity in TrainingIntensity.values)
                          ChoiceChip(
                            label: Text(widget.s(_intensityLabelKeys[intensity]!)),
                            selected: _intensityFilter == intensity,
                            onSelected: (selected) => setSheetState(
                              () => setState(() => _intensityFilter = selected ? intensity : null),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    filterHeading(widget.s('filterRating')),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var r = 1; r <= 5; r++)
                          ChoiceChip(
                            label: Text('$r ⭐'),
                            selected: _ratingFilter == r,
                            onSelected: (selected) => setSheetState(
                              () => setState(() => _ratingFilter = selected ? r : null),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _clearFilters();
                              setSheetState(() {});
                            },
                            child: Text(widget.s('clearFilters')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Text(widget.s('done')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _entryCard(BuildContext context, TrainingEntry entry) {
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 12),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteEntry(context, entry),
      child: GestureDetector(
        onTap: () => _showEntryDetail(context, entry),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_typeEmoji(entry.trainingType), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.s(_typeLabelKeys[entry.trainingType]!),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  Text(_fmtDate(entry.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= entry.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: i <= entry.rating ? Colors.amber : Colors.grey.shade700,
                    ),
                  const SizedBox(width: 8),
                  Text(_intensityEmoji(entry.intensity), style: const TextStyle(fontSize: 14)),
                ],
              ),
              if (entry.whatWentBad.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '⚠️ ${entry.whatWentBad}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TrainingEntry>>(
      valueListenable: LogbookData.entries,
      builder: (context, allEntries, _) {
        final filtered = _filtered(allEntries);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: widget.s('searchEntries'),
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1C1C1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Material(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openFilterSheet(context),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.tune, color: Colors.white),
                          ),
                        ),
                      ),
                      if (_hasActiveFilters)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(widget.s('noEntriesFound'), style: TextStyle(color: Colors.grey.shade500)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _entryCard(context, filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }
}
