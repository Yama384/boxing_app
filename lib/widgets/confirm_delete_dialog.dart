import 'package:flutter/material.dart';
import '../app_strings.dart';

Future<bool> confirmDelete(BuildContext context, AppStrings s) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(s('confirmDeleteTitle')),
        content: Text(s('confirmDeleteMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(s('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(s('delete')),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
