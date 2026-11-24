import 'package:flutter/material.dart';

import '../theme.dart';

class WordPoolSelector extends StatelessWidget {
  const WordPoolSelector({
    required this.themes,
    required this.labels,
    required this.selectedTheme,
    required this.selectedLabels,
    required this.markedOnly,
    required this.onThemeChanged,
    required this.onLabelsChanged,
    required this.onMarkedChanged,
    super.key,
  });

  static const _allThemes = '__all_themes__';

  final List<String> themes;
  final List<String> labels;
  final String? selectedTheme;
  final Set<String> selectedLabels;
  final bool markedOnly;
  final ValueChanged<String?> onThemeChanged;
  final ValueChanged<Set<String>> onLabelsChanged;
  final ValueChanged<bool> onMarkedChanged;

  Future<void> _selectLabels(BuildContext context) async {
    final selected = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _LabelSelectionDialog(
        labels: labels,
        selectedLabels: selectedLabels,
      ),
    );
    if (selected != null) onLabelsChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Thème', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.card,
            border: Border.all(color: AppTheme.border),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTheme ?? _allThemes,
              isExpanded: true,
              dropdownColor: AppTheme.card,
              items: [
                const DropdownMenuItem(
                  value: _allThemes,
                  child: Text('Tous les thèmes'),
                ),
                ...themes.map(
                  (theme) => DropdownMenuItem(value: theme, child: Text(theme)),
                ),
              ],
              onChanged: (value) => onThemeChanged(
                value == _allThemes ? null : value,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: labels.isEmpty ? null : () => _selectLabels(context),
          icon: const Icon(Icons.label_outline),
          label: Text(
            selectedLabels.isEmpty
                ? 'Tous les labels'
                : 'Labels : ${selectedLabels.join(', ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mots marqués uniquement'),
          subtitle: const Text('Pour réviser les mots difficiles'),
          value: markedOnly,
          onChanged: onMarkedChanged,
        ),
      ],
    );
  }
}

class _LabelSelectionDialog extends StatefulWidget {
  const _LabelSelectionDialog({
    required this.labels,
    required this.selectedLabels,
  });

  final List<String> labels;
  final Set<String> selectedLabels;

  @override
  State<_LabelSelectionDialog> createState() => _LabelSelectionDialogState();
}

class _LabelSelectionDialogState extends State<_LabelSelectionDialog> {
  late final Set<String> _selected = {...widget.selectedLabels};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrer par labels'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aucun label sélectionné = tous les labels. '
                'Avec plusieurs choix, un seul label correspondant suffit.',
              ),
              const SizedBox(height: 8),
              for (final label in widget.labels)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(label),
                  value: _selected.contains(label),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selected.add(label);
                      } else {
                        _selected.remove(label);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => setState(_selected.clear),
          child: const Text('Tout effacer'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}
