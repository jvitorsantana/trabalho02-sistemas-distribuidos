import 'package:flutter/material.dart';

/// Valores retornados pelo diálogo de configuração.
class ServerSettings {
  final String host;
  final int port;

  const ServerSettings({
    required this.host,
    required this.port,
  });
}

/// Diálogo para alterar o IP e a porta do servidor.
///
/// É um [StatefulWidget] de propósito: os [TextEditingController]
/// precisam viver enquanto o diálogo estiver na árvore de widgets.
///
/// O Future do showDialog completa assim que o Navigator.pop é
/// chamado, ou seja, antes da animação de saída terminar. Se os
/// controllers fossem descartados logo após o await, os campos
/// ainda montados usariam um controller já destruído.
class ServerSettingsDialog extends StatefulWidget {
  final String initialHost;
  final int initialPort;

  const ServerSettingsDialog({
    super.key,
    required this.initialHost,
    required this.initialPort,
  });

  @override
  State<ServerSettingsDialog> createState() =>
      _ServerSettingsDialogState();
}

class _ServerSettingsDialogState
    extends State<ServerSettingsDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();

    _hostController = TextEditingController(
      text: widget.initialHost,
    );

    _portController = TextEditingController(
      text: widget.initialPort.toString(),
    );
  }

  @override
  void dispose() {
    // Executado apenas quando o diálogo sai da árvore.
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      ServerSettings(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuração do servidor'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'IP do servidor',
                  hintText: 'Ex.: 192.168.1.100',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o IP ou endereço.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Porta',
                  hintText: 'Ex.: 25565',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                validator: (value) {
                  final port = int.tryParse(
                    (value ?? '').trim(),
                  );

                  if (port == null) {
                    return 'Informe uma porta válida.';
                  }

                  if (port < 1 || port > 65535) {
                    return 'A porta deve estar entre 1 e 65535.';
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
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
