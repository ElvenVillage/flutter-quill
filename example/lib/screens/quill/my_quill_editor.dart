import 'dart:io' as io show Directory, File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
// ignore: implementation_imports

import 'package:path/path.dart' as path;

import 'embeds/timestamp_embed.dart';

class MyQuillEditor extends StatefulWidget {
  const MyQuillEditor({
    required this.controller,
    required this.configurations,
    required this.scrollController,
    required this.focusNode,
    required this.toolbarGlobalKey,
    required this.onEditMode,
    required this.config,
    super.key,
  });

  final QuillController controller;
  final QuillEditorConfigurations configurations;
  final ScrollController scrollController;
  final FocusNode focusNode;
  final GlobalKey toolbarGlobalKey;
  final void Function(bool editMode) onEditMode;
  final QuillSimpleToolbarConfigurations config;

  @override
  State<MyQuillEditor> createState() => _MyQuillEditorState();
}

class _MyQuillEditorState extends State<MyQuillEditor> {
  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = DefaultTextStyle.of(context);
    return QuillEditor(
      scrollController: widget.scrollController,
      focusNode: widget.focusNode,
      controller: widget.controller,
      configurations: widget.configurations.copyWith(
        readOnly: true,
        elementOptions: const QuillEditorElementOptions(
          codeBlock: QuillEditorCodeBlockElementOptions(
            enableLineNumbers: true,
          ),
          orderedList: QuillEditorOrderedListElementOptions(),
          unorderedList: QuillEditorUnOrderedListElementOptions(
            useTextColorForDot: true,
          ),
        ),
        customStyles: DefaultStyles(
          h1: DefaultTextBlockStyle(
            defaultTextStyle.style.copyWith(
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w300,
            ),
            HorizontalSpacing.zero,
            const VerticalSpacing(16, 0),
            VerticalSpacing.zero,
            null,
          ),
          sizeSmall: defaultTextStyle.style.copyWith(fontSize: 9),
        ),
        scrollable: true,
        checkBoxReadOnly: true,
        placeholder: 'Start writing your notes...',
        padding: const EdgeInsets.all(16),
        onImagePaste: (imageBytes) async {
          if (kIsWeb) {
            return null;
          }
          // We will save it to system temporary files
          final newFileName =
              'imageFile-${DateTime.now().toIso8601String()}.png';
          final newPath = path.join(
            io.Directory.systemTemp.path,
            newFileName,
          );
          final file = await io.File(
            newPath,
          ).writeAsBytes(imageBytes, flush: true);
          return file.path;
        },
        onGifPaste: (gifBytes) async {
          if (kIsWeb) {
            return null;
          }
          // We will save it to system temporary files
          final newFileName = 'gifFile-${DateTime.now().toIso8601String()}.gif';
          final newPath = path.join(
            io.Directory.systemTemp.path,
            newFileName,
          );
          final file = await io.File(
            newPath,
          ).writeAsBytes(gifBytes, flush: true);
          return file.path;
        },
        embedBuilders: [
          QuillEditorTableEmbedBuilder(
              config: widget.config,
              toolbarGlobalKey: widget.toolbarGlobalKey,
              onEditMode: widget.onEditMode),
          TimeStampEmbedBuilderWidget(),
        ],
        builder: (context, rawEditor) {
          // The `desktop_drop` plugin doesn't support iOS platform for now

          return rawEditor;
        },
      ),
    );
  }
}
