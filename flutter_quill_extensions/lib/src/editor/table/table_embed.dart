import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../../common/utils/quill_table_utils.dart';
import 'table_cell_embed.dart';
import 'table_models.dart';

class CustomTableEmbed extends CustomBlockEmbed {
  const CustomTableEmbed(String value) : super(tableType, value);

  static const String tableType = 'table';

  static CustomTableEmbed fromDocument(Document document) =>
      CustomTableEmbed(jsonEncode(document.toDelta().toJson()));

  Document get document =>
      Document.fromJson(jsonDecode(data as String) as List);
}

//Embed builder

class QuillEditorTableEmbedBuilder extends EmbedBuilder {
  QuillEditorTableEmbedBuilder({
    this.toolbarGlobalKey,
    this.onEditMode,
    this.config,
    this.customToolbar,
    this.customToolbarKey,
  });

  final GlobalKey? toolbarGlobalKey;
  final void Function(bool editMode)? onEditMode;
  final QuillSimpleToolbarConfigurations? config;
  final GlobalKey? customToolbarKey;
  final Widget Function(QuillController)? customToolbar;

  @override
  String get key => 'table';

  @override
  String toPlainText(Embed node) {
    final tableData = node.value.data;
    final tableModel = TableModel.fromMap(tableData);

    return tableModel.rows.values
        .map((v) => v.cells.values.join('  '))
        .join('\n');
  }

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final tableData = node.value.data;

    return TableWidget(
      config: config,
      onEditMode: onEditMode,
      toolbarGlobalKey: toolbarGlobalKey,
      tableData: tableData,
      controller: controller,
      offset: node.documentOffset,
      customToolbar: customToolbar,
      customToolbarKey: customToolbarKey,
    );
  }
}

class TableWidget extends StatefulWidget {
  const TableWidget({
    required this.tableData,
    required this.controller,
    required this.offset,
    required this.toolbarGlobalKey,
    required this.onEditMode,
    required this.config,
    required this.customToolbar,
    required this.customToolbarKey,
    super.key,
  });

  final QuillController controller;
  final Map<String, dynamic> tableData;
  final int offset;
  final GlobalKey? toolbarGlobalKey;
  final void Function(bool mode)? onEditMode;
  final QuillSimpleToolbarConfigurations? config;
  final GlobalKey? customToolbarKey;
  final Widget Function(QuillController)? customToolbar;

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  TableModel _tableModel = TableModel(columns: {}, rows: {});

  static const _newId = '';

  @override
  void initState() {
    _tableModel = TableModel.fromMap(widget.tableData);
    super.initState();
  }

  void _rebuild(List<String> columnIds, List<String> rowIds) {
    final columns = <String, ColumnModel>{};
    for (var column = 0; column < columnIds.length; column++) {
      final id = '${column + 1}';
      columns[id] = ColumnModel(id: id, position: column);
    }

    final rows = <String, RowModel>{};
    for (var row = 0; row < rowIds.length; row++) {
      final id = '${row + 1}';
      final oldCells = _tableModel.rows[rowIds[row]]?.cells;
      rows[id] = RowModel(
        id: id,
        cells: {
          for (var column = 0; column < columnIds.length; column++)
            '${column + 1}': oldCells?[columnIds[column]] ?? '',
        },
      );
    }

    setState(() {
      _tableModel = TableModel(columns: columns, rows: rows);
    });
    _updateTable();
  }

  List<String> get _columnIds => _tableModel.columns.keys.toList();
  List<String> get _rowIds => _tableModel.rows.keys.toList();

  void _addColumnAfter(String columnId) {
    final columns = _columnIds;
    columns.insert(columns.indexOf(columnId) + 1, _newId);
    _rebuild(columns, _rowIds);
  }

  void _addRowAfter(String rowId) {
    final rows = _rowIds;
    rows.insert(rows.indexOf(rowId) + 1, _newId);
    _rebuild(_columnIds, rows);
  }

  void _removeColumn(String columnId) {
    if (_tableModel.columns.length <= 1) return;
    _rebuild(_columnIds..remove(columnId), _rowIds);
  }

  void _removeRow(String rowId) {
    if (_tableModel.rows.length <= 1) return;
    _rebuild(_columnIds, _rowIds..remove(rowId));
  }

  void _removeTable() {
    widget.controller.moveCursorToPosition(widget.offset);
    final offset = getEmbedNode(
      widget.controller,
      widget.controller.selection.start,
    ).offset;
    widget.controller.replaceText(
      offset,
      1,
      '',
      TextSelection.collapsed(offset: offset),
    );
  }

  void _updateCell(String columnId, String rowId, String data) {
    setState(() {
      _tableModel.rows[rowId]!.cells[columnId] = data;
    });
    _updateTable();
  }

  void _updateTable() {
    widget.controller.moveCursorToPosition(widget.offset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final offset = getEmbedNode(
        widget.controller,
        widget.controller.selection.start,
      ).offset;
      final delta = Delta()..insert({'table': _tableModel.toMap()});
      widget.controller.replaceText(
        offset,
        1,
        delta,
        TextSelection.collapsed(
          offset: offset,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
                color: Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.black)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.controller.readOnly) ...[
              Builder(
                builder: (buttonContext) => IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Действия с таблицей',
                  onPressed: () async {
                    final remove = await showMenu<bool>(
                      context: buttonContext,
                      position: menuPositionUnder(buttonContext),
                      items: const [
                        PopupMenuItem(
                          value: true,
                          child: Text('Удалить таблицу'),
                        ),
                      ],
                    );
                    if (remove ?? false) _removeTable();
                  },
                ),
              ),
              const Divider(
                color: Colors.black,
                height: 1,
              )
            ],
            Table(
              border: const TableBorder.symmetric(inside: BorderSide()),
              children: _buildTableRows(),
            ),
          ],
        ),
      ),
    );
  }

  List<TableRow> _buildTableRows() {
    final rows = <TableRow>[];

    _tableModel.rows.forEach((rowId, rowModel) {
      final rowCells = <Widget>[];
      final rowKey = rowId;
      rowModel.cells.forEach((key, value) {
        if (key != 'id') {
          final columnId = key;
          final data = value;
          final editable = !widget.controller.readOnly;

          rowCells.add(TableCellWidget(
            customToolbar: widget.customToolbar,
            customToolbarKey: widget.customToolbarKey,
            config: widget.config,
            onEditMode: widget.onEditMode,
            toolbarGlobalKey: widget.toolbarGlobalKey,
            editable: editable,
            cellId: rowKey,
            onAddRowAfter: editable ? () => _addRowAfter(rowId) : null,
            onAddColumnAfter: editable ? () => _addColumnAfter(columnId) : null,
            onRemoveRow: editable && _tableModel.rows.length > 1
                ? () => _removeRow(rowId)
                : null,
            onRemoveColumn: editable && _tableModel.columns.length > 1
                ? () => _removeColumn(columnId)
                : null,
            cellData: data,
            onUpdate: (data) {
              _updateCell(columnId, rowKey, data);
            },
          ));
        }
      });
      rows.add(TableRow(
          children: rowCells, decoration: BoxDecoration(border: Border.all())));
    });
    return rows;
  }
}
