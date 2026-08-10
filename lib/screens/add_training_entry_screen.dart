import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/training_entry.dart';
import '../widgets/star_rating_input.dart';
import 'create_goal_screen.dart';

class AddTrainingEntryScreen extends StatefulWidget {
  const AddTrainingEntryScreen({super.key});

  @override
  State<AddTrainingEntryScreen> createState() => _AddTrainingEntryScreenState();
}

class _AddTrainingEntryScreenState extends State<AddTrainingEntryScreen> {
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

  static const _intensityOptions = [
    (TrainingIntensity.light, '😌', 'intensityLight'),
    (TrainingIntensity.medium, '😐', 'intensityMedium'),
    (TrainingIntensity.hard, '😤', 'intensityHard'),
    (TrainingIntensity.veryHard, '🔥', 'intensityVeryHard'),
  ];

  static const _moodOptions = [
    (Mood.frustrated, '😞', 'moodFrustrated'),
    (Mood.neutral, '😐', 'moodNeutral'),
    (Mood.good, '🙂', 'moodGood'),
    (Mood.motivated, '😤', 'moodMotivated'),
    (Mood.onFire, '🔥', 'moodOnFire'),
  ];

  DateTime _date = DateTime.now();
  TrainingType? _trainingType;
  TrainingIntensity? _intensity;
  int _rating = 0;
  Mood? _mood;
  final _wellController = TextEditingController();
  final _badController = TextEditingController();
  final _improvementController = TextEditingController();

  bool get _canSave => _trainingType != null;

  @override
  void dispose() {
    _wellController.dispose();
    _badController.dispose();
    _improvementController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _openCreateGoalFromProblem(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateGoalScreen(initialDescription: _badController.text.trim()),
      ),
    );
  }

  Future<void> _showSavedCheckmark(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, _, _) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });
        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (context, value, _) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: Colors.green.shade600, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _save(BuildContext context) async {
    if (!_canSave) return;
    LogbookData.addEntry(
      date: _date,
      trainingType: _trainingType!,
      intensity: _intensity ?? TrainingIntensity.medium,
      rating: _rating,
      mood: _mood,
      whatWentWell: _wellController.text.trim(),
      whatWentBad: _badController.text.trim(),
      improvement: _improvementController.text.trim(),
    );
    await _showSavedCheckmark(context);
    if (context.mounted) Navigator.of(context).pop();
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade400,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, {VoidCallback? onChanged}) {
    return TextField(
      controller: controller,
      maxLines: 3,
      minLines: 2,
      onChanged: onChanged == null ? null : (_) => onChanged(),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _buildDateRow(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: primary),
            const SizedBox(width: 10),
            Text(
              '${_date.day}.${_date.month}.${_date.year}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainingTypeChips(AppStrings s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in TrainingType.values)
          ChoiceChip(
            label: Text(s(_typeLabelKeys[type]!)),
            selected: _trainingType == type,
            onSelected: (_) => setState(() => _trainingType = type),
          ),
      ],
    );
  }

  Widget _buildIntensityPicker(BuildContext context, AppStrings s) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        for (final (value, emoji, labelKey) in _intensityOptions)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _intensity = value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _intensity == value ? primary.withValues(alpha: 0.2) : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _intensity == value ? primary : Colors.transparent, width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(s(labelKey), style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMoodPicker(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (value, emoji, _) in _moodOptions)
          GestureDetector(
            onTap: () => setState(() => _mood = _mood == value ? null : value),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _mood == value ? primary.withValues(alpha: 0.2) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: _mood == value ? primary : Colors.transparent, width: 1.5),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: AppSettings.locale,
      builder: (context, locale, _) {
        final s = AppStrings.of(locale);
        return Scaffold(
          appBar: AppBar(title: Text(s('addTrainingEntry'))),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _sectionLabel(s('entryDate')),
                _buildDateRow(context),
                const SizedBox(height: 24),
                _sectionLabel(s('trainingTypeLabel')),
                _buildTrainingTypeChips(s),
                const SizedBox(height: 24),
                _sectionLabel(s('intensityLabel')),
                _buildIntensityPicker(context, s),
                const SizedBox(height: 24),
                _sectionLabel(s('howWasTraining')),
                StarRatingInput(rating: _rating, onChanged: (r) => setState(() => _rating = r)),
                const SizedBox(height: 24),
                _sectionLabel(s('whatWentWellLabel')),
                _textField(_wellController),
                const SizedBox(height: 24),
                _sectionLabel(s('whatWentBadLabel')),
                _textField(_badController, onChanged: () => setState(() {})),
                if (_badController.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () => _openCreateGoalFromProblem(context),
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: Text(s('createGoalFromProblem')),
                    ),
                  ),
                const SizedBox(height: 24),
                _sectionLabel(s('improvementLabel')),
                _textField(_improvementController),
                const SizedBox(height: 24),
                _sectionLabel(s('moodLabel')),
                _buildMoodPicker(context),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSave ? () => _save(context) : null,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(
                      s('saveEntry'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
