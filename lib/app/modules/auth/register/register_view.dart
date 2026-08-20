import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../theme/app_theme.dart';
import 'register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Material(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => c.currentStep.value > 0
                          ? c.prevStep()
                          : Get.back(),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Passo ${c.currentStep.value + 1} de ${RegisterController.totalSteps}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                    fontFamily: 'Poppins'),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _stepTitle(c.currentStep.value),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins'),
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (c.currentStep.value + 1) /
                                      RegisterController.totalSteps,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.25),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              switch (c.currentStep.value) {
                case 0: return _Step1(c: c);
                case 1: return _Step2(c: c);
                case 2: return _Step3(c: c);
                case 3: return _Step4(c: c);
                case 4: return _Step5(c: c);
                default: return const SizedBox();
              }
            }),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) => const [
        'Dados pessoais',
        'Dados profissionais',
        'Seus serviços',
        'Disponibilidade',
        'Endereço e documentos',
      ][step];
}

// ─── Step 1 ───────────────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final RegisterController c;
  const _Step1({required this.c});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      onNext: c.nextStep,
      buttonLabel: 'Continuar',
      child: Column(
        children: [
          _Field(ctrl: c.nameCtrl, label: 'Nome completo *',
              hint: 'Seu nome', icon: Icons.person_outline),
          const SizedBox(height: 14),
          _Field(
              ctrl: c.cpfCtrl,
              label: 'CPF *',
              hint: '000.000.000-00',
              icon: Icons.badge_outlined,
              keyboard: TextInputType.number,
              formatters: [_MaskFormatter('999.999.999-99')]),
          const SizedBox(height: 14),
          _Field(ctrl: c.emailCtrl, label: 'E-mail *',
              hint: 'seu@email.com', icon: Icons.email_outlined,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _Field(
              ctrl: c.phoneCtrl,
              label: 'Celular',
              hint: '(21) 9 9999-9999',
              icon: Icons.phone_outlined,
              keyboard: TextInputType.phone,
              formatters: [_MaskFormatter('(99) 9 9999-9999')]),
          const SizedBox(height: 14),
          Obx(() => _Field(
                ctrl: c.passwordCtrl,
                label: 'Senha *',
                hint: 'Mínimo 6 caracteres',
                icon: Icons.lock_outline,
                obscure: c.obscure.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    c.obscure.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textLight, size: 20,
                  ),
                  onPressed: () => c.obscure.toggle(),
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Step 2 — Multi-categoria ─────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final RegisterController c;
  const _Step2({required this.c});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      onNext: c.nextStep,
      buttonLabel: 'Continuar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Categorias * (selecione uma ou mais)'),
          const SizedBox(height: 10),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: c.categories.map((cat) {
                  final sel = c.selectedCategories.contains(cat);
                  return GestureDetector(
                    onTap: () => c.toggleCategory(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel) ...[
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                          ],
                          Text(cat,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : AppColors.textDark)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 8),
          Obx(() => c.selectedCategories.isEmpty
              ? const SizedBox()
              : Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Serviços padrão serão pré-carregados no próximo passo.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                )),
          const SizedBox(height: 20),
          const _SectionLabel('Espécies atendidas * (selecione uma ou mais)'),
          const SizedBox(height: 10),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: c.allSpecies.map((sp) {
                  final (key, emoji, label) = sp;
                  final sel = c.selectedSpecies.contains(key);
                  return GestureDetector(
                    onTap: () => c.toggleSpecies(key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? AppColors.primary : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : AppColors.textDark)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 20),
          _Field(ctrl: c.crmvCtrl,
              label: 'CRMV / Certificação',
              hint: 'Ex: CRMV-RJ 12345 ou Cert. 4456',
              icon: Icons.badge_outlined),
          const SizedBox(height: 14),
          _MultilineField(
              ctrl: c.bioCtrl,
              label: 'Mini bio',
              hint: 'Conte um pouco sobre sua experiência...'),
        ],
      ),
    );
  }
}

// ─── Step 3 — Serviços editáveis ─────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final RegisterController c;
  const _Step3({required this.c});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      onNext: c.nextStep,
      buttonLabel: 'Continuar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (c.services.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Nenhum serviço. Adicione abaixo.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMedium)),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edite os serviços conforme necessário:',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...c.services.asMap().entries.map((e) =>
                    _ServiceEditCard(
                        index: e.key,
                        service: e.value,
                        controller: c)),
              ],
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Adicionar serviço personalizado'),
                const SizedBox(height: 12),
                _Field(ctrl: c.serviceNameCtrl,
                    label: 'Nome do serviço',
                    hint: 'Ex: Consulta domiciliar',
                    icon: Icons.add_circle_outline),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _Field(
                          ctrl: c.servicePriceCtrl,
                          label: 'Preço (R\$)',
                          hint: '0',
                          icon: Icons.attach_money,
                          keyboard: TextInputType.number),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Obx(() => _DropdownField(
                            value: c.serviceUnit.value,
                            items: RegisterController.units,
                            onChanged: (v) =>
                                c.serviceUnit.value = v ?? 'consulta',
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: c.addService,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceEditCard extends StatefulWidget {
  final int index;
  final Map<String, String> service;
  final RegisterController controller;
  const _ServiceEditCard(
      {required this.index,
      required this.service,
      required this.controller});

  @override
  State<_ServiceEditCard> createState() => _ServiceEditCardState();
}

class _ServiceEditCardState extends State<_ServiceEditCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service['name']);
    _priceCtrl = TextEditingController(text: widget.service['price']);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medical_services_outlined,
                color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  onChanged: (v) =>
                      widget.controller.updateServiceName(widget.index, v),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('R\$ ',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        onChanged: (v) =>
                            widget.controller.updateServicePrice(widget.index, v),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('/ ${widget.service['unit'] ?? 'serviço'}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMedium)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 18),
            onPressed: () => widget.controller.removeService(widget.index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Step 4 — Disponibilidade ─────────────────────────────────────────────────

class _Step4 extends StatelessWidget {
  final RegisterController c;
  const _Step4({required this.c});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      onNext: c.nextStep,
      buttonLabel: 'Finalizar cadastro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Dias disponíveis *'),
          const SizedBox(height: 10),
          Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RegisterController.allDays.map((day) {
                  final sel = c.selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () => c.toggleDay(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? AppColors.primary
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Center(
                        child: Text(day,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : AppColors.textDark)),
                      ),
                    ),
                  );
                }).toList(),
              )),
          const SizedBox(height: 24),
          const _SectionLabel('Horários disponíveis *'),
          const SizedBox(height: 10),
          ...RegisterController.periods.map((period) {
            final (label, times) = period;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium)),
                const SizedBox(height: 8),
                Obx(() => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: times.map((t) {
                        final sel = c.availableTimes.contains(t);
                        return GestureDetector(
                          onTap: () => c.toggleTime(t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Text(t,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textDark)),
                          ),
                        );
                      }).toList(),
                    )),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Step 5 — Endereço e documentos ──────────────────────────────────────────

