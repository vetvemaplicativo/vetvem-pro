import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mostrado quando o acesso à câmera/fotos foi negado ao enviar documento.
/// Sem isso, o seletor falhava em silêncio e a pessoa achava que o envio
/// estava quebrado. No iOS abre os Ajustes do app; no Android explica o caminho.
class PermissionHelp {
  static void show(ImageSource source) {
    final isCamera = source == ImageSource.camera;
    final what = isCamera ? 'à câmera' : 'às fotos';
    Get.dialog(
      AlertDialog(
        title: const Text('Precisamos de permissão'),
        content: Text(
          Platform.isIOS
              ? 'O VetVem Pro não tem acesso $what do seu iPhone. '
                  'Toque em "Abrir Ajustes", permita o acesso e volte ao app. '
                  'Se preferir, escolha a outra opção (${isCamera ? 'Galeria' : 'Câmera'}).'
              : 'O VetVem Pro não tem acesso $what do seu celular. '
                  'Vá em Configurações → Apps → VetVem Pro → Permissões e libere '
                  '${isCamera ? 'a Câmera' : 'Fotos e mídia'}. '
                  'Se preferir, escolha a outra opção (${isCamera ? 'Galeria' : 'Câmera'}).',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Agora não')),
          if (Platform.isIOS)
            TextButton(
              onPressed: () async {
                Get.back();
                await launchUrl(Uri.parse('app-settings:'));
              },
              child: const Text('Abrir Ajustes'),
            ),
        ],
      ),
    );
  }
}
