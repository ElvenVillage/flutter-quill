import 'package:flutter/material.dart';

class TableCellWidget extends StatelessWidget {
  const TableCellWidget({
    required this.cellId,
    required this.cellData,
    required this.onUpdate,
    required this.onTap,
    required this.editable,
    super.key,
  });

  final bool editable;
  final String cellId;
  final String cellData;
  final void Function(FocusNode node) onTap;
  final void Function(String data) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      constraints: const BoxConstraints(
        minHeight: 50,
      ),
      padding: const EdgeInsets.only(left: 5, right: 5, top: 5),
      child: InkWell(
          onTap: editable
              ? () async {
                  final controller = TextEditingController(text: cellData);
                  await showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: TextField(
                            controller: controller,
                          ),
                        );
                      });
                  onUpdate(controller.text);
                  controller.dispose();
                }
              : null,
          child: Center(
              child: Text(
            cellData,
          ))),
    );
  }
}
