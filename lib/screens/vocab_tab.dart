import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../data/word_repo.dart';
import '../models/word.dart';
import '../services/vocab_pack_service.dart';
import '../theme.dart';

class VocabTab extends StatefulWidget {
  const VocabTab({super.key});

  @override
  State<VocabTab> createState() => _VocabTabState();
}

class _VocabTabState extends State<VocabTab> {
  static const _allThemes = '__all_themes__';

  final _searchController = TextEditingController();
  Timer? _editTimer;
  List<Word> _words = [];
  List<Map<String, String>> _readAloud = [];
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

  @override
  void dispose() {
    _editTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
      final themes = refreshThemes ? await WordRepo.themes() : _themes;
      final selectedTheme =
          _selectedTheme != _allThemes && !themes.contains(_selectedTheme)
          ? _allThemes
          : _selectedTheme;
      final words = await WordRepo.all(
        theme: selectedTheme == _allThemes ? null : selectedTheme,
        search: _searchController.text,
      );
      final readAloud = selectedTheme == _allThemes
          ? <Map<String, String>>[]
          : await WordRepo.readAloud(selectedTheme);
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _themes = themes;
        _selectedTheme = selectedTheme;
        _words = words;
        _readAloud = readAloud;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les mots : $error';
      });
    }
  }

  Future<void> _editWord([Word? word]) async {
    final editedWord = await showDialog<Word>(
      context: context,
      builder: (context) => _WordEditorDialog(word: word, themes: _themes),
    );
    if (editedWord == null || !mounted) return;

    try {
      if (word == null) {
        await WordRepo.insert(editedWord);
      } else {
        await WordRepo.update(editedWord);
      }
      await _load(refreshThemes: true, showLoading: true);
    } catch (error) {
      _showError('Impossible d’enregistrer le mot : $error');
    }
  }

  Future<void> _toggleMarked(Word word) async {
    try {
      await WordRepo.setMarked(word, !word.marked);
      await _load();
    } catch (error) {
      _showError('Impossible de modifier le marqueur : $error');
    }
  }

  Future<void> _confirmDelete(Word word) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce mot ?'),
        content: Text('Le mot « ${word.en} » sera supprimé définitivement.'),
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
    if (shouldDelete != true || word.id == null || !mounted) return;

    try {
      await WordRepo.delete(word.id!);
      await _load(refreshThemes: true, showLoading: true);
    } catch (error) {
      _showError('Impossible de supprimer le mot : $error');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickVocabPack() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (file == null) return;
      if (!_isVocabJson(file.name)) {
        _showError('Choisis un fichier .vocab.json ou .json.');
        return;
      }
      await _previewVocabPack(utf8.decode(await file.readAsBytes()));
    } catch (error) {
      _showError('Impossible d’ouvrir le fichier : $error');
    }
  }

  bool _isVocabJson(String name) {
    final lowerName = name.toLowerCase();
    return lowerName.endsWith('.vocab.json') || lowerName.endsWith('.json');
  }

  Future<void> _previewVocabPack(String source) async {
    try {
      final preview = await VocabPackService.readAndPreview(source);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _VocabPackPreviewDialog(preview: preview),
      );
      if (confirmed != true || !mounted) return;
      final importedCount = await VocabPackService.importPack(preview);
      await _load(refreshThemes: true, showLoading: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pack « ${preview.title} » importé ($importedCount entrées).',
            ),
          ),
        );
      }
    } on VocabPackFormatException catch (error) {
      _showError('Fichier invalide : ${error.message}');
    } catch (error) {
      _showError('Impossible d’importer le pack : $error');
    }
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _load(),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 168),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
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
                        style: const TextStyle(
                          color: AppTheme.text,
                          fontSize: 14,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: _allThemes,
                            child: Text('Tous les thèmes'),
                          ),
                          ..._themes.map(
                            (theme) => DropdownMenuItem(
                              value: theme,
                              child: Text(
                                theme,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_words.length} mot${_words.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Importer un fichier vocab-pack',
                    onPressed: _pickVocabPack,
                    icon: const Icon(Icons.file_upload_outlined),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildWordList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter un mot',
        onPressed: () => _editWord(),
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

  Widget _buildWordList() {
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
    if (_words.isEmpty && _readAloud.isEmpty) {
      return Center(
        child: Text(
          'Aucun mot trouvé.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
      itemCount: _words.length + _readAloud.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
      itemBuilder: (context, index) {
        if (index < _readAloud.length) {
          final line = _readAloud[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Lecture à voix haute',
                      style: TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(line['written'] ?? ''),
                Text('FR : ${line['fr'] ?? ''}'),
                Text('EN : ${line['en'] ?? ''}'),
              ],
            ),
          );
        }
        final word = _words[index - _readAloud.length];
        final displayTheme = _selectedTheme == _allThemes
            ? word.theme
            : _selectedTheme;
        final details = [
          if (word.pos != null && word.pos!.isNotEmpty) word.pos!,
          if (word.sense != null && word.sense!.isNotEmpty) word.sense!,
        ].join(' · ');
        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey(word.id),
            onTapDown: (_) {
              _editTimer?.cancel();
              _editTimer = Timer(const Duration(seconds: 1), () {
                if (mounted) _editWord(word);
              });
            },
            onTapUp: (_) => _editTimer?.cancel(),
            onTapCancel: () => _editTimer?.cancel(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.en,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          displayTheme,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (details.isNotEmpty)
                          Text(
                            details,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (word.tags.isNotEmpty)
                          Text(
                            word.tags.join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (word.stress != null && word.stress!.isNotEmpty)
                          Text(
                            'Accent : ${word.stress}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (word.context != null && word.context!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: _contextWithHighlight(
                              word.context!,
                              word.highlight,
                            ),
                          ),
                        if (word.note != null && word.note!.isNotEmpty)
                          Text(
                            word.note!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            word.fr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppTheme.muted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: word.marked
                              ? 'Retirer des mots à revoir'
                              : 'Marquer comme mot difficile',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _toggleMarked(word),
                          icon: Icon(
                            word.marked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: word.marked
                                ? AppTheme.accent
                                : AppTheme.muted,
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Autres actions',
                          onSelected: (action) {
                            if (action == 'delete') _confirmDelete(word);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Supprimer'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _contextWithHighlight(String context, String? highlight) {
    if (highlight == null || highlight.isEmpty) {
      return Text(context, style: const TextStyle(color: AppTheme.muted));
    }
    final start = context.indexOf(highlight);
    if (start < 0) {
      return Text(context, style: const TextStyle(color: AppTheme.muted));
    }
    return Text.rich(
      TextSpan(
        style: const TextStyle(color: AppTheme.muted),
        children: [
          TextSpan(text: context.substring(0, start)),
          TextSpan(
            text: highlight,
            style: const TextStyle(
              color: AppTheme.text,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: context.substring(start + highlight.length)),
        ],
      ),
    );
  }
}

class _VocabPackPreviewDialog extends StatelessWidget {
  const _VocabPackPreviewDialog({required this.preview});

  final VocabPackPreview preview;

  @override
  Widget build(BuildContext context) {
    final themes = (preview.pack['themes'] as List<dynamic>)
        .map((theme) => (theme as Map)['title'] as String)
        .toList();
    return AlertDialog(
      title: Text(preview.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${preview.themeCount} thèmes : ${themes.join(', ')}'),
            const SizedBox(height: 8),
            Text('${preview.newWords} mots nouveaux'),
            Text('${preview.updatedWords} mots à mettre à jour'),
            Text('${preview.identicalWords} mots identiques'),
            Text('${preview.mergedWords} mots fusionnés par terme et sens'),
            if (preview.duplicateWords > 0)
              Text('${preview.duplicateWords} doublons de terme détectés'),
            Text('${preview.grammarCount} point(s) de grammaire'),
            Text('${preview.wordCount} entrée(s) au total'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirmer'),
        ),
      ],
    );
  }
}

class _WordEditorDialog extends StatefulWidget {
  const _WordEditorDialog({required this.themes, this.word});

  final Word? word;
  final List<String> themes;

  @override
  State<_WordEditorDialog> createState() => _WordEditorDialogState();
}

class _WordEditorDialogState extends State<_WordEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _enController;
  late final TextEditingController _frController;
  late final TextEditingController _themeController;
  late final TextEditingController _labelsController;
  late final FocusNode _themeFocusNode;
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    _enController = TextEditingController(text: widget.word?.en ?? '');
    _frController = TextEditingController(text: widget.word?.fr ?? '');
    _themeController = TextEditingController(text: widget.word?.theme ?? '');
    _labelsController = TextEditingController(
      text: widget.word?.tags.join(', ') ?? '',
    );
    _marked = widget.word?.marked ?? false;
    _themeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _enController.dispose();
    _frController.dispose();
    _themeController.dispose();
    _labelsController.dispose();
    _themeFocusNode.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final original = widget.word;
    Navigator.pop(
      context,
      Word(
        id: original?.id,
        en: _enController.text.trim(),
        fr: _frController.text.trim(),
        theme: _themeController.text.trim(),
        ease: original?.ease ?? 2.5,
        interval: original?.interval ?? 0,
        reps: original?.reps ?? 0,
        lapses: original?.lapses ?? 0,
        due: original?.due ?? now,
        created: original?.created ?? now,
        termKey: original?.termKey,
        sense: original?.sense,
        stress: original?.stress,
        pos: original?.pos,
        context: original?.context,
        highlight: original?.highlight,
        note: original?.note,
        tags: _labelsController.text
            .split(',')
            .map((label) => label.trim())
            .where((label) => label.isNotEmpty)
            .toSet()
            .toList(),
        marked: _marked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.word == null ? 'Ajouter un mot' : 'Modifier le mot'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _enController,
                autofocus: true,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(labelText: 'Anglais'),
                validator: _requiredField,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _frController,
                decoration: const InputDecoration(labelText: 'Français'),
                validator: _requiredField,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelsController,
                decoration: const InputDecoration(
                  labelText: 'Labels',
                  hintText: 'difficile, électronique',
                  helperText: 'Sépare les labels par des virgules.',
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mot difficile à revoir'),
                value: _marked,
                onChanged: (value) => setState(() => _marked = value),
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
