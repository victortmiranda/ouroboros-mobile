import 'package:flutter/material.dart';

class ImportGuideModal extends StatefulWidget {
  final Function(String guideUrl) onImport;

  const ImportGuideModal({
    super.key,
    required this.onImport,
  });

  @override
  State<ImportGuideModal> createState() => _ImportGuideModalState();
}

class _ImportGuideModalState extends State<ImportGuideModal> {
  final _formKey = GlobalKey<FormState>();
  String _guideUrl = '';
  bool _isLoading = false;

  void _handleImport() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      try {
        await widget.onImport(_guideUrl);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Erro já tratado na função onImport
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar Guia do Tec Concursos'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'URL do Guia'),
                keyboardType: TextInputType.url,
                onSaved: (value) => _guideUrl = value ?? '',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a URL do guia.';
                  }
                  if (!(Uri.tryParse(value)?.hasAbsolutePath ?? false)) {
                    return 'URL inválida.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleImport,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Importar'),
        ),
      ],
    );
  }
}
