import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../app_strings.dart';
import '../logbook_data.dart';
import '../models/improvement_goal.dart';

/// Dient sowohl zum Anlegen eines neuen Ziels als auch -- wenn [existingGoal]
/// gesetzt ist -- zum Bearbeiten eines bestehenden, statt ein fast
/// identisches zweites Formular zu duplizieren.
class CreateGoalScreen extends StatefulWidget {
  const CreateGoalScreen({super.key, this.initialDescription = '', this.existingGoal});

  final String initialDescription;
  final ImprovementGoal? existingGoal;

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  late final _titleController = TextEditingController(text: widget.existingGoal?.title ?? '');
  late final _descriptionController = TextEditingController(
    text: widget.existingGoal?.description ?? widget.initialDescription,
  );
  late SkillArea _category = widget.existingGoal?.category ?? SkillArea.technique;
  late GoalPriority _priority = widget.existingGoal?.priority ?? GoalPriority.medium;

  bool get _isEditing => widget.existingGoal != null;
  bool get _canSave => _titleController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_canSave) return;
    if (_isEditing) {
      final updated = widget.existingGoal!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        priority: _priority,
        updatedAt: DateTime.now(),
      );
      LogbookData.updateGoal(updated);
      Navigator.of(context).pop(updated);
    } else {
      final goal = LogbookData.addGoal(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        priority: _priority,
      );
      Navigator.of(context).pop(goal);
    }
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

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.all(14),
    );
  }

  Widget _buildCategoryPicker(AppStrings s) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final area in SkillArea.values)
          ChoiceChip(
            label: Text('${skillAreaEmoji(area)} ${skillAreaLabel(area, s)}'),
            selected: _category == area,
            onSelected: (_) => setState(() => _category = area),
          ),
      ],
    );
  }

  Widget _buildPriorityPicker(BuildContext context, AppStrings s) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        for (final priority in GoalPriority.values)
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _priority = priority),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _priority == priority ? primary.withValues(alpha: 0.2) : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _priority == priority ? primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    goalPriorityLabel(priority, s),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
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
          appBar: AppBar(title: Text(_isEditing ? s('editGoal') : s('createGoal'))),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (!_isEditing && widget.initialDescription.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s('problemLabel'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.initialDescription,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _sectionLabel(s('goalTitleLabel')),
                TextField(
                  controller: _titleController,
                  autofocus: widget.initialDescription.isEmpty && !_isEditing,
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDecoration(),
                ),
                const SizedBox(height: 24),
                _sectionLabel(s('goalDescriptionLabel')),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  minLines: 2,
                  decoration: _fieldDecoration(),
                ),
                const SizedBox(height: 24),
                _sectionLabel(s('goalCategoryLabel')),
                _buildCategoryPicker(s),
                const SizedBox(height: 24),
                _sectionLabel(s('goalPriorityLabel')),
                _buildPriorityPicker(context, s),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSave ? () => _save(context) : null,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: Text(
                      _isEditing ? s('saveGoal') : s('createGoal'),
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
