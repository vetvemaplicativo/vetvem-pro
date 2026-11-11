import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import 'calc_engine.dart';

const calcEntryDisclaimer =
    'O VetVem Calc é uma ferramenta de apoio matemático para médicos-veterinários. Não fornece diagnóstico, '
    'prescrição, posologia ou protocolo terapêutico. Todos os parâmetros devem ser definidos e conferidos pelo profissional.';

const calcResultDisclaimer =
    'Cálculo matemático baseado exclusivamente nos valores informados. Confira os parâmetros antes do uso clínico.';

/// Página padrão das calculadoras: título, formulário rolável.
class CalcScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const CalcScaffold({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: children,
        ),
      ),
    );
  }
}

/// Campo numérico com a unidade SEMPRE visível ao lado (seletor), nunca só como placeholder.
class CalcField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<CalcUnit> units;
  final CalcUnit unit;
  final ValueChanged<CalcUnit> onUnit;
  final String? hint;
  final bool optional;
  const CalcField({
    super.key,
    required this.label,
    required this.controller,
    required this.units,
    required this.unit,
    required this.onUnit,
    this.hint,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(optional ? '$label (opcional)' : label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: label,
                  textField: true,
                  child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CalcUnit>(
                    value: unit,
                    items: [
                      for (final u in units)
                        DropdownMenuItem(value: u, child: Text(u.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                    ],
                    onChanged: (u) {
                      if (u != null) onUnit(u);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mensagem de erro de validação, em texto (não depende só de cor).
class CalcErrorBox extends StatelessWidget {
  final String message;
  const CalcErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Atenção: $message', style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
        ],
      ),
    );
  }
}

/// Resultado em destaque + passos usados no cálculo + aviso.
class CalcResultBox extends StatelessWidget {
  final String headline; // ex.: "2 mL"
  final String headlineLabel; // ex.: "Volume calculado"
  final String? alsoAs;
  final List<String> steps;
  const CalcResultBox({
    super.key,
    required this.headline,
    required this.headlineLabel,
    this.alsoAs,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headlineLabel, style: const TextStyle(fontSize: 12, color: AppColors.textMedium, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Semantics(
            label: '$headlineLabel: $headline',
            child: Text(headline, key: const Key('calc_result'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
          if (alsoAs != null) ...[
            const SizedBox(height: 2),
            Text('= $alsoAs', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          for (final s in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(s, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            ),
          const SizedBox(height: 8),
          const Text(calcResultDisclaimer, style: TextStyle(fontSize: 11.5, color: AppColors.textMedium, height: 1.35)),
        ],
      ),
    );
  }
}

class CalcActions extends StatelessWidget {
  final VoidCallback onCalculate;
  final VoidCallback onClear;
  final String calculateLabel;
  const CalcActions({super.key, required this.onCalculate, required this.onClear, this.calculateLabel = 'Calcular'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: onCalculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(calculateLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(96, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}
