import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_extensions/src/common/utils/quill_table_utils.dart';
import 'package:flutter_quill_extensions/src/editor/table/table_cell_embed.dart';
import 'package:flutter_quill_extensions/src/editor/table/table_models.dart';

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
  @override
  String get key => 'table';

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
      tableData: tableData,
      controller: controller,
      offset: node.documentOffset,
    );
  }
}

class TableWidget extends StatefulWidget {
  const TableWidget({
    required this.tableData,
    required this.controller,
    required this.offset,
    super.key,
  });
  final QuillController controller;
  final Map<String, dynamic> tableData;
  final int offset;

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  TableModel _tableModel = TableModel(columns: {}, rows: {});

  var _removeRowMode = false;
  var _removeColumnMode = false;

  @override
  void initState() {
    _tableModel = TableModel.fromMap(widget.tableData);
    super.initState();
  }

  void _addColumn() {
    setState(() {
      final id = '${_tableModel.columns.length + 1}';
      final position = _tableModel.columns.length;
      _tableModel.columns[id] = ColumnModel(id: id, position: position);
      _tableModel.rows.forEach((key, row) {
        row.cells[id] = '';
      });
    });
    _updateTable();
  }

  void _addRow() {
    setState(() {
      final id = '${_tableModel.rows.length + 1}';
      final cells = <String, String>{};
      _tableModel.columns.forEach((key, column) {
        cells[key] = '';
      });
      _tableModel.rows[id] = RowModel(id: id, cells: cells);
    });
    _updateTable();
  }

  void _removeColumn(String columnId) {
    setState(() {
      if (_tableModel.columns.length > 1) {
        _tableModel.columns.remove(columnId);
        _tableModel.rows.forEach((key, row) {
          row.cells.remove(columnId);
        });
      }

      _removeColumnMode = false;
    });
    _updateTable();
  }

  void _removeRow(String rowId) {
    setState(() {
      if (_tableModel.rows.length > 1) {
        _tableModel.rows.remove(rowId);
      }
      _removeRowMode = false;
    });
    _updateTable();
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
              if (_removeRowMode || _removeColumnMode)
                IconButton(
                    onPressed: () {
                      setState(() {
                        _removeRowMode = false;
                        _removeColumnMode = false;
                      });
                    },
                    icon: const Icon(Icons.cancel))
              else
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () async {
                    final position = renderPosition(context);
                    await showMenu<TableOperation>(
                        context: context,
                        position: position,
                        items: [
                          const PopupMenuItem(
                            value: TableOperation.addColumn,
                            child: Text('Добавить столбец'),
                          ),
                          const PopupMenuItem(
                            value: TableOperation.addRow,
                            child: Text('Добавить строку'),
                          ),
                          const PopupMenuItem(
                            value: TableOperation.removeColumn,
                            child: Text('Удалить столбец'),
                          ),
                          const PopupMenuItem(
                            value: TableOperation.removeRow,
                            child: Text('Удалить строку'),
                          ),
                        ]).then((value) {
                      if (value != null) {
                        if (value == TableOperation.addRow) {
                          _addRow();
                        }
                        if (value == TableOperation.addColumn) {
                          _addColumn();
                        }
                        if (value == TableOperation.removeColumn) {
                          setState(() {
                            _removeColumnMode = true;
                          });
                        }
                        if (value == TableOperation.removeRow) {
                          setState(() {
                            _removeRowMode = true;
                          });
                        }
                      }
                    });
                  },
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
          rowCells.add(TableCellWidget(
            editable: !widget.controller.readOnly,
            cellId: rowKey,
            onTap: () {
              if (_removeColumnMode) {
                _removeColumn(columnId);
                return true;
              }
              if (_removeRowMode) {
                _removeRow(rowId);
                return true;
              }
              return false;
            },
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
