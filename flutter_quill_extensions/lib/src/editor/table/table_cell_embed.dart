import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class _FormattedTextViewer extends StatefulWidget {
  const _FormattedTextViewer({
    required this.readOnly,
    required this.quillText,
    required this.dropRootFocus,
    required this.onChange,
    this.setActiveController,
    super.key,
  });

  final bool readOnly;
  final String quillText;
  final void Function() dropRootFocus;
  final void Function(String delta) onChange;
  final void Function(QuillController controller)? setActiveController;

  static Document documentFromText(String questionText) {
    Document document;
    try {
      document = Document.fromJson(jsonDecode(questionText) as List);
    } on FormatException {
      // текст не был сохранен как Quill delta
      // ==> создаем сами из plain text
      // ignore: prefer_interpolation_to_compose_strings
      final deltaJson = jsonDecode('{"insert":"' +
          questionText
              .replaceAll('\n', '')
              .replaceAll('\r', '')
              .replaceAll('	', '')
              .replaceAll('"', r'\"') +
          r'\n"}');
      document = Document.fromJson([deltaJson]);
    }

    return document;
  }

  @override
  State<_FormattedTextViewer> createState() => _FormattedTextViewerState();
}

class _FormattedTextViewerState extends State<_FormattedTextViewer> {
  late final _controller = QuillController.basic()..readOnly = widget.readOnly;
  final _focusNode = FocusNode();

  @override
  void initState() {
    _controller.document =
        _FormattedTextViewer.documentFromText(widget.quillText);
    if (!widget.readOnly) {
      _controller.addListener(() {
        widget.onChange(jsonEncode(_controller.document.toDelta().toJson()));
      });

      if (widget.setActiveController != null) {
        widget.setActiveController!(_controller);
      }
    }

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor.basic(
      controller: _controller,
      focusNode: _focusNode,
      configurations: QuillEditorConfigurations(
        showCursor: !widget.readOnly,
        enableInteractiveSelection: !widget.readOnly,
      ),
    );
  }
}

class TableCellWidget extends StatefulWidget {
  const TableCellWidget({
    required this.cellId,
    required this.cellData,
    required this.onUpdate,
    required this.onTap,
    required this.editable,
    required this.toolbarGlobalKey,
    required this.onEditMode,
    required this.config,
    required this.customToolbar,
    required this.customToolbarKey,
    super.key,
  });

  final bool editable;
  final String cellId;
  final String cellData;
  final bool Function() onTap;
  final void Function(String data) onUpdate;
  final GlobalKey? toolbarGlobalKey;
  final GlobalKey? customToolbarKey;
  final Widget? customToolbar;
  final void Function(bool editMode)? onEditMode;
  final QuillSimpleToolbarConfigurations? config;

  @override
  State<TableCellWidget> createState() => _TableCellWidgetState();
}

class _TableCellWidgetState extends State<TableCellWidget> {
  final _cellKey = GlobalKey();
  var _editMode = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onEditMode == null
          ? null
          : () async {
              setState(() {
                _editMode = true;
              });

              widget.onEditMode!(true);

              final cellRenderBox =
                  _cellKey.currentContext?.findRenderObject() as RenderBox;
              final cellOffset = cellRenderBox.localToGlobal(Offset.zero);
              final cellSize = cellRenderBox.size;

              final toolbarRenderBox = widget.toolbarGlobalKey!.currentContext
                  ?.findRenderObject() as RenderBox;
              final toolbarOffset = toolbarRenderBox.localToGlobal(Offset.zero);

              final templatesRenderBox = widget.customToolbarKey!.currentContext
                  ?.findRenderObject() as RenderBox;
              final customToolbarOffset =
                  templatesRenderBox.localToGlobal(Offset.zero);

              QuillController? activeController;

              await showDialog(
                  barrierColor: Colors.transparent,
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(builder: (context, setState) {
                      return Stack(
                        children: [
                          if (activeController != null) ...[
                            Positioned(
                                top: toolbarOffset.dy,
                                left: toolbarOffset.dx,
                                child: QuillSimpleToolbar(
                                  configurations: widget.config,
                                  controller: activeController,
                                )),
                            if (widget.customToolbar != null)
                              Positioned(
                                top: customToolbarOffset.dy,
                                left: customToolbarOffset.dx,
                                child: widget.customToolbar!,
                              ),
                          ],
                          Positioned(
                            top: cellOffset.dy,
                            left: cellOffset.dx,
                            child: SizedBox(
                              width: cellSize.width,
                              height: cellSize.height,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: _FormattedTextViewer(
                                    readOnly: false,
                                    quillText: widget.cellData,
                                    setActiveController: (controller) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        setState(() {
                                          activeController = controller;
                                        });
                                      });
                                    },
                                    dropRootFocus: () {},
                                    onChange: (val) {
                                      setState(() {
                                        widget.onUpdate(val);
                                      });
                                    }),
                              ),
                            ),
                          )
                        ],
                      );
                    });
                  });

              setState(() {
                _editMode = false;
              });

              widget.onEditMode!(false);
            },
      child: _editMode
          ? const SizedBox.shrink()
          : Container(
              key: _cellKey,
              width: 40,
              constraints: const BoxConstraints(
                minHeight: 50,
              ),
              padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
              child: _FormattedTextViewer(
                readOnly: true,
                quillText: widget.cellData,
                key: Key(widget.cellData),
                dropRootFocus: widget.onTap,
                onChange: (_) {},
              )),
    );
  }
}
