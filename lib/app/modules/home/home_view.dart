import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../terms/terms_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';
import '../../services/taxonomy_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shimmer.dart';
import '../auth/register/register_controller.dart' show RegisterController;
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        switch (controller.currentTab.value) {
          case 0: return const _InicioTab();
          case 1: return const _AgendaTab();
          case 2: return const _ServicosTab();
          case 3: return const _FinanceiroTab();
          case 4: return const _PerfilTab();
          default: return const _InicioTab();
        }
      }),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.currentTab.value,
            onTap: controller.changeTab,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            selectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                const TextStyle(fontFamily: 'Poppins', fontSize: 10),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_rounded),
                  label: 'Início'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month_outlined),
                  activeIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Agenda'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.medical_services_outlined),
                  activeIcon: Icon(Icons.medical_services_rounded),
                  label: 'Serviços'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Financeiro'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline_rounded),
                  activeIcon: Icon(Icons.person_rounded),
                  label: 'Perfil'),
            ],
          )),
    );
  }
}

// ─── Aba Início ───────────────────────────────────────────────────────────────

class _InicioTab extends GetView<HomeController> {
  const _InicioTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Obx(() {
                          final photoUrl = controller.professionalPhotoUrl.value;
                          if (photoUrl.isNotEmpty) {
                            return CircleAvatar(
                              radius: 30,
                              backgroundImage: photoUrl.startsWith('data:image')
                                  ? MemoryImage(base64Decode(photoUrl.split(',').last))
                                  : NetworkImage(photoUrl) as ImageProvider,
                            );
                          }
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white, size: 32),
                          );
                        }),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bom dia,',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      fontFamily: 'Poppins')),
                              Obx(() => Text(
                                  controller.professionalName.value.isNotEmpty
                                      ? controller.professionalName.value.split(' ').first
                                      : (FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'Profissional'),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins'))),
                              const SizedBox(height: 6),
                              Obx(() => _AccountStatusBadge(
                                  status: controller.accountStatus.value)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white),
                          onPressed: () =>
                              _showNotifications(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    final c = Get.find<HomeController>();
                    final available = c.isAvailable.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: available
                              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            available ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                            color: available ? const Color(0xFF22C55E) : AppColors.textMedium,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  available ? 'Recebendo novos pedidos' : 'Pausado — não recebe pedidos',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: available ? AppColors.textDark : AppColors.textMedium,
                                      fontFamily: 'Poppins'),
                                ),
                                if (!available)
                                  const Text(
                                    'Você não aparece para novos agendamentos',
                                    style: TextStyle(fontSize: 11, color: AppColors.textLight, fontFamily: 'Poppins'),
                                  ),
                              ],
                            ),
                          ),
                          Switch(
                            value: available,
                            activeThumbColor: const Color(0xFF22C55E),
                            onChanged: (_) => c.toggleAvailability(),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: Obx(() => _SummaryCard(
                                icon: Icons.attach_money_rounded,
                                color: const Color(0xFF22C55E),
                                label: 'Últimos 7 dias',
                                value:
                                    'R\$ ${controller.weekEarnings.value.toStringAsFixed(0)}',
                              ))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Obx(() => _SummaryCard(
                                icon: Icons.star_rounded,
                                color: const Color(0xFFF59E0B),
                                label: 'Avaliação',
                                value:
                                    '${controller.rating.value.toStringAsFixed(1)} (${controller.totalReviews.value})',
                              ))),
                    ],
                  ),
                  // Banner de status da conta
                  Obx(() {
                    final status = controller.accountStatus.value;
                    if (status == 'active') return const SizedBox();
                    return _StatusBanner(status: status);
                  }),
                  const SizedBox(height: 24),
                  const Text('Próximos atendimentos',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Obx(() {
                    if (controller.isLoadingData.value) {
                      return Column(
                        children: List.generate(3, (_) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: AppointmentCardSkeleton(),
                        )),
                      );
                    }
                    if (controller.upcomingAppointments.isEmpty) {
                      return const _EmptyDay();
                    }
                    return Column(
                      children: controller.upcomingAppointments
                          .asMap()
                          .entries
                          .map((e) => _AppointmentCard(
                              index: e.key, appt: e.value))
                          .toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.notifications_rounded,
                      color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Notificações',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                ],
              ),
            ),
            const Divider(height: 1),
            _NotifItem(
              icon: Icons.calendar_today_outlined,
              color: AppColors.primary,
              title: 'Novo agendamento',
              subtitle: 'Pedro Costa agendou para amanhã às 16:00',
              time: '5 min atrás',
            ),
            _NotifItem(
              icon: Icons.star_outline_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Nova avaliação',
              subtitle: 'Ana Lima te avaliou com 5 estrelas ⭐',
              time: '1h atrás',
            ),
            _NotifItem(
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF22C55E),
              title: 'Pagamento recebido',
              subtitle: 'R\$ 120,00 referente à consulta de Thor',
              time: '3h atrás',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, time;
  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textMedium)),
      trailing: Text(time,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textLight)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _SummaryCard(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMedium)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
        ],
      ),
    );
  }
}

String _shortDate(String date) {
  // "25/06/2026" → "25/06"
  final parts = date.split('/');
  if (parts.length >= 2) return '${parts[0]}/${parts[1]}';
  return date;
}

class _AppointmentCard extends GetView<HomeController> {
  final int index;
  final Map<String, String> appt;
  const _AppointmentCard({required this.index, required this.appt});

