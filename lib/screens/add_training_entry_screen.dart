import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/pain_entry.dart';
import '../models/sparring_log.dart';
import '../models/training_entry.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/coach_tour.dart';
import '../widgets/star_rating_input.dart';
import 'create_goal_screen.dart';

class AddTrainingEntryScreen extends StatefulWidget {
  const AddTrainingEntryScreen({super.key, this.initialGoal = ''});

  /// Vorbefüllt das Trainingsziel, z.B. wenn der Nutzer im Dashboard einen
  /// Fokus-Vorschlag über "Als Trainingsziel übernehmen" übernimmt.
  final String initialGoal;

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

  static const _additionalSportKeys = {
    'bjj': 'sportBjj',
    'judo': 'sportJudo',
    'wrestling': 'sportWrestling',
    'karate': 'sportKarate',
    'taekwondo': 'sportTaekwondo',
    'catch_wrestling': 'sportCatchWrestling',
    'sambo': 'sportSambo',
  };

  static const _sessionTypeKeys = {
    SessionType.techniqueDrilling: 'sessionTypeTechniqueDrilling',
    SessionType.sparring: 'sessionTypeSparring',
    SessionType.competitionPrep: 'sessionTypeCompetitionPrep',
    SessionType.strengthConditioning: 'sessionTypeStrengthConditioning',
    SessionType.openMat: 'sessionTypeOpenMat',
    SessionType.seminar: 'sessionTypeSeminar',
  };

  static const _moodOptions = [
    (Mood.frustrated, '😞', 'moodFrustrated'),
    (Mood.neutral, '😐', 'moodNeutral'),
    (Mood.good, '🙂', 'moodGood'),
    (Mood.motivated, '😤', 'moodMotivated'),
    (Mood.onFire, '🔥', 'moodOnFire'),
  ];

  int _currentStep = 0;

  // Anker für die geführte Tour (CoachTour) -- je ein Key pro erklärbarem
  // Feld, damit das Spotlight-Overlay dessen Position auf dem Bildschirm
  // findet.
  final _trainingTypeKey = GlobalKey();
  final _additionalSportsKey = GlobalKey();
  final _sessionTypeKey = GlobalKey();
  final _durationKey = GlobalKey();
  final _rpeKey = GlobalKey();
  final _energyKey = GlobalKey();
  final _focusKey = GlobalKey();
  final _sleepKey = GlobalKey();
  final _painKey = GlobalKey();
  final _goalKey = GlobalKey();
  final _techniquesKey = GlobalKey();
  final _successKey = GlobalKey();
  final _sparringKey = GlobalKey();
  final _ratingKey = GlobalKey();
  final _keyTakeawayKey = GlobalKey();
  final _wellKey = GlobalKey();
  final _badKey = GlobalKey();
  final _improvementKey = GlobalKey();
  final _moodKey = GlobalKey();

  DateTime _date = DateTime.now();
  TrainingType? _trainingType;
  final Set<String> _additionalSports = {};
  SessionType? _sessionType;
  int? _durationMinutes;
  int _rpe = 0;

  int _energyLevelPre = 0;
  int _focusLevelPre = 0;
  int _sleepQuality = 0;
  bool _painEnabled = false;
  final List<PainEntry> _painEntries = [];

  final List<String> _techniquesPracticed = [];
  int _techniqueSuccessRating = 0;
  int? _rounds;
  int? _roundLengthMinutes;
  final Set<PartnerLevel> _partnerLevels = {};
  int _submissionsFor = 0;
  int _submissionsAgainst = 0;
  int _takedownsFor = 0;
  int _takedownsAgainst = 0;
  int _strikesFor = 0;
  int _strikesAgainst = 0;

  int _rating = 0;
  Mood? _mood;
  late final _goalController = TextEditingController(text: widget.initialGoal);
  final _wellController = TextEditingController();
  final _badController = TextEditingController();
  final _improvementController = TextEditingController();
  final _keyTakeawayController = TextEditingController();
  final _techniqueTagController = TextEditingController();

  bool get _canSave => _trainingType != null;

  bool get _showTechniqueStep => _sessionType != SessionType.strengthConditioning;
  bool get _showSparringLog => _sessionType == SessionType.sparring || _sessionType == SessionType.competitionPrep;