class _Step5 extends StatelessWidget {
  final RegisterController c;
  const _Step5({required this.c});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      onNext: c.nextStep,
      buttonLabel: 'Concluir cadastro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Endereço
          const _SectionLabel('Endereço de atendimento *'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _Field(
                    ctrl: c.cepCtrl,
                    label: 'CEP *',
                    hint: '00000-000',
                    icon: Icons.location_on_outlined,
                    keyboard: TextInputType.number,
                    formatters: [_MaskFormatter('99999-999')]),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _Field(
                    ctrl: c.cityCtrl,
                    label: 'Cidade *',
                    hint: 'Rio de Janeiro',
                    icon: Icons.location_city_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
              ctrl: c.streetCtrl,
              label: 'Logradouro *',
              hint: 'Rua, Avenida...',
              icon: Icons.signpost_outlined),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _Field(
                    ctrl: c.numberCtrl,
                    label: 'Número *',
                    hint: '123',
                    icon: Icons.tag_outlined,
                    keyboard: TextInputType.number),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _Field(
                    ctrl: c.complementCtrl,
                    label: 'Complemento',
                    hint: 'Apto, Sala...',
                    icon: Icons.apartment_outlined),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _Field(
                    ctrl: c.neighborhoodCtrl,
                    label: 'Bairro',
                    hint: 'Centro',
                    icon: Icons.map_outlined),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: _Field(
                    ctrl: c.stateCtrl,
                    label: 'UF',
                    hint: 'RJ',
                    icon: Icons.flag_outlined),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Chave PIX
          const _SectionLabel('Chave PIX para recebimento *'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00B894).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.pix_rounded, color: Color(0xFF00B894), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O app usará esta chave para repassar seus pagamentos em D+2 após cada consulta concluída.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF00695C)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => _DropdownField(
                value: c.pixKeyType.value,
                items: RegisterController.pixKeyTypes,
                onChanged: (v) => c.pixKeyType.value = v ?? 'CPF',
                label: 'Tipo de chave',
              )),
          const SizedBox(height: 10),
          Obx(() => _Field(
                ctrl: c.pixKeyCtrl,
                label: 'Chave PIX',
                hint: c.pixKeyType.value == 'CPF'
                    ? '000.000.000-00'
                    : c.pixKeyType.value == 'CNPJ'
                        ? '00.000.000/0001-00'
                        : c.pixKeyType.value == 'Celular'
                            ? '(21) 9 9999-9999'
                            : c.pixKeyType.value == 'E-mail'
                                ? 'seu@email.com'
                                : 'Chave aleatória',
                icon: Icons.pix_rounded,
                keyboard: c.pixKeyType.value == 'Celular'
                    ? TextInputType.phone
                    : c.pixKeyType.value == 'E-mail'
                        ? TextInputType.emailAddress
                        : TextInputType.text,
              )),

          const SizedBox(height: 28),

          // Documentos
          const _SectionLabel('Documentos'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFD97706), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sua conta ficará pendente até a análise dos documentos (até 24h).',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Obx(() => _DocUploadCard(
                icon: Icons.badge_outlined,
                title: 'Identidade (RG ou CNH)',
                subtitle: 'Foto legível dos dois lados',
                uploaded: c.docIdentityUploaded.value,
                onTap: () => c.simulateUpload('identity'),
              )),
          const SizedBox(height: 10),
          Obx(() => _DocUploadCard(
                icon: Icons.workspace_premium_outlined,
                title: 'CRMV / Certificação',
                subtitle: 'Comprovante do registro profissional',
                uploaded: c.docCrmvUploaded.value,
                onTap: () => c.simulateUpload('crmv'),
              )),
          const SizedBox(height: 8),
          const Text(
            'Você pode enviar os documentos depois pelo seu perfil.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // ─── Termos de Uso ───────────────────────────────────────
          const _SectionLabel('Termos de Uso'),
          const SizedBox(height: 10),
          Container(
            height: 220,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const SingleChildScrollView(
              child: Text(
                _termsPro,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                    height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Obx(() => GestureDetector(
                onTap: () => c.termsAccepted.toggle(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: c.termsAccepted.value,
                        onChanged: (_) => c.termsAccepted.toggle(),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              height: 1.4),
                          children: [
                            const TextSpan(text: 'Li e aceito os '),
                            TextSpan(
                              text: 'Termos de Uso',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => c.termsAccepted.toggle(),
                            ),
                            const TextSpan(text: ' do VetVem Pro.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

const _termsPro = '''TERMOS DE USO — VetVem Pro (Profissional)
Versão 1.0 — Junho de 2026

1. O QUE É O VETVEM PRO

O VetVem Pro é o aplicativo destinado a profissionais autônomos da área veterinária e de cuidados pet que desejam oferecer seus serviços a domicílio por meio da plataforma VetVem.

O VetVem atua exclusivamente como plataforma de intermediação entre você e os tutores de pets. Você não é funcionário, representante nem agente do VetVem. A relação entre você e o tutor é de prestação de serviço autônoma e independente.

2. ACEITAÇÃO DOS TERMOS

Ao criar uma conta no VetVem Pro, você declara que:
• Tem 18 anos ou mais;
• Possui habilitação legal para exercer a atividade profissional declarada no cadastro;
• Se veterinário, possui registro ativo no Conselho Regional de Medicina Veterinária (CRMV);
• Leu, compreendeu e concorda integralmente com estes Termos de Uso.

3. CADASTRO E VERIFICAÇÃO

Para se cadastrar no VetVem Pro, você deve fornecer:
• Nome completo e CPF;
• Número de registro profissional (CRMV ou equivalente);
• Foto de documento com foto;
• Dados bancários para recebimento;
• Localização de atuação e serviços oferecidos.

O VetVem realizará verificação básica dos dados informados, mas a veracidade e validade das informações são de sua exclusiva responsabilidade. O fornecimento de informações falsas implica cancelamento imediato da conta.

4. NATUREZA DA RELAÇÃO COM O VETVEM

Você é um prestador de serviço autônomo e independente. Não existe vínculo empregatício, societário ou de representação entre você e o VetVem.

Você é livre para definir sua agenda, aceitar ou recusar agendamentos e atuar em outras plataformas simultaneamente. O VetVem não garante volume mínimo de agendamentos.

5. RESPONSABILIDADES DO PROFISSIONAL

Você é integralmente responsável por:
• A qualidade técnica, segurança e resultado dos serviços prestados;
• Manter seu registro profissional ativo e regularizado;
• Possuir os equipamentos e condições necessárias para realização dos serviços;
• Cumprir os agendamentos confirmados ou cancelar com antecedência mínima de 24 horas;
• Respeitar a privacidade e os bens do tutor durante o atendimento domiciliar;
• Qualquer dano causado ao animal, ao tutor ou a terceiros durante a prestação do serviço;
• O recolhimento de tributos incidentes sobre sua renda (IRPF, INSS, ISS, quando aplicável).

6. POLÍTICA DE NÃO-DESINTERMEDIAÇÃO

É expressamente proibido:
• Solicitar ou induzir o tutor a realizar pagamentos fora do aplicativo;
• Combinar agendamentos futuros diretamente com tutores conhecidos pelo VetVem;
• Oferecer descontos condicionados ao pagamento externo.

O descumprimento implica suspensão imediata da conta e pode resultar em cobrança de multa contratual.

7. COMISSÕES E PAGAMENTOS

O VetVem retém uma comissão sobre cada serviço concluído e pago pela plataforma, conforme tabela vigente disponível no aplicativo. O repasse ao profissional será realizado em até D+2 dias úteis após a confirmação de conclusão do serviço.

8. LIMITAÇÃO DE RESPONSABILIDADE DO VETVEM

O VetVem não se responsabiliza por:
• Erros ou danos decorrentes dos serviços que você presta;
• Reclamações de tutores relacionadas à qualidade do atendimento;
• Danos causados por você ao animal ou ao domicílio do tutor;
• Sua situação fiscal, tributária ou previdenciária;
• Indisponibilidade temporária do aplicativo.

9. PRONTUÁRIO DIGITAL

Ao registrar informações no prontuário digital do pet após uma consulta concluída, você declara que as informações são verdadeiras e refletem o atendimento realizado. Essas informações ficam vinculadas ao pet na plataforma e podem ser visualizadas pelo tutor.

10. AVALIAÇÕES

Os tutores poderão avaliar seus serviços na plataforma. Avaliações negativas não serão removidas salvo em caso de comprovada má-fé do tutor. Sua nota média impacta sua visibilidade nas buscas do aplicativo.

11. SUSPENSÃO E DESCREDENCIAMENTO

O VetVem pode suspender ou encerrar sua conta em caso de:
• Registro profissional cassado ou suspenso;
• Reiteradas reclamações de tutores;
• Descumprimento da política de não-desintermediação;
• Comportamento abusivo com tutores ou animais;
• Fornecimento de informações falsas no cadastro;
• Violação destes Termos de Uso.

12. ALTERAÇÕES NOS TERMOS

O VetVem pode atualizar estes Termos a qualquer momento, com notificação prévia pelo aplicativo. O uso continuado da plataforma após a notificação implica aceitação dos novos termos.

13. LEGISLAÇÃO APLICÁVEL E FORO

Estes Termos são regidos pelas leis brasileiras. Fica eleito o foro da comarca do Rio de Janeiro/RJ para dirimir quaisquer controvérsias.

14. CONTATO

Para dúvidas ou questões relacionadas a estes Termos: profissionais@vetvem.com.br''';

class _DocUploadCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool uploaded;
  final VoidCallback onTap;
  const _DocUploadCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.uploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: uploaded ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded
                ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: uploaded
                    ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                uploaded ? Icons.check_circle_rounded : icon,
                color: uploaded ? const Color(0xFF22C55E) : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            ),
            uploaded
                ? const Text('Enviado',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF22C55E)))
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Enviar',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers compartilhados ───────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  final Widget child;
  final VoidCallback onNext;
  final String buttonLabel;
  const _StepScaffold(
      {required this.child,
      required this.onNext,
      required this.buttonLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24), child: child)),
        Padding(
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child:
              ElevatedButton(onPressed: onNext, child: Text(buttonLabel)),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMedium));
}

class _MaskFormatter extends TextInputFormatter {
  final String mask;
  _MaskFormatter(this.mask);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final result = StringBuffer();
    var di = 0;
    for (var i = 0; i < mask.length && di < digits.length; i++) {
      if (mask[i] == '9') {
        result.write(digits[di++]);
      } else {
        result.write(mask[i]);
        if (mask[i] == digits[di]) di++;
      }
    }
    final text = result.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final IconData icon;
  final TextInputType keyboard;
  final bool obscure;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? formatters;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                Icon(icon, color: AppColors.textLight, size: 20),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class _MultilineField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  const _MultilineField(
      {required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium)),
        const SizedBox(height: 6),
        TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  final String label;
  const _DropdownField(
      {required this.value,
      required this.items,
      required this.onChanged,
      this.label = 'Unidade'});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMedium)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins'),
              items: items
                  .map((u) =>
                      DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