  @override
  Widget build(BuildContext context) {
    final isPending = appt['status'] == 'pending' || appt['status'] == 'pending_confirmation';
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.appointmentDetail, arguments: appt),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((appt['date'] ?? '').isNotEmpty)
                  Text(
                    _shortDate(appt['date']!),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontFamily: 'Poppins'),
                  ),
                Text(appt['time']!,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      appt['petSpecies'] == 'cat' ? '🐱' : appt['petSpecies'] == 'dog' ? '🐶' : '🐾',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(appt['pet']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Pendente',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                Text(appt['owner']!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMedium)),
                Text(appt['service']!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (isPending)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      color: Color(0xFF22C55E), size: 22),
                  onPressed: () =>
                      controller.confirmAppointment(appt['id']!),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.error, size: 22),
                  // Confirmação obrigatória: os dois ícones ficam colados,
                  // um toque impreciso não pode recusar (e estornar, se
                  // pago) uma consulta sem chance de desfazer.
                  onPressed: () => _confirmReject(context, appt['id']!),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            )
          else
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textLight, size: 20),
        ],
      ),
      ),
    );
  }

  void _confirmReject(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Recusar consulta?',
            style: TextStyle(fontFamily: 'Poppins')),
        content: const Text(
            'Se já houver pagamento, o valor será estornado ao cliente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar',
                  style: TextStyle(color: AppColors.textMedium))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              controller.rejectAppointment(id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 40, color: AppColors.textLight),
            SizedBox(height: 10),
            Text('Nenhum próximo atendimento',
                style: TextStyle(
                    color: AppColors.textMedium, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets de status da conta ──────────────────────────────────────────────

class _AccountStatusBadge extends StatelessWidget {
  final String status;
  const _AccountStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status == 'active'
        ? 'Conta ativa'
        : status == 'suspended'
            ? 'Conta suspensa'
            : 'Em análise';
    final dotColor = status == 'active'
        ? const Color(0xFF4ADE80)
        : status == 'suspended'
            ? const Color(0xFFF87171)
            : const Color(0xFFFBBF24);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: dotColor == const Color(0xFF4ADE80)
                      ? const Color(0xFF16A34A)
                      : dotColor == const Color(0xFFF87171)
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

class _ProfileStatusBadge extends StatelessWidget {
  final String status;
  const _ProfileStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status == 'active'
        ? 'Conta ativa'
        : status == 'suspended'
            ? 'Conta suspensa'
            : 'Em análise';
    final bg = status == 'active'
        ? const Color(0xFFDCFCE7)
        : status == 'suspended'
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7);
    final fg = status == 'active'
        ? const Color(0xFF166534)
        : status == 'suspended'
            ? const Color(0xFF991B1B)
            : const Color(0xFF92400E);
    final icon = status == 'active'
        ? Icons.verified_rounded
        : status == 'suspended'
            ? Icons.block_rounded
            : Icons.hourglass_top_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg)),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final isSuspended = status == 'suspended';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSuspended
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuspended
              ? const Color(0xFFF87171).withValues(alpha: 0.5)
              : const Color(0xFFFBBF24).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuspended
                ? Icons.block_rounded
                : Icons.hourglass_top_rounded,
            color: isSuspended
                ? const Color(0xFFDC2626)
                : const Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuspended ? 'Conta suspensa' : 'Conta em análise',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSuspended
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF92400E)),
                ),
                Text(
                  isSuspended
                      ? 'Entre em contato com o suporte para reativar.'
                      : 'Estamos verificando seus documentos. Em até 24h sua conta será ativada.',
                  style: TextStyle(
                      fontSize: 12,
                      color: isSuspended
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba Agenda ───────────────────────────────────────────────────────────────

class _AgendaTab extends StatefulWidget {
  const _AgendaTab();

  @override
  State<_AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<_AgendaTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _monthLabel(DateTime d) {
    const months = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return '${months[d.month]} ${d.year}';
  }

  List<DateTime?> _buildCalendarDays() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final startOffset = first.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final cells = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) cells.add(null);
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Agenda',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins')),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              fontFamily: 'Poppins'),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              fontFamily: 'Poppins'),
          tabs: const [
            Tab(text: 'Agenda'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAgendaContent(ctrl),
          _buildHistoricoContent(ctrl),
        ],
      ),
    );
  }

  // ── Conteúdo da aba Agenda (calendário + lista do dia) ─────────────

  Widget _buildAgendaContent(HomeController ctrl) {
    final cells = _buildCalendarDays();
    return Column(
      children: [
        // ── Calendário ─────────────────────────────────────────────
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              // Navegação de mês
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month - 1);
                    }),
                  ),
                  Text(
                    _monthLabel(_focusedMonth),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Poppins'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () => setState(() {
                      _focusedMonth = DateTime(
                          _focusedMonth.year, _focusedMonth.month + 1);
                    }),
                  ),
                ],
              ),
              // Cabeçalho dias da semana
              Row(
                children: ['D', 'S', 'T', 'Q', 'Q', 'S', 'S']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins')),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              // Grid de dias
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: cells.length,
                itemBuilder: (_, i) {
                  final day = cells[i];
                  if (day == null) return const SizedBox();
                  final isSelected = _selectedDay != null &&
                      day.year == _selectedDay!.year &&
                      day.month == _selectedDay!.month &&
                      day.day == _selectedDay!.day;
                  final isToday = day.year == DateTime.now().year &&
                      day.month == DateTime.now().month &&
                      day.day == DateTime.now().day;
                  final dateStr = _formatDate(day);
                  final hasAppt = ctrl.allAppointments
                      .any((a) => a['date'] == dateStr);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          if (hasAppt && !isSelected)
                            Positioned(
                              bottom: 3,
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // ── Lista de consultas do dia selecionado ──────────────────
        Expanded(
          child: Obx(() {
            if (_selectedDay == null) {
              return const Center(child: _EmptyDay());
            }
            final dateStr = _formatDate(_selectedDay!);
            final appts = ctrl.allAppointments
                .where((a) => a['date'] == dateStr)
                .toList();
            if (appts.isEmpty) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.textLight),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMedium),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(child: Center(child: _EmptyDay())),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '$dateStr · ${appts.length} consulta${appts.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: appts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _AppointmentCard(index: i, appt: appts[i]),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  // ── Conteúdo da aba Histórico ───────────────────────────────────────

  Widget _buildHistoricoContent(HomeController ctrl) {
    return _HistoricoContent(ctrl: ctrl);
  }
}

// ─── Histórico de consultas (widget separado para ter estado próprio) ─────────

class _HistoricoContent extends StatefulWidget {
  final HomeController ctrl;
  const _HistoricoContent({required this.ctrl});

  @override
  State<_HistoricoContent> createState() => _HistoricoContentState();
}

class _HistoricoContentState extends State<_HistoricoContent> {
  // 0=Todos 1=Concluídas 2=Canceladas/Recusadas
  int _filter = 0;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _statusLabels = {
    'completed': 'Concluída',
    'cancelled': 'Cancelada',
    'rejected': 'Recusada',
    'confirmed': 'Confirmada',
    'pending_confirmation': 'Aguardando',
    'pending_payment': 'Aguard. pagamento',
  };

  static const _statusColors = {
    'completed': Color(0xFF22C55E),
    'cancelled': Color(0xFFEF4444),
    'rejected': Color(0xFFEF4444),
    'confirmed': AppColors.primary,
    'pending_confirmation': Color(0xFFF59E0B),
    'pending_payment': Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Busca ────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Buscar por pet ou tutor...',
              hintStyle: const TextStyle(
                  fontSize: 13, color: AppColors.textLight, fontFamily: 'Poppins'),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textLight),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textLight),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // ── Filtros ─────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              _FilterChip(label: 'Todos', selected: _filter == 0,
                  onTap: () => setState(() => _filter = 0)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Concluídas', selected: _filter == 1,
                  onTap: () => setState(() => _filter = 1)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Canceladas', selected: _filter == 2,
                  onTap: () => setState(() => _filter = 2)),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Lista ───────────────────────────────────────────────────
        Expanded(
          child: Obx(() {
            final all = widget.ctrl.allAppointments.where((a) {
              final s = a['status'] ?? '';
              final matchFilter = switch (_filter) {
                1 => s == 'completed',
                2 => s == 'cancelled' || s == 'rejected',
                _ => true,
              };
              if (!matchFilter) return false;
              if (_searchQuery.isEmpty) return true;
              final pet = (a['pet'] ?? '').toLowerCase();
              final owner = (a['owner'] ?? '').toLowerCase();
              return pet.contains(_searchQuery) || owner.contains(_searchQuery);
            }).toList()
              ..sort((a, b) {
                // Ordena por data decrescente
                final da = a['date'] ?? '';
                final db = b['date'] ?? '';
                final ta = a['time'] ?? '';
                final tb = b['time'] ?? '';
                final cmp = db.compareTo(da);
                return cmp != 0 ? cmp : tb.compareTo(ta);
              });

            if (all.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded,
                        size: 56, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma consulta encontrada',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                          fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final appt = all[i];
                final status = appt['status'] ?? '';
                final statusLabel = _statusLabels[status] ?? status;
                final statusColor = _statusColors[status] ?? AppColors.textLight;
                final rating = appt['rating'];

                return GestureDetector(
                  onTap: () => Get.toNamed(Routes.appointmentDetail, arguments: appt),
                  child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho: pet + status
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.pets,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appt['pet'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                      fontFamily: 'Poppins'),
                                ),
                                Text(
                                  appt['owner'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                      fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                  fontFamily: 'Poppins'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      // Detalhes
                      Row(
                        children: [
                          _InfoChip(
                              icon: Icons.calendar_today_outlined,
                              label: appt['date'] ?? ''),
                          const SizedBox(width: 12),
                          _InfoChip(
                              icon: Icons.access_time_outlined,
                              label: appt['time'] ?? ''),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _InfoChip(
                              icon: Icons.medical_services_outlined,
                              label: appt['service'] ?? ''),
                          const SizedBox(width: 12),
                          _InfoChip(
                              icon: Icons.attach_money,
                              label: 'R\$ ${appt['value'] ?? ''}'),
                        ],
                      ),
                      // Avaliação do cliente (se houver)
                      if (rating != null && rating != '') ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Avaliação: ',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMedium,
                                    fontFamily: 'Poppins')),
                            ...List.generate(5, (si) => Icon(
                                  si < (int.tryParse(rating.toString()) ?? 0)
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 14,
                                  color: Colors.amber,
                                )),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                ); // GestureDetector
              },
            );
          }),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textMedium,
              fontFamily: 'Poppins'),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMedium,
                fontFamily: 'Poppins')),
      ],
    );
  }
}

