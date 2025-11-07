import 'package:flutter/material.dart';

class ImportSubjectModal extends StatefulWidget {
  final Function(String) onImport;

  const ImportSubjectModal({super.key, required this.onImport});

  @override
  State<ImportSubjectModal> createState() => _ImportSubjectModalState();
}

class _ImportSubjectModalState extends State<ImportSubjectModal> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar Matéria do TEC Concursos'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'URL da Matéria',
          hintText: 'https://www.tecconcursos.com.br/...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onImport(_controller.text);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
