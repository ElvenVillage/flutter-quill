import 'dart:convert' show jsonEncode;

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart'
    show QuillSharedExtensionsConfigurations;

import '../../extensions/scaffold_messenger.dart';
import '../../spell_checker/spell_checker.dart';
import '../shared/widgets/home_screen_button.dart';
import 'my_quill_editor.dart';
import 'my_quill_toolbar.dart';

@immutable
class QuillScreenArgs {
  const QuillScreenArgs({required this.document});

  final Document document;
}

class QuillScreen extends StatefulWidget {
  const QuillScreen({
    required this.args,
    super.key,
  });

  final QuillScreenArgs args;

  static const routeName = '/quill';

  @override
  State<QuillScreen> createState() => _QuillScreenState();
}

class _QuillScreenState extends State<QuillScreen> {
  /// Instantiate the controller
  final _controller = QuillController.basic();
  final _editorFocusNode = FocusNode();
  final _editorScrollController = ScrollController();
  var _isReadOnly = false;
  var _isSpellcheckerActive = false;

  late var _activeController = _controller;

  final _toolbarGlobalKey = GlobalKey();
  var _editMode = false;

  @override
  void initState() {
    super.initState();
    _editorFocusNode.addListener(() {
      if (_editorFocusNode.hasPrimaryFocus) {
        setState(() {
          _activeController = _controller;
        });
      }
    });
    _controller.document = widget.args.document;
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.readOnly = _isReadOnly;
    if (!_isSpellcheckerActive) {
      _isSpellcheckerActive = true;
      SpellChecker.useSpellCheckerService(
          Localizations.localeOf(context).languageCode);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Quill'),
        actions: [
          IconButton(
            tooltip: 'Spell-checker',
            onPressed: () {
              SpellCheckerServiceProvider.toggleState();
              setState(() {});
            },
            icon: Icon(
              Icons.document_scanner,
              color: SpellCheckerServiceProvider.isServiceActive()
                  ? Colors.red.withOpacity(0.5)
                  : null,
            ),
          ),
          IconButton(
            tooltip: 'Print to log',
            onPressed: () {
              debugPrint(
                jsonEncode(_controller.document.toDelta().toJson()),
              );
              ScaffoldMessenger.of(context).showText(
                'The quill delta json has been printed to the log.',
              );
            },
            icon: const Icon(Icons.print),
          ),
          const HomeScreenButton(),
        ],
      ),
      body: Column(
        children: [
          if (!_isReadOnly)
            Opacity(
              opacity: !_editMode ? 1.0 : 0.0,
              child: MyQuillToolbar(
                key: _toolbarGlobalKey,
                controller: _activeController,
                focusNode: _editorFocusNode,
              ),
            ),
          Builder(
            builder: (context) {
              return Expanded(
                child: MyQuillEditor(
                  config: const QuillSimpleToolbarConfigurations(),
                  onEditMode: (val) {
                    setState(() {
                      _editMode = val;
                    });
                  },
                  toolbarGlobalKey: _toolbarGlobalKey,
                  controller: _controller,
                  configurations: QuillEditorConfigurations(
                    characterShortcutEvents: standardCharactersShortcutEvents,
                    spaceShortcutEvents: standardSpaceShorcutEvents,
                    searchConfigurations: const QuillSearchConfigurations(
                      searchEmbedMode: SearchEmbedMode.plainText,
                    ),
                    sharedConfigurations: _sharedConfigurations,
                  ),
                  scrollController: _editorScrollController,
                  focusNode: _editorFocusNode,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(!_isReadOnly ? Icons.lock : Icons.edit),
        onPressed: () => setState(() => _isReadOnly = !_isReadOnly),
      ),
    );
  }

  QuillSharedConfigurations get _sharedConfigurations {
    return const QuillSharedConfigurations(
      // locale: Locale('en'),
      extraConfigurations: {
        QuillSharedExtensionsConfigurations.key:
            QuillSharedExtensionsConfigurations(
          assetsPrefix: 'assets', // Defaults to assets
        ),
      },
    );
  }
}