// ─── Aba Serviços ─────────────────────────────────────────────────────────────

class _ServicosTab extends StatelessWidget {
  const _ServicosTab();

  void _addService(BuildContext context, HomeController ctrl) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddServiceSheet(
        nameCtrl: nameCtrl,
        priceCtrl: priceCtrl,
        onSave: (name, price, unit) {
          if (name.isEmpty || price.isEmpty) return;
          ctrl.addService(name, price, unit);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Meus Serviços',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins')),
        centerTitle: false,
        elevation: 0,
      ),
      body: Obx(() => ctrl.services.isEmpty
          ? const Center(
              child: Text('Nenhum serviço cadastrado.',
                  style: TextStyle(color: AppColors.textMedium)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: ctrl.services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final s = ctrl.services[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medical_services_outlined,
                            color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textDark)),
                            Text(
                                s['price'] != null && s['price']!.isNotEmpty
                                    ? 'R\$ ${s['price']} / ${s['unit']}'
                                    : s['unit'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 20),
                        onPressed: () => ctrl.removeService(i),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addService(context, ctrl),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Novo serviço',
            style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
      ),
    );
  }
}

class _AddServiceSheet extends StatefulWidget {
  final TextEditingController nameCtrl, priceCtrl;
  final void Function(String, String, String) onSave;
  const _AddServiceSheet(
      {required this.nameCtrl,
      required this.priceCtrl,
      required this.onSave});

  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  String _unit = 'consulta';
  static const _units = [
    'consulta', 'sessão', 'hora', 'dose', 'serviço', 'pacote'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Novo serviço',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 16),
            TextField(
              controller: widget.nameCtrl,
              decoration: const InputDecoration(
                  hintText: 'Nome do serviço',
                  prefixIcon: Icon(Icons.medical_services_outlined,
                      size: 20, color: AppColors.textLight)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        hintText: 'Preço (R\$)',
                        prefixIcon: Icon(Icons.attach_money,
                            size: 20,
                            color: AppColors.textLight)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatefulBuilder(
                    builder: (_, ss) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unit,
                          isExpanded: true,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                              fontFamily: 'Poppins'),
                          items: _units
                              .map((u) => DropdownMenuItem(
                                  value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) =>
                              ss(() => _unit = v ?? 'consulta'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.onSave(widget.nameCtrl.text.trim(),
                    widget.priceCtrl.text.trim(), _unit);
                Get.back();
              },
              child: const Text('Salvar serviço'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Aba Financeiro ───────────────────────────────────────────────────────────

class _FinanceiroTab extends GetView<HomeController> {
  const _FinanceiroTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Financeiro',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins')),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de resumo
            Row(
              children: [
                Expanded(
                    child: Obx(() => _FinCard(
                          label: 'Últimos 7 dias',
                          value:
                              'R\$ ${controller.weekEarnings.value.toStringAsFixed(2).replaceAll('.', ',')}',
                          sub: '${controller.weekCount.value} atendimento${controller.weekCount.value == 1 ? '' : 's'}',
                          color: const Color(0xFF22C55E),
                          icon: Icons.trending_up_rounded,
                          onTap: () => _showWeekDetail(context),
                        ))),
                const SizedBox(width: 12),
                Expanded(
                    child: Obx(() => _FinCard(
                          label: 'Este mês',
                          value:
                              'R\$ ${controller.monthEarnings.value.toStringAsFixed(2).replaceAll('.', ',')}',
                          sub: '${controller.monthCount.value} atendimento${controller.monthCount.value == 1 ? '' : 's'}',
                          color: AppColors.primary,
                          icon: Icons.calendar_month_rounded,
                          onTap: () => _showMonthDetail(context),
                        ))),
              ],
            ),
            const SizedBox(height: 14),
            Obx(() => _FinCard(
              label: 'A receber',
              value: 'R\$ ${controller.pendingEarnings.value.toStringAsFixed(2).replaceAll('.', ',')}',
              sub: '${controller.pendingCount.value} pagamento${controller.pendingCount.value == 1 ? '' : 's'} pendente${controller.pendingCount.value == 1 ? '' : 's'}',
              color: const Color(0xFFF59E0B),
              icon: Icons.pending_actions_rounded,
              full: true,
              onTap: () => _showPendingDetail(context),
            )),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Valores líquidos — a taxa do app já está descontada',
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
            ),

            const SizedBox(height: 14),
            Obx(() => _FeeTierCard(
                  currentFee: controller.currentFeePercent,
                  paidThisMonth: controller.paidThisMonth.value,
                  nextTarget: controller.nextTierTarget,
                  nextFee: controller.nextTierPercent,
                  tiersLabel: controller.tiersLabel,
                  overrideActive: controller.hasActiveOverride,
                  overrideUntil: controller.feeOverrideUntil.value,
                )),

            const SizedBox(height: 24),
            const Text('Últimas transações',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 12),

            Obx(() {
              if (controller.isLoadingData.value) {
                return Column(
                  children: List.generate(4, (_) => const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: TransactionCardSkeleton(),
                  )),
                );
              }
              final txs = controller.recentTransactions;
              if (txs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Nenhuma transação ainda',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMedium)),
                  ),
                );
              }
              return Column(
                children: txs.map((tx) {
                  final net = tx['net'] as double? ?? 0;
                  return _TransactionItem(
                    name: tx['name'] ?? '',
                    date: '${tx['date']}${tx['time'] != '' ? ', ${tx['time']}' : ''}',
                    value: net.toStringAsFixed(2).replaceAll('.', ','),
                    status: tx['txStatus'] == 'recebido' ? 'received' : 'pending',
                  );
                }).toList(),
              );
            }),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Chaves PIX',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                TextButton.icon(
                  onPressed: () => _showPixSheet(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Adicionar'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.pixKeys.isEmpty) {
                return _PixEmptyCard(
                    onTap: () => _showPixSheet(context));
              }
              return Column(
                children: controller.pixKeys
                    .asMap()
                    .entries
                    .map((e) => _PixKeyItem(
                          index: e.key,
                          data: e.value,
                          onRemove: () =>
                              controller.removePixKey(e.key),
                        ))
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _fmtMoney(double v) {
    final s = v.toStringAsFixed(2).replaceAll('.', ',');
    // add thousands separator
    final parts = s.split(',');
    final intPart = parts[0];
    final dec = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }
    return 'R\$ ${buf.toString()},$dec';
  }

