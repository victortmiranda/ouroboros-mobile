import 'package:flutter/material.dart';

class ConfirmationModal extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onClose;
  final String confirmText;
  final String cancelText;

  const ConfirmationModal({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    required this.onClose,
    this.confirmText = 'Confirmar',
    this.cancelText = 'Cancelar',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: onClose,
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