  List<String> get _stepTitleKeys => [
        'wizardStepSession',
        'wizardStepCheckIn',
        if (_showTechniqueStep) (_showSparringLog ? 'wizardStepTechnique' : 'wizardStepTechniqueOnly'),
        'wizardStepReflection',
      ];

  void _clampStep() {
    final maxIndex = _stepTitleKeys.length - 1;
    if (_currentStep > maxIndex) _currentStep = maxIndex;
  }

  @override
  void dispose() {
    _goalController.dispose();
    _wellController.dispose();
    _badController.dispose();
    _improvementController.dispose();
    _keyTakeawayController.dispose();
    _techniqueTagController.dispose();
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

  /// RPE (1-10, was der Nutzer im Wizard einstellt) wird auf die bestehende
  /// vierstufige TrainingIntensity abgebildet, statt eine zweite,
  /// redundante Intensitäts-Abfrage zu zeigen -- Historie-Filter & bestehende
  /// Auswertungen bleiben dadurch unverändert funktionsfähig.
  TrainingIntensity _intensityFromRpe(int rpe) {
    if (rpe <= 3) return TrainingIntensity.light;
    if (rpe <= 6) return TrainingIntensity.medium;
    if (rpe <= 8) return TrainingIntensity.hard;
    return TrainingIntensity.veryHard;
  }

  Future<void> _save(BuildContext context) async {
    if (!_canSave) return;
    final sparringLog = _showSparringLog &&
            (_rounds != null ||
                _partnerLevels.isNotEmpty ||
                _submissionsFor > 0 ||
                _submissionsAgainst > 0 ||
                _takedownsFor > 0 ||
                _takedownsAgainst > 0 ||
                _strikesFor > 0 ||
                _strikesAgainst > 0)
        ? SparringLog(
            rounds: _rounds,
            roundLengthMinutes: _roundLengthMinutes,
            partnerLevels: _partnerLevels.toList(),
            submissionsFor: _submissionsFor,
            submissionsAgainst: _submissionsAgainst,
            takedownsFor: _takedownsFor,
            takedownsAgainst: _takedownsAgainst,
            significantStrikesFor: _strikesFor,
            significantStrikesAgainst: _strikesAgainst,
          )
        : null;

    LogbookData.addEntry(
      date: _date,
      trainingType: _trainingType!,
      intensity: _rpe == 0 ? TrainingIntensity.medium : _intensityFromRpe(_rpe),
      rating: _rating,
      mood: _mood,
      goal: _goalController.text.trim(),
      durationMinutes: _durationMinutes,
      whatWentWell: _wellController.text.trim(),
      whatWentBad: _badController.text.trim(),
      improvement: _improvementController.text.trim(),
      sessionType: _sessionType,
      additionalSports: _additionalSports.toList(),
      rpe: _rpe == 0 ? null : _rpe,
      energyLevelPre: _energyLevelPre == 0 ? null : _energyLevelPre,
      focusLevelPre: _focusLevelPre == 0 ? null : _focusLevelPre,
      sleepQuality: _sleepQuality == 0 ? null : _sleepQuality,
      painEntries: _painEnabled ? _painEntries : const [],
      techniquesPracticed: _techniquesPracticed,
      techniqueSuccessRating: _techniqueSuccessRating == 0 ? null : _techniqueSuccessRating,
      sparringLog: sparringLog,
      keyTakeaway: _keyTakeawayController.text.trim().isEmpty ? null : _keyTakeawayController.text.trim(),
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

  Widget _textField(TextEditingController controller, {VoidCallback? onChanged, String? hintText}) {
    return TextField(
      controller: controller,
      maxLines: 3,
      minLines: 2,
      onChanged: onChanged == null ? null : (_) => onChanged(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF1C1C1E),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 18, color: Colors.white)),
      ),
    );
  }