  List<_FinDetailItem> _txToItems(List<Map<String, dynamic>> txs) {
    return txs.map((tx) {
      final gross = tx['gross'] as double? ?? 0;
      final net = tx['net'] as double? ?? 0;
      final feePct = tx['feePct'] as int? ?? 0;
      return _FinDetailItem(
        name: tx['name'] ?? '',
        date: '${tx['date']}${(tx['time'] ?? '').isNotEmpty ? ', ${tx['time']}' : ''}'
            '\n${_fmtMoney(gross)} · taxa $feePct% → você recebe',
        value: _fmtMoney(net),
        received: tx['txStatus'] == 'recebido',
      );
    }).toList();
  }

  List<_BreakdownItem> _buildBreakdown(List<Map<String, dynamic>> txs, double total) {
    final Map<String, double> groups = {};
    for (final tx in txs) {
      final name = (tx['serviceName'] as String? ?? '').toLowerCase();
      String label;
      if (name.contains('vacin')) {
        label = 'Vacinas';
      } else if (name.contains('retorno')) {
        label = 'Retornos';
      } else if (name.contains('check') || name.contains('anual')) {
        label = 'Check-ups';
      } else if (name.contains('consul')) {
        label = 'Consultas';
      } else {
        label = 'Outros';
      }
      groups[label] = (groups[label] ?? 0) + (tx['net'] as double? ?? 0);
    }
    if (total <= 0) return [];
    return groups.entries.map((e) => _BreakdownItem(
      label: e.key,
      value: _fmtMoney(e.value),
      percent: e.value / total,
    )).toList()..sort((a, b) => b.percent.compareTo(a.percent));
  }

