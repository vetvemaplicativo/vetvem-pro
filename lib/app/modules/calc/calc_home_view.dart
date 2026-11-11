import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_theme.dart';
import 'calc_widgets.dart';
import 'convert_page.dart';
import 'dilution_page.dart';
import 'dose_page.dart';
import 'volume_page.dart';

/// Tela principal do VetVem Calc (somente app Pro). Ferramentas de apoio matemático:
/// sem medicamentos, sem doses sugeridas, sem dados de pacientes e sem rede.
class CalcHomeView extends StatelessWidget {
  const CalcHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String subtitle, Widget Function() page) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Get.to(page),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.textMedium)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textLight),
                ],
              ),
            ),
          ),
        );

    return CalcScaffold(
      title: 'VetVem Calc',
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(calcEntryDisclaimer, style: TextStyle(fontSize: 12.5, color: AppColors.textDark, height: 1.4)),
        ),
        tile(Icons.monitor_weight_outlined, 'Dose por peso', 'Peso × dose informada, com volume opcional', () => const DosePage()),
        tile(Icons.science_outlined, 'Volume por concentração', 'Quantidade ÷ concentração (mg/mL ou %)', () => const VolumePage()),
        tile(Icons.swap_horiz_rounded, 'Conversão de unidades', 'kg, g, mg, µg, L, mL, mg/mL e %', () => const ConvertPage()),
        tile(Icons.water_drop_outlined, 'Diluição simples', 'C1 × V1 = C2 × V2', () => const DilutionPage()),
      ],
    );
  }
}

/// Cartão de entrada na aba Início.
class CalcEntryCard extends StatelessWidget {
  const CalcEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Get.to(() => const CalcHomeView()),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.calculate_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VetVem Calc', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text('Dose por peso, volume, conversões e diluição', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