  Widget _counterField(String label, int value, ValueChanged<int> onChanged, {int min = 0, int max = 99}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13))),
          _stepButton(Icons.remove, () => onChanged((value - 1).clamp(min, max))),
          SizedBox(
            width: 36,
            child: Center(
              child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          _stepButton(Icons.add, () => onChanged((value + 1).clamp(min, max))),
        ],
      ),
    );
  }

  Widget _tagInput({
    required List<String> tags,
    required TextEditingController controller,
    required String hintText,
  }) {
    void addTag() {
      final value = controller.text.trim();
      if (value.isEmpty) return;
      setState(() {
        if (!tags.contains(value)) tags.add(value);
        controller.clear();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  Chip(
                    label: Text(tag),
                    backgroundColor: const Color(0xFF1C1C1E),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
                    deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white54),
                    onDeleted: () => setState(() => tags.remove(tag)),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                onSubmitted: (_) => addTag(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1C1C1E),
                  hintText: hintText,
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _stepButton(Icons.add, addTag),
          ],
        ),
      ],
    );
  }

  // --- Schritt 1: Session ---

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

  Widget _buildAdditionalSportsChips(AppStrings s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in _additionalSportKeys.entries)
          FilterChip(
            label: Text(s(entry.value)),
            selected: _additionalSports.contains(entry.key),
            onSelected: (selected) => setState(() {
              if (selected) {
                _additionalSports.add(entry.key);
              } else {
                _additionalSports.remove(entry.key);
              }
            }),
          ),
      ],
    );
  }

  Widget _buildSessionTypeChips(AppStrings s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in SessionType.values)
          ChoiceChip(
            label: Text(s(_sessionTypeKeys[type]!)),
            selected: _sessionType == type,
            onSelected: (_) => setState(() {
              _sessionType = _sessionType == type ? null : type;
              _clampStep();
            }),
          ),
      ],
    );
  }

  List<int> get _durationOptions {
    const presets = [15, 30, 45, 60, 75, 90, 120];
    if (_durationMinutes != null && !presets.contains(_durationMinutes)) {
      return [...presets, _durationMinutes!]..sort();
    }
    return presets;
  }

  Future<void> _pickCustomDuration(BuildContext context, AppStrings s) async {
    final controller = TextEditingController(
      text: _durationMinutes != null ? _durationMinutes.toString() : '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(s('durationLabel'), style: const TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(suffixText: s('minutesUnit')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(s('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(int.tryParse(controller.text.trim())),
              child: Text(s('done')),
            ),
          ],
        );
      },
    );
    if (result != null && result > 0) setState(() => _durationMinutes = result);
  }

  Widget _buildDurationChips(BuildContext context, AppStrings s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final minutes in _durationOptions)
          ChoiceChip(
            label: Text('$minutes ${s('minutesUnit')}'),
            selected: _durationMinutes == minutes,
            onSelected: (_) => setState(() => _durationMinutes = minutes),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: Text(s('durationCustom')),
          onPressed: () => _pickCustomDuration(context, s),
        ),
      ],
    );
  }

  Widget _buildRpeSlider(BuildContext context, AppStrings s) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _rpe == 0 ? '—' : '$_rpe/10',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primary),
            ),
          ],
        ),
        Slider(
          value: (_rpe == 0 ? 5 : _rpe).toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          activeColor: primary,
          label: '$_rpe',
          onChanged: (value) => setState(() => _rpe = value.round()),
        ),
        Text(s('rpeHint'), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildSessionStep(BuildContext context, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(s('entryDate')),
        _buildDateRow(context),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _trainingTypeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('trainingTypeLabel')), _buildTrainingTypeChips(s)],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _additionalSportsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('additionalSportsLabel')), _buildAdditionalSportsChips(s)],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _sessionTypeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('sessionTypeLabel')), _buildSessionTypeChips(s)],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _durationKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('durationLabel')), _buildDurationChips(context, s)],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _rpeKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('rpeLabel')), _buildRpeSlider(context, s)],
          ),
        ),
      ],
    );
  }

  // --- Schritt 2: Check-in ---

  Future<void> _addPainZoneSheet(BuildContext context, AppStrings s) async {
    BodyZone selectedZone = BodyZone.other;
    int intensity = 3;
    final noteController = TextEditingController();

    final entry = await showModalBottomSheet<PainEntry>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                      s('addPainZone'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final zone in BodyZone.values)
                          ChoiceChip(
                            label: Text(bodyZoneLabel(zone, s)),
                            selected: selectedZone == zone,
                            onSelected: (_) => setSheetState(() => selectedZone = zone),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(s('painIntensityLabel'), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                    const SizedBox(height: 8),
                    StarRatingInput(
                      rating: intensity,
                      onChanged: (value) => setSheetState(() => intensity = value),
                    ),
                    const SizedBox(height: 16),
                    _textField(noteController),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(
                          PainEntry(bodyZone: selectedZone, intensity: intensity, note: noteController.text.trim()),
                        ),
                        child: Text(s('add')),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (entry != null) setState(() => _painEntries.add(entry));
  }

  Widget _buildPainSection(BuildContext context, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(s('painToggleLabel'), style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
            Switch(
              value: _painEnabled,
              onChanged: (value) => setState(() => _painEnabled = value),
            ),
          ],
        ),
        if (_painEnabled) ...[
          const SizedBox(height: 8),
          for (final entry in _painEntries)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${bodyZoneLabel(entry.bodyZone, s)} · ${entry.intensity}/5',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                    onPressed: () => setState(() => _painEntries.remove(entry)),
                  ),
                ],
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => _addPainZoneSheet(context, s),
            icon: const Icon(Icons.add, size: 18),
            label: Text(s('addPainZone')),
          ),
        ],
      ],
    );
  }

  Widget _buildCheckInStep(BuildContext context, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: _energyKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(s('energyLevelLabel')),
              StarRatingInput(rating: _energyLevelPre, onChanged: (v) => setState(() => _energyLevelPre = v)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _focusKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(s('focusLevelLabel')),
              StarRatingInput(rating: _focusLevelPre, onChanged: (v) => setState(() => _focusLevelPre = v)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _sleepKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(s('sleepQualityLabel')),
              StarRatingInput(rating: _sleepQuality, onChanged: (v) => setState(() => _sleepQuality = v)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _painKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('painSectionLabel')), _buildPainSection(context, s)],
          ),
        ),
      ],
    );
  }

  // --- Schritt 3: Technik & Sparring ---

  Widget _buildSparringLogSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _counterField(s('roundsLabel'), _rounds ?? 0, (v) => setState(() => _rounds = v), max: 30),
        _counterField(s('roundLengthLabel'), _roundLengthMinutes ?? 0, (v) => setState(() => _roundLengthMinutes = v), max: 20),
        const SizedBox(height: 12),
        Text(s('partnerLevelLabel'), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in PartnerLevel.values)
              FilterChip(
                label: Text(partnerLevelLabel(level, s)),
                selected: _partnerLevels.contains(level),
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _partnerLevels.add(level);
                  } else {
                    _partnerLevels.remove(level);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(s('submissionsLabel'), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        _counterField(s('statFor'), _submissionsFor, (v) => setState(() => _submissionsFor = v)),
        _counterField(s('statAgainst'), _submissionsAgainst, (v) => setState(() => _submissionsAgainst = v)),
        const SizedBox(height: 8),
        Text(s('takedownsLabel'), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        _counterField(s('statFor'), _takedownsFor, (v) => setState(() => _takedownsFor = v)),
        _counterField(s('statAgainst'), _takedownsAgainst, (v) => setState(() => _takedownsAgainst = v)),
        const SizedBox(height: 8),
        Text(s('strikesLabel'), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
        _counterField(s('statFor'), _strikesFor, (v) => setState(() => _strikesFor = v)),
        _counterField(s('statAgainst'), _strikesAgainst, (v) => setState(() => _strikesAgainst = v)),
      ],
    );
  }

  Widget _buildTechniqueStep(BuildContext context, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: _goalKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('trainingGoalLabel')), _textField(_goalController)],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _techniquesKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(s('techniquesPracticedLabel')),
              _tagInput(
                tags: _techniquesPracticed,
                controller: _techniqueTagController,
                hintText: s('addTechniqueHint'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _successKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(s('techniqueSuccessLabel')),
              StarRatingInput(
                rating: _techniqueSuccessRating,
                onChanged: (v) => setState(() => _techniqueSuccessRating = v),
              ),
            ],
          ),
        ),
        if (_showSparringLog) ...[
          const SizedBox(height: 28),
          KeyedSubtree(
            key: _sparringKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_sectionLabel(s('sparringLogLabel')), _buildSparringLogSection(s)],
            ),
          ),
        ],
      ],
    );
  }

  // --- Schritt 4: Reflexion ---

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

  Widget _buildReflectionStep(BuildContext context, AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: _ratingKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(s('howWasTraining')),
              StarRatingInput(rating: _rating, onChanged: (r) => setState(() => _rating = r)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _keyTakeawayKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel(s('keyTakeawayLabel')),
              _textField(_keyTakeawayController, hintText: s('keyTakeawayHint')),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _wellKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('whatWentWellLabel')), _textField(_wellController)],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _badKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
            ],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _improvementKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('improvementLabel')), _textField(_improvementController)],
          ),
        ),
        const SizedBox(height: 24),
        KeyedSubtree(
          key: _moodKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_sectionLabel(s('moodLabel')), _buildMoodPicker(context)],
          ),
        ),
      ],
    );
  }

  // --- Wizard-Gerüst ---

  List<Widget Function(BuildContext, AppStrings)> get _stepBuilders => [
        _buildSessionStep,
        _buildCheckInStep,
        if (_showTechniqueStep) _buildTechniqueStep,
        _buildReflectionStep,
      ];

  /// Startet die geführte Tour für den aktuell sichtbaren Schritt: geht die
  /// dort tatsächlich angezeigten Felder der Reihe nach durch (Spotlight +
  /// Erklärung + Weiter-Button), statt für jedes Feld ein eigenes kleines
  /// Icon zu zeigen.
  void _startStepTour(BuildContext context, AppStrings s) {
    final steps = switch (_stepTitleKeys[_currentStep]) {
      'wizardStepSession' => [
          CoachTourStep(anchorKey: _trainingTypeKey, message: s('coachTourTrainingType')),
          CoachTourStep(anchorKey: _additionalSportsKey, message: s('coachTourAdditionalSports')),
          CoachTourStep(anchorKey: _sessionTypeKey, message: s('coachTourSessionType')),
          CoachTourStep(anchorKey: _durationKey, message: s('coachTourDuration')),
          CoachTourStep(anchorKey: _rpeKey, message: s('coachTourRpe')),
        ],
      'wizardStepCheckIn' => [
          CoachTourStep(anchorKey: _energyKey, message: s('coachTourEnergy')),
          CoachTourStep(anchorKey: _focusKey, message: s('coachTourFocus')),
          CoachTourStep(anchorKey: _sleepKey, message: s('coachTourSleep')),
          CoachTourStep(anchorKey: _painKey, message: s('coachTourPain')),
        ],
      'wizardStepTechnique' || 'wizardStepTechniqueOnly' => [
          CoachTourStep(anchorKey: _goalKey, message: s('coachTipGoal')),
          CoachTourStep(anchorKey: _techniquesKey, message: s('coachTourTechniques')),
          CoachTourStep(anchorKey: _successKey, message: s('coachTourSuccessRating')),
          if (_showSparringLog) CoachTourStep(anchorKey: _sparringKey, message: s('coachTourSparringLog')),
        ],
      'wizardStepReflection' => [
          CoachTourStep(anchorKey: _ratingKey, message: s('coachTourRating')),
          CoachTourStep(anchorKey: _keyTakeawayKey, message: s('coachTourKeyTakeaway')),
          CoachTourStep(anchorKey: _wellKey, message: s('coachTipWentWell')),
          CoachTourStep(anchorKey: _badKey, message: s('coachTipWentBad')),
          CoachTourStep(anchorKey: _improvementKey, message: s('coachTourImprovement')),
          CoachTourStep(anchorKey: _moodKey, message: s('coachTourMood')),
        ],
      _ => const <CoachTourStep>[],
    };
    showCoachTour(
      context,
      steps: steps,
      nextLabel: s('coachTourNext'),
      doneLabel: s('coachTourDone'),
      skipLabel: s('coachTourSkip'),
    );
  }

  Widget _buildStepIndicator(BuildContext context, AppStrings s) {
    final titles = _stepTitleKeys;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s('wizardStepIndicator')
              .replaceFirst('{current}', '${_currentStep + 1}')
              .replaceFirst('{total}', '${titles.length}'),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < titles.length; i++)
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == titles.length - 1 ? 0 : 6),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _currentStep
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          s(titles[_currentStep]),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
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
        _clampStep();
        final steps = _stepBuilders;
        final isFirstStep = _currentStep == 0;
        final isLastStep = _currentStep == steps.length - 1;
        return Scaffold(
          appBar: AppBar(
            title: Text(s('addTrainingEntry')),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: CoachAvatarIcon(onTap: () => _startStepTour(context, s))),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: _buildStepIndicator(context, s),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [steps[_currentStep](context, s)],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      if (!isFirstStep)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            child: Text(s('wizardBack')),
                          ),
                        ),
                      if (!isFirstStep) const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: isFirstStep && !_canSave
                              ? null
                              : () {
                                  if (isLastStep) {
                                    _save(context);
                                  } else {
                                    setState(() => _currentStep++);
                                  }
                                },
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: Text(
                            isLastStep ? s('saveEntry') : s('wizardNext'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
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