  void _showWeekDetail(BuildContext context) {
    final txs = controller.weekTransactions;
    final total = controller.weekEarnings.value;
    final count = controller.weekCount.value;
    _showFinancialDetail(
      context: context,
      title: 'Últimos 7 dias',
      total: _fmtMoney(total),
      subtitle: '$count atendimento${count == 1 ? '' : 's'} nos últimos 7 dias',
      color: const Color(0xFF22C55E),
      icon: Icons.trending_up_rounded,
      items: _txToItems(txs),
      breakdown: _buildBreakdown(txs, total),
    );
  }

  void _showMonthDetail(BuildContext context) {
    final txs = controller.monthTransactions;
    final total = controller.monthEarnings.value;
    final count = controller.monthCount.value;
    final now = DateTime.now();
    final months = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    _showFinancialDetail(
      context: context,
      title: 'Este mês',
      total: _fmtMoney(total),
      subtitle: '$count atendimento${count == 1 ? '' : 's'} · ${months[now.month - 1]} ${now.year}',
      color: AppColors.primary,
      icon: Icons.calendar_month_rounded,
      items: _txToItems(txs),
      breakdown: _buildBreakdown(txs, total),
    );
  }

  void _showPendingDetail(BuildContext context) {
    final txs = controller.pendingTransactions;
    final total = controller.pendingEarnings.value;
    final count = controller.pendingCount.value;
    _showFinancialDetail(
      context: context,
      title: 'A receber',
      total: _fmtMoney(total),
      subtitle: '$count pagamento${count == 1 ? '' : 's'} pendente${count == 1 ? '' : 's'}',
      color: const Color(0xFFF59E0B),
      icon: Icons.pending_actions_rounded,
      items: _txToItems(txs),
      breakdown: null,
      pendingNote: 'Agendamentos confirmados + atendimentos dos últimos 2 dias (D+2 úteis).',
    );
  }

