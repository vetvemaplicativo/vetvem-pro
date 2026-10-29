import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

/// Máximo de arquivos por prontuário/complemento e tamanho de cada um (as regras do Storage
/// também limitam a 10 MB e só aceitam imagem ou PDF).
const kMaxAnexos = 5;
const kMaxAnexoBytes = 10 * 1024 * 1024;

/// Anexos (fotos e PDFs) de um prontuário ou complemento. Os arquivos sobem para o Firebase
/// Storage em prontuarios/{id da consulta}/...; cada item da lista [items] é
/// {name, path, type, size}, que vai para o documento da consulta quando o veterinário salva.
class AttachmentsField extends StatefulWidget {
  final String apptId;
  final List<Map<String, dynamic>> items;
  final VoidCallback onChanged;
  final ValueChanged<bool> onBusyChanged;

  const AttachmentsField({
    super.key,
    required this.apptId,
    required this.items,
    required this.onChanged,
    required this.onBusyChanged,
  });

  @override
  State<AttachmentsField> createState() => _AttachmentsFieldState();
}

class _AttachmentsFieldState extends State<AttachmentsField> {
  int _uploading = 0;
  String? _tutorId;
  String? _error;
  // Arquivos enviados nesta tela: só estes são apagados do Storage ao remover (os que já estavam
  // salvos no prontuário continuam lá até o veterinário salvar a edição).
  final _sessionPaths = <String>{};

  bool get _full => widget.items.length + _uploading >= kMaxAnexos;

  String _safeName(String raw) =>
      raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_').replaceAll(RegExp(r'_+'), '_');

  String _typeOf(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.webp')) return 'image/webp';
    if (n.endsWith('.heic') || n.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> _pickImage(ImageSource source) async {
    final x = await ImagePicker().pickImage(source: source, maxWidth: 2200, imageQuality: 85);
    if (x == null) return;
    await _upload(File(x.path), x.name);
  }

  Future<void> _pickPdf() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    final f = r?.files.single;
    if (f == null || f.path == null) return;
    await _upload(File(f.path!), f.name);
  }

  Future<void> _upload(File file, String name) async {
    if (_full) return;
    final size = await file.length();
    if (size >= kMaxAnexoBytes) {
      setState(() => _error = 'O arquivo passa de 10 MB. Escolha um menor.');
      return;
    }
    setState(() {
      _uploading++;
      _error = null;
    });
    widget.onBusyChanged(true);
    try {
      final type = _typeOf(name);
      final vetUid = FirebaseAuth.instance.currentUser!.uid;
      // O uid do tutor vai gravado no arquivo: é ele que as regras do Storage usam para liberar a leitura.
      _tutorId ??= ((await FirebaseFirestore.instance.collection('appointments').doc(widget.apptId).get())
              .data()?['tutorId'] as String?) ??
          '';
      final ref = FirebaseStorage.instance.ref(
          'prontuarios/$vetUid/${widget.apptId}/${DateTime.now().millisecondsSinceEpoch}_${_safeName(name)}');
      await ref.putFile(
          file, SettableMetadata(contentType: type, customMetadata: {'tutorId': _tutorId!}));
      _sessionPaths.add(ref.fullPath);
      widget.items.add({'name': name, 'path': ref.fullPath, 'type': type, 'size': size});
      widget.onChanged();
    } catch (_) {
      if (mounted) setState(() => _error = 'Não foi possível enviar o arquivo. Tente de novo.');
    } finally {
      if (mounted) setState(() => _uploading--);
      widget.onBusyChanged(_uploading > 0);
    }
  }

  Future<void> _remove(int i) async {
    final item = widget.items[i];
    widget.items.removeAt(i);
    widget.onChanged();
    final path = item['path'] as String?;
    if (path != null && _sessionPaths.remove(path)) {
      try {
        await FirebaseStorage.instance.ref(path).delete();
      } catch (_) {/* sem problema: fica sem referência */}
    }
  }

  void _chooser() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar foto'),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Arquivo PDF'),
            onTap: () {
              Navigator.pop(ctx);
              _pickPdf();
            },
          ),
        ]),
      ),
    );
  }

  String _sizeLabel(int bytes) => bytes >= 1024 * 1024
      ? '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB'
      : '${(bytes / 1024).ceil()} KB';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(children: [
              Icon(
                (widget.items[i]['type'] as String? ?? '') == 'application/pdf'
                    ? Icons.picture_as_pdf_outlined
                    : Icons.image_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.items[i]['name']?.toString() ?? 'arquivo',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(_sizeLabel((widget.items[i]['size'] as num?)?.toInt() ?? 0),
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Remover',
                onPressed: () => _remove(i),
              ),
            ]),
          ),
        if (_uploading > 0)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Enviando arquivo…', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
            ]),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
          ),
        OutlinedButton.icon(
          onPressed: _full ? null : _chooser,
          icon: const Icon(Icons.attach_file, size: 18),
          label: Text(_full
              ? 'Limite de $kMaxAnexos arquivos'
              : 'Anexar foto ou PDF (${widget.items.length}/$kMaxAnexos)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

/// Abre um anexo já salvo (imagem ou PDF) no visualizador do celular.
Future<void> openAnexo(BuildContext context, Map<String, dynamic> item) async {
  try {
    final url = await FirebaseStorage.instance.ref(item['path'] as String).getDownloadURL();
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) throw Exception('sem app para abrir');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o anexo agora.')));
    }
  }
}

/// Lista de anexos (somente leitura): toque para abrir.
class AnexosLinks extends StatelessWidget {
  final List<dynamic> items;
  const AnexosLinks({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final list = items.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final it in list)
          ActionChip(
            avatar: Icon(
              (it['type'] as String? ?? '') == 'application/pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(it['name']?.toString() ?? 'arquivo',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ),
            onPressed: () => openAnexo(context, it),
          ),
      ],
    );
  }
}
