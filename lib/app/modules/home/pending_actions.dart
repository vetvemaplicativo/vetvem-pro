import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'home_controller.dart';

const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _amberDark = Color(0xFFB45309);

/// Pode sugerir outros horários? Só pedidos feitos no app novo do tutor
/// (canChooseTimes), nunca os do portal, e uma vez por pedido.
bool canSuggestTimes(Map<String, String> appt) =>
    appt['canChooseTimes'] == '1' &&
    appt['bookingOrigin'] != 'portal_web' &&
    (appt['proposalStatus'] ?? '').isEmpty;

/// Botões grandes de resposta a um pedido pendente: Aceitar (verde),
/// Sugerir outros horários (amarelo) e Recusar (vermelho). Quando já há
/// sugestões enviadas, mostra o aviso de que o tutor está escolhendo.
class PendingActions extends StatelessWidget {
  final Map<String, String> appt;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onSuggest;
  final bool busy;
  const PendingActions({
    super.key,
    required this.appt,
    required this.onAccept,
    required this.onReject,
    required this.onSuggest,
    this.busy = false,
  });

  String? get _deadlineLabel {
    final ms = int.tryParse(appt['proposalDeadline'] ?? '');
    if (ms == null) return null;
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} às ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (appt['proposalStatus'] == 'awaiting_tutor') {
      final until = _deadlineLabel;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_send_rounded, color: _amberDark, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Você sugeriu outros horários. Aguardando o tutor escolher'
                '${until != null ? ' (até $until)' : ''}.',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _amberDark),
              ),
            ),
          ],
        ),
      );
    }

    final suggest = canSuggestTimes(appt);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: busy ? null : onAccept,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded, size: 24),
            label: Text(busy ? 'Aceitando...' : 'Aceitar',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (suggest) ...[
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : onSuggest,
                    icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                    label: const Text('Sugerir horários',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amber,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.close_rounded, size: 22),
                  label: const Text('Recusar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Abre a tela de sugestão de até 3 horários. Retorna true se enviou.
Future<bool> showSuggestTimes(BuildContext context, Map<String, String> appt) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SuggestTimesSheet(appt: appt),
  );
  return sent == true;
}

class _Slot {
  DateTime? date;
  TimeOfDay? time;
  DateTime? get at => date == null || time == null
      ? null
      : DateTime(date!.year, date!.month, date!.day, time!.hour, time!.minute);
}

class _SuggestTimesSheet extends StatefulWidget {
  final Map<String, String> appt;
  const _SuggestTimesSheet({required this.appt});

  @override
  State<_SuggestTimesSheet> createState() => _SuggestTimesSheetState();
}

class _SuggestTimesSheetState extends State<_SuggestTimesSheet> {
  final List<_Slot> _slots = [_Slot()];
  bool _sending = false;
  String? _error;

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';
  static String _fmtTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  // Mesmas regras do servidor (para o aviso aparecer na hora, sem ida e volta).
  String? _validate() {
    final now = DateTime.now();
    final seen = <String>{};
    for (final s in _slots) {
      final at = s.at;
      if (at == null) return 'Preencha a data e o horário de todas as opções.';
      if (at.isBefore(now.add(const Duration(hours: 3)))) {
        return 'Sugira horários com pelo menos 3 horas de antecedência.';
      }
      final key = '${_fmtDate(at)} ${_fmtTime(s.time!)}';
      if (!seen.add(key)) return 'Há horários repetidos.';
      if (key == '${widget.appt['date']} ${widget.appt['time']}') {
        return 'Uma das opções é o mesmo horário que o tutor pediu.';
      }
    }
    return null;
  }

  Future<void> _pickDate(_Slot s) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: s.date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (d != null) setState(() => s.date = d);
  }

  Future<void> _pickTime(_Slot s) async {
    final t = await showTimePicker(
      context: context,
      initialTime: s.time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null) setState(() => s.time = t);
  }

  Future<void> _send() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final ctrl = Get.find<HomeController>();
    final msg = await ctrl.proposeNewTimes(widget.appt['id']!, [
      for (final s in _slots) {'date': _fmtDate(s.date!), 'time': _fmtTime(s.time!)}
    ]);
    if (!mounted) return;
    if (msg == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _sending = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, 20 + MediaQuery.of(context).padding.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sugerir outros horários',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'O tutor pediu ${widget.appt['date']} às ${widget.appt['time']}. '
                'Escolha até 3 opções com pelo menos 3 horas de antecedência. '
                'O tutor escolhe uma e a consulta fica confirmada. Se nenhuma servir, o valor é devolvido.',
                style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.textMedium),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _slots.length; i++) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(_slots[i]),
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(_slots[i].date == null
                            ? 'Data ${i + 1}'
                            : _fmtDate(_slots[i].date!)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(_slots[i]),
                        icon: const Icon(Icons.access_time_rounded, size: 18),
                        label: Text(_slots[i].time == null
                            ? 'Hora'
                            : _fmtTime(_slots[i].time!)),
                      ),
                    ),
                    if (_slots.length > 1)
                      IconButton(
                        onPressed: () => setState(() => _slots.removeAt(i)),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMedium),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (_slots.length < 3)
                TextButton.icon(
                  onPressed: () => setState(() => _slots.add(_Slot())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar outro horário'),
                ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sending ? null : _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amber,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_sending ? 'Enviando...' : 'Enviar sugestões',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