  void _showFinancialDetail({
    required BuildContext context,
    required String title,
    required String total,
    required String subtitle,
    required Color color,
    required IconData icon,
    required List<_FinDetailItem> items,
    required List<_BreakdownItem>? breakdown,
    String? pendingNote,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: TextStyle(
                              fontSize: 12, color: color,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins')),
                          Text(total, style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold,
                              color: color, fontFamily: 'Poppins')),
                          Text(subtitle, style: const TextStyle(
                              fontSize: 11, color: AppColors.textMedium,
                              fontFamily: 'Poppins')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // Nota de pendência
                    if (pendingNote != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(pendingNote,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF92400E),
                                    fontFamily: 'Poppins'))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Breakdown por categoria
                    if (breakdown != null) ...[
                      const Text('Por categoria',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 10),
                      ...breakdown.map((b) => _BreakdownRow(item: b, color: color)),
                      const SizedBox(height: 20),
                    ],
                    // Lista de transações
                    const Text('Transações',
                        style: TextStyle(fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontFamily: 'Poppins')),
                    const SizedBox(height: 10),
                    ...items.map((item) => _FinDetailRow(item: item)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPixSheet(BuildContext context) {
    final keyCtrl = TextEditingController();
    String selectedType = 'CPF';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (_, ss) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Adicionar chave PIX',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 6),
                const Text(
                  'Os pagamentos serão transferidos para essa chave.',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMedium),
                ),
                const SizedBox(height: 20),
                const Text('Tipo de chave',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['CPF', 'E-mail', 'Telefone', 'Aleatória']
                      .map((t) {
                    final sel = selectedType == t;
                    return GestureDetector(
                      onTap: () => ss(() => selectedType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : const Color(0xFFE5E7EB)),
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
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: keyCtrl,
                  decoration: InputDecoration(
                    hintText: selectedType == 'CPF'
                        ? '000.000.000-00'
                        : selectedType == 'E-mail'
                            ? 'seu@email.com'
                            : selectedType == 'Telefone'
                                ? '(21) 9 9999-9999'
                                : 'Cole sua chave aleatória',
                    prefixIcon: const Icon(Icons.pix_rounded,
                        color: AppColors.textLight, size: 20),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final key = keyCtrl.text.trim();
                    if (key.isEmpty) return;
                    Get.back();
                    await controller.addPixKey(selectedType, key);
                    controller.snack(
                      title: 'PIX cadastrado',
                      message: 'Chave $selectedType salva com sucesso!',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF22C55E),
                    );
                  },
                  child: const Text('Salvar chave PIX'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Card da taxa regressiva por volume ───────────────────────────────────────

class _FeeTierCard extends StatelessWidget {
  final int currentFee;
  final int paidThisMonth;
  final int? nextTarget; // null = já garantiu a taxa mínima
  final int nextFee;
  final String tiersLabel;
  final bool overrideActive;
  final DateTime? overrideUntil;

  const _FeeTierCard({
    required this.currentFee,
    required this.paidThisMonth,
    required this.nextTarget,
    required this.nextFee,
    required this.tiersLabel,
    this.overrideActive = false,
    this.overrideUntil,
  });

  @override
  Widget build(BuildContext context) {
    // Taxa personalizada definida pela plataforma: sem barra de progresso
    if (overrideActive) {
      final untilStr = overrideUntil != null
          ? ' até ${overrideUntil!.day.toString().padLeft(2, '0')}/${overrideUntil!.month.toString().padLeft(2, '0')}/${overrideUntil!.year}'
          : '';
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star_rounded,
                  color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      currentFee == 0
                          ? '🎁 Você está isento de taxa$untilStr!'
                          : 'Sua taxa personalizada: $currentFee%$untilStr',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const Text('Condição especial definida pela plataforma',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textMedium)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final atMinimum = nextTarget == null;
    final remaining = atMinimum ? 0 : nextTarget! - paidThisMonth;
    final progress = atMinimum
        ? 1.0
        : (paidThisMonth / nextTarget!).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.trending_down_rounded,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sua taxa este mês: $currentFee%',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const Text('Quanto mais consultas, menor a taxa',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMedium)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            atMinimum
                ? '🎉 $paidThisMonth consultas este mês — você garantiu a '
                    'taxa mínima de $nextFee% no mês que vem!'
                : '$paidThisMonth de $nextTarget consultas este mês — '
                    'faltam $remaining para garantir $nextFee% no mês que vem',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textMedium, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            'Faixas (consultas/mês): $tiersLabel',
            style: const TextStyle(fontSize: 10, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}

class _FinCard extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  final IconData icon;
  final bool full;
  final VoidCallback? onTap;
  const _FinCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.icon,
    this.full = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: full ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMedium)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(sub,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textLight)),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String name, date, value, status;
  const _TransactionItem(
      {required this.name,
      required this.date,
      required this.value,
      required this.status});

  @override
  Widget build(BuildContext context) {
    final received = status == 'received';
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: received
                  ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              received
                  ? Icons.check_circle_outline
                  : Icons.schedule_rounded,
              color: received
                  ? const Color(0xFF22C55E)
                  : const Color(0xFFF59E0B),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
                Text(date,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMedium)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: received
                          ? const Color(0xFF22C55E)
                          : AppColors.textDark)),
              Text(received ? 'Recebido' : 'A receber',
                  style: TextStyle(
                      fontSize: 10,
                      color: received
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }
}

class _PixEmptyCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PixEmptyCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF32BCAD).withValues(alpha: 0.4),
              style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF32BCAD).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pix_rounded,
                  color: Color(0xFF32BCAD), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nenhuma chave PIX cadastrada',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  Text('Toque para adicionar uma chave',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline,
                size: 20, color: Color(0xFF32BCAD)),
          ],
        ),
      ),
    );
  }
}

