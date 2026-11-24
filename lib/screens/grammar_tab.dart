import 'package:flutter/material.dart';

import '../data/rule_repo.dart';
import '../models/rule.dart';
import '../theme.dart';

class GrammarTab extends StatefulWidget {
  const GrammarTab({super.key});

  @override
  State<GrammarTab> createState() => _GrammarTabState();
}

class _GrammarTabState extends State<GrammarTab> {
  static const _allThemes = '__all_themes__';

  List<Rule> _rules = [];
  List<String> _themes = [];
  String _selectedTheme = _allThemes;
  String? _error;
  bool _loading = true;
  int _loadRequest = 0;

  @override
  void initState() {
    super.initState();
    _load(refreshThemes: true, showLoading: true);
  }

  Future<void> _load({
    bool refreshThemes = false,
    bool showLoading = false,
  }) async {
    final request = ++_loadRequest;
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final themes = refreshThemes ? await RuleRepo.themes() : _themes;
      final selectedTheme =
          _selectedTheme != _allThemes && !themes.contains(_selectedTheme)
          ? _allThemes
          : _selectedTheme;
      final rules = await RuleRepo.all(
        theme: selectedTheme == _allThemes ? null : selectedTheme,
      );
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _themes = themes;
        _selectedTheme = selectedTheme;
        _rules = rules;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les règles : $error';
      });
    }
  }

  Future<void> _editRule([Rule? rule]) async {
    final editedRule = await showDialog<Rule>(
      context: context,
      builder: (context) => _RuleEditorDialog(rule: rule, themes: _themes),
    );
    if (editedRule == null || !mounted) return;

    try {
      if (rule == null) {
        await RuleRepo.insert(editedRule);
      } else {
        await RuleRepo.update(editedRule);
      }
      await _load(refreshThemes: true, showLoading: true);
    } catch (error) {
      _showError('Impossible d’enregistrer la règle : $error');
    }
  }

  Future<void> _confirmDelete(Rule rule) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette règle ?'),
        content: Text('« ${rule.title} » sera supprimée définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || rule.id == null || !mounted) return;

    try {
      await RuleRepo.delete(rule.id!);
      await _load(refreshThemes: true, showLoading: true);
    } catch (error) {
      _showError('Impossible de supprimer la règle : $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTheme,
                    isExpanded: true,
                    dropdownColor: AppTheme.card,
                    iconEnabledColor: AppTheme.muted,
                    style: const TextStyle(color: AppTheme.text, fontSize: 14),
                    items: [
                      const DropdownMenuItem(
                        value: _allThemes,
                        child: Text('Tous'),
                      ),
                      ..._themes.map(
                        (theme) =>
                            DropdownMenuItem(value: theme, child: Text(theme)),
                      ),
                    ],
                    onChanged: (theme) {
                      if (theme == null) return;
                      setState(() => _selectedTheme = theme);
                      _load();
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_rules.length} règle${_rules.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            Expanded(child: _buildRuleList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter une règle',
        onPressed: () => _editRule(),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRuleList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
        ),
      );
    }
    if (_rules.isEmpty) {
      return Center(
        child: Text(
          'Aucune règle trouvée.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 88),
      itemCount: _rules.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return GestureDetector(
          onLongPress: () => _confirmDelete(rule),
          child: ExpansionTile(
            key: ValueKey(rule.id),
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rule.theme,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Modifier la règle',
                  onPressed: () => _editRule(rule),
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTheme.muted,
                ),
              ],
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  rule.explanation,
                  style: const TextStyle(color: AppTheme.text, fontSize: 14),
                ),
              ),
              if (rule.structure != null && rule.structure!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Structure : ${rule.structure}',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              ...rule.exampleList.map(_buildExample),
              if (rule.mistakes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Erreurs fréquentes',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...rule.mistakes.map(
                  (mistake) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${mistake['wrong']} → ${mistake['right']}\n${mistake['explanation']}',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExample(String example) {
    final separator = example.indexOf(' - ');
    final english = separator < 0
        ? example.trim()
        : example.substring(0, separator).trim();
    final french = separator < 0 ? '' : example.substring(separator + 3).trim();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: english,
              style: const TextStyle(color: AppTheme.text, fontSize: 14),
            ),
            if (french.isNotEmpty)
              TextSpan(
                text: ' - $french',
                style: const TextStyle(color: AppTheme.muted, fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }
}

class _RuleEditorDialog extends StatefulWidget {
  const _RuleEditorDialog({required this.themes, this.rule});

  final Rule? rule;
  final List<String> themes;

  @override
  State<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<_RuleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _themeController;
  late final TextEditingController _explanationController;
  late final TextEditingController _examplesController;
  late final FocusNode _themeFocusNode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.rule?.title ?? '');
    _themeController = TextEditingController(text: widget.rule?.theme ?? '');
    _explanationController = TextEditingController(
      text: widget.rule?.explanation ?? '',
    );
    _examplesController = TextEditingController(
      text: widget.rule?.examples ?? '',
    );
    _themeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _themeController.dispose();
    _explanationController.dispose();
    _examplesController.dispose();
    _themeFocusNode.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      Rule(
        id: widget.rule?.id,
        title: _titleController.text.trim(),
        theme: _themeController.text.trim(),
        explanation: _explanationController.text.trim(),
        examples: _examplesController.text.trim(),
        structure: widget.rule?.structure,
        mistakes: widget.rule?.mistakes ?? const [],
        tags: widget.rule?.tags ?? const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.rule == null ? 'Ajouter une règle' : 'Modifier la règle',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: _requiredField,
              ),
              const SizedBox(height: 12),
              RawAutocomplete<String>(
                textEditingController: _themeController,
                focusNode: _themeFocusNode,
                optionsBuilder: (value) {
                  final query = value.text.trim().toLowerCase();
                  return widget.themes.where(
                    (theme) =>
                        query.isEmpty || theme.toLowerCase().contains(query),
                  );
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) =>
                        TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Thème'),
                          validator: _requiredField,
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                        ),
                optionsViewBuilder: (context, onSelected, options) => Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: AppTheme.card,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 180,
                        maxWidth: 320,
                      ),
                      child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: options
                            .map(
                              (theme) => InkWell(
                                onTap: () => onSelected(theme),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    theme,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _explanationController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Explication'),
                validator: _requiredField,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _examplesController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Exemples (anglais - français)',
                  alignLabelWithHint: true,
                ),
                validator: _requiredField,
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
        ElevatedButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }

  String? _requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'Champ obligatoire' : null;
}