class _PixKeyItem extends StatelessWidget {
  final int index;
  final Map<String, String> data;
  final VoidCallback onRemove;
  const _PixKeyItem(
      {required this.index,
      required this.data,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF32BCAD).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pix_rounded,
                color: Color(0xFF32BCAD), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['type'] ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w600)),
                Text(data['key'] ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            onPressed: () => Get.defaultDialog(
              title: 'Remover chave?',
              middleText:
                  'Deseja remover a chave ${data['type']}?',
              textConfirm: 'Remover',
              textCancel: 'Cancelar',
              confirmTextColor: Colors.white,
              buttonColor: AppColors.error,
              onConfirm: () {
                Get.back();
                onRemove();
              },
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Aba Perfil ───────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType keyboard;
  final int maxLines;

  const _EditField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMedium)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: AppColors.textLight),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  // Vem do TaxonomyService (config/species no Firestore).
  List<(String, String)> get _allSpecies => Get.find<TaxonomyService>()
      .species
      .map((s) => (s.key, '${s.emoji} ${s.label}'))
      .toList();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _crmvCtrl;
  late List<String> _selectedSpecies;
  late List<String> _selectedCategories;
  late Set<String> _selectedDays;
  late List<String> _selectedTimes;

  @override
  void initState() {
    super.initState();
    final c = Get.find<HomeController>();
    _nameCtrl = TextEditingController(text: c.professionalName.value);
    _phoneCtrl = TextEditingController(text: c.professionalPhone.value);
    _bioCtrl = TextEditingController(text: c.professionalBio.value);
    _crmvCtrl = TextEditingController(text: c.professionalCrmv.value);
    _selectedSpecies = List<String>.from(c.animalSpecies);
    _selectedCategories = List<String>.from(c.professionalCategories);
    _selectedDays = Set<String>.from(c.professionalDays);
    _selectedTimes = List<String>.from(c.professionalTimes);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _crmvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Editar perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 20),
              _EditField(ctrl: _nameCtrl, label: 'Nome completo', icon: Icons.person_outline),
              const SizedBox(height: 14),
              _EditField(ctrl: _phoneCtrl, label: 'Telefone', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              _EditField(ctrl: _crmvCtrl, label: 'CRMV / Certificação', icon: Icons.badge_outlined),
              const SizedBox(height: 14),
              _EditField(ctrl: _bioCtrl, label: 'Sobre mim', icon: Icons.info_outline, maxLines: 4),
              const SizedBox(height: 20),
              const Text('Especialidades que ofereço',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 10),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Get.find<TaxonomyService>().specialtyValues.map((spec) {
                  final selected = _selectedCategories.contains(spec);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedCategories.remove(spec);
                      } else {
                        _selectedCategories.add(spec);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Text(spec,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.white : AppColors.textMedium)),
                    ),
                  );
                }).toList(),
              )),
              const SizedBox(height: 20),
              const Text('Espécies que atendo',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSpecies.map((sp) {
                  final selected = _selectedSpecies.contains(sp.$1);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedSpecies.remove(sp.$1);
                      } else {
                        _selectedSpecies.add(sp.$1);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Text(sp.$2,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.white : AppColors.textMedium)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Dias disponíveis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RegisterController.allDays.map((day) {
                  final selected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedDays.remove(day);
                      } else {
                        _selectedDays.add(day);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 44,
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(day,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : AppColors.textDark)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Horários disponíveis',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const SizedBox(height: 10),
              ...RegisterController.periods.map((period) {
                final (label, times) = period;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMedium)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: times.map((t) {
                          final selected = _selectedTimes.contains(t);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (selected) {
                                _selectedTimes.remove(t);
                              } else {
                                _selectedTimes.add(t);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Text(t,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : AppColors.textDark)),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Get.back();
                  await c.updateProfile(
                    name: _nameCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                    bio: _bioCtrl.text.trim(),
                    crmv: _crmvCtrl.text.trim(),
                    species: _selectedSpecies,
                    categories: _selectedCategories,
                    days: _selectedDays.toList(),
                    times: _selectedTimes,
                  );
                  c.snack(
                    title: 'Perfil atualizado',
                    message: 'Suas informações foram salvas.',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF22C55E),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Salvar alterações'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilTab extends StatefulWidget {
  const _PerfilTab();

  @override
  State<_PerfilTab> createState() => _PerfilTabState();
}

class _PerfilTabState extends State<_PerfilTab> {
  void _showEditProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Meu Perfil',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins')),
        centerTitle: false,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _showEditProfileSheet(context),
            child: const Text('Editar',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  Obx(() {
                    final c = Get.find<HomeController>();
                    final photoUrl = c.professionalPhotoUrl.value;
                    final uploading = c.isUploadingPhoto.value;
                    return Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          backgroundImage: photoUrl.isNotEmpty
                              ? (photoUrl.startsWith('data:image')
                                  ? MemoryImage(base64Decode(photoUrl.split(',').last))
                                  : NetworkImage(photoUrl) as ImageProvider)
                              : null,
                          child: photoUrl.isEmpty
                              ? const Icon(Icons.person_rounded,
                                  size: 44, color: AppColors.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: uploading ? null : c.pickAndUploadPhoto,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: uploading
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.camera_alt_rounded,
                                      size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  Obx(() {
                    final name = Get.find<HomeController>().professionalName.value;
                    return Text(
                      name.isEmpty ? (FirebaseAuth.instance.currentUser?.displayName ?? 'Profissional') : name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark));
                  }),
                  Obx(() {
                    final c = Get.find<HomeController>();
                    final cats = c.professionalCategories.join(', ');
                    final crmv = c.professionalCrmv.value;
                    final sub = [if (cats.isNotEmpty) cats, if (crmv.isNotEmpty) crmv].join(' · ');
                    return Text(sub.isEmpty ? '' : sub,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMedium));
                  }),
                  const SizedBox(height: 8),
                  Obx(() {
                    final ctrl = Get.find<HomeController>();
                    final r = ctrl.rating.value;
                    final n = ctrl.totalReviews.value;
                    if (n == 0) return const SizedBox.shrink();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 4),
                        Text(r.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                        const SizedBox(width: 4),
                        Text('($n avaliação${n == 1 ? '' : 'ões'})',
                            style: const TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 13)),
                      ],
                    );
                  }),
                  const SizedBox(height: 10),
                  Obx(() => _ProfileStatusBadge(
                      status:
                          Get.find<HomeController>().accountStatus.value)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bio
            Obx(() {
              final bio = Get.find<HomeController>().professionalBio.value;
              if (bio.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  _InfoCard(
                    title: 'Sobre mim',
                    child: Text(bio,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMedium, height: 1.5)),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            }),

            // Espécies atendidas
            Obx(() {
              final species = Get.find<HomeController>().animalSpecies;
              if (species.isEmpty) return const SizedBox.shrink();
              const labels = {
                'dog': '🐶 Cão',
                'cat': '🐱 Gato',
                'bird': '🐦 Ave',
                'rabbit': '🐰 Coelho',
                'rodent': '🐹 Roedor',
                'reptile': '🦎 Réptil',
                'fish': '🐟 Peixe',
                'exotic': '🦜 Exótico',
              };
              return Column(
                children: [
                  _InfoCard(
                    title: 'Espécies atendidas',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: species
                          .map((s) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(labels[s] ?? s,
                                    style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            }),

            // Contato
            Obx(() {
              final c = Get.find<HomeController>();
              return _InfoCard(
                title: 'Contato',
                child: Column(
                  children: [
                    _ProfileRow(icon: Icons.email_outlined, text: c.professionalEmail.value.isEmpty ? '—' : c.professionalEmail.value),
                    if (c.professionalPhone.value.isNotEmpty) ...[
                      const Divider(height: 20),
                      _ProfileRow(icon: Icons.phone_outlined, text: c.professionalPhone.value),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),

            // Disponibilidade
            Obx(() {
              final c = Get.find<HomeController>();
              final days = c.professionalDays.join(', ');
              final times = c.professionalTimes;
              final timeRange = times.isEmpty ? '' : '${times.first} – ${times.last}';
              if (days.isEmpty && timeRange.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  _InfoCard(
                    title: 'Disponibilidade',
                    child: Column(
                      children: [
                        if (days.isNotEmpty)
                          _ProfileRow(icon: Icons.calendar_today_outlined, text: days),
                        if (days.isNotEmpty && timeRange.isNotEmpty)
                          const Divider(height: 20),
                        if (timeRange.isNotEmpty)
                          _ProfileRow(icon: Icons.schedule_outlined, text: timeRange),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              );
            }),
            const SizedBox(height: 14),

            // Área de atuação
            Obx(() {
              final resumo =
                  Get.find<HomeController>().areaAtuacaoResumo.value;
              return _InfoCard(
                title: 'Área de atuação',
                child: InkWell(
                  onTap: () async {
                    await Get.toNamed(Routes.serviceArea);
                    Get.find<HomeController>().reloadAreaAtuacao();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Icon(
                        resumo.isEmpty
                            ? Icons.add_location_alt_outlined
                            : Icons.location_on_outlined,
                        size: 18,
                        color: resumo.isEmpty
                            ? AppColors.accent
                            : AppColors.textMedium,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          resumo.isEmpty
                              ? 'Defina onde você atende para aparecer nas buscas'
                              : resumo,
                          style: TextStyle(
                            fontSize: 13,
                            color: resumo.isEmpty
                                ? AppColors.accent
                                : AppColors.textMedium,
                            fontWeight: resumo.isEmpty
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 20, color: AppColors.textMedium),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 14),

            // Documentos
            Obx(() {
              final c = Get.find<HomeController>();
              final statuses = c.docStatuses;
              return _InfoCard(
                title: 'Documentos',
                child: Column(
                  children: [
                    _DocItem(
                      label: 'RG / CNH',
                      status: statuses['rg'] ?? 'pending',
                      onTap: () => _showDocSheet(context, 'RG / CNH', 'rg'),
                    ),
                    const Divider(height: 20),
                    _DocItem(
                      label: 'CRMV / Certificação',
                      status: statuses['crmv'] ?? 'pending',
                      onTap: () => _showDocSheet(
                          context, 'CRMV / Certificação', 'crmv'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),

            // Termos de Uso (consulta)
            _InfoCard(
              title: 'Legal',
              child: InkWell(
                onTap: () => Get.to(() => const TermsView(readOnly: true)),
                borderRadius: BorderRadius.circular(8),
                child: const Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 18, color: AppColors.textMedium),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Termos de Uso e Política de Privacidade',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textDark)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: AppColors.textMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sair
            OutlinedButton.icon(
              onPressed: () => Get.offAllNamed('/login'),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sair da conta'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDocSheet(BuildContext context, String docName, [String docType = 'rg']) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enviar $docName',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 6),
            const Text(
              'Envie uma foto legível do documento. Será analisado em até 24h.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textMedium),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _UploadOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Câmera',
                    onTap: () {
                      Get.back();
                      Get.find<HomeController>()
                          .uploadDocument(docType, ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _UploadOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeria',
                    onTap: () {
                      Get.back();
                      Get.find<HomeController>()
                          .uploadDocument(docType, ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final String label, status;
  final VoidCallback onTap;
  const _DocItem(
      {required this.label,
      required this.status,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (chipLabel, chipColor, icon) = switch (status) {
      'approved' => ('Aprovado', const Color(0xFF22C55E), Icons.check_circle_rounded),
      'submitted' => ('Em análise', AppColors.primary, Icons.hourglass_top_rounded),
      'rejected' => ('Reenviar', const Color(0xFFEF4444), Icons.error_outline_rounded),
      _ => ('Enviar', const Color(0xFFD97706), Icons.upload_file_outlined),
    };
    final isApproved = status == 'approved';
    return GestureDetector(
      onTap: isApproved ? null : onTap,
      child: Row(
        children: [
          Icon(icon, color: chipColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textDark)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              chipLabel,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: chipColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _UploadOption(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

// ─── Financeiro: detalhe ──────────────────────────────────────────────────────

class _FinDetailItem {
  final String name, date, value;
  final bool received;
  const _FinDetailItem({
    required this.name, required this.date,
    required this.value, required this.received,
  });
}

class _BreakdownItem {
  final String label, value;
  final double percent;
  const _BreakdownItem({required this.label, required this.value, required this.percent});
}

class _BreakdownRow extends StatelessWidget {
  final _BreakdownItem item;
  final Color color;
  const _BreakdownRow({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.label, style: const TextStyle(
                  fontSize: 12, color: AppColors.textMedium, fontFamily: 'Poppins')),
              Text(item.value, style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textDark, fontFamily: 'Poppins')),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percent,
              minHeight: 6,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinDetailRow extends StatelessWidget {
  final _FinDetailItem item;
  const _FinDetailRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: item.received
                  ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.received ? Icons.check_circle_outline : Icons.schedule_rounded,
              color: item.received ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: AppColors.textDark, fontFamily: 'Poppins')),
                Text(item.date, style: const TextStyle(
                    fontSize: 11, color: AppColors.textMedium, fontFamily: 'Poppins')),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.value, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: item.received ? const Color(0xFF22C55E) : AppColors.textDark,
                  fontFamily: 'Poppins')),
              Text(item.received ? 'Recebido' : 'A receber',
                  style: TextStyle(
                      fontSize: 10, fontFamily: 'Poppins',
                      color: item.received
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ProfileRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMedium)),
      ],
    );
  }
}
