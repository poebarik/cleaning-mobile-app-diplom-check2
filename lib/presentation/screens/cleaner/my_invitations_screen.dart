// lib/presentation/screens/cleaner/my_invitations_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../providers/invitation_provider.dart';
import '../../../routes/route_names.dart';
import '../../../data/models/invitation/cleaner_invitation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/cleaner_repository.dart';
import '../../../data/repositories/user_repository.dart';

class MyInvitationsScreen extends ConsumerStatefulWidget {
  const MyInvitationsScreen({super.key});

  @override
  ConsumerState<MyInvitationsScreen> createState() => _MyInvitationsScreenState();
}

class _MyInvitationsScreenState extends ConsumerState<MyInvitationsScreen> {
  String _filter = 'ALL';
  final UserRepository _userRepository = UserRepository();
  final CleanerRepository _cleanerRepository = CleanerRepository();
  final Map<int, int> _userIdCache = {};

  static const _filters = [
    _FilterChip(value: 'ALL', label: 'Все', icon: CupertinoIcons.list_bullet),
    _FilterChip(value: 'PENDING', label: 'Ожидают', icon: CupertinoIcons.clock),
    _FilterChip(value: 'COUNTER_OFFER', label: 'Встречные', icon: CupertinoIcons.arrow_2_squarepath),
    _FilterChip(value: 'ACCEPTED', label: 'Принятые', icon: CupertinoIcons.checkmark_circle),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invitationProvider.notifier).loadCleanerInvitations();
    });
  }

  // lib/presentation/screens/cleaner/my_invitations_screen.dart

// ✅ Исправленный метод _getUserIdByClientId
  Future<int?> _getUserIdByClientId(int clientId) async {
    if (_userIdCache.containsKey(clientId)) {
      final cachedUserId = _userIdCache[clientId];
      if (cachedUserId != null && cachedUserId > 0) {
        print('✅ userId найден в кэше: $cachedUserId для clientId: $clientId');
        return cachedUserId;
      }
    }

    try {
      print('🔍 Запрос userId для clientId: $clientId');
      final userId = await _userRepository.getUserIdByClientId(clientId);
      print('📊 Результат getUserIdByClientId: $userId');

      if (userId != null && userId > 0) {
        _userIdCache[clientId] = userId;
        print('✅ userId получен через API: $userId для clientId: $clientId');
        return userId;
      }

      print('⚠️ userId не найден для clientId: $clientId');
      return null;
    } catch (e) {
      print('❌ Ошибка получения userId для clientId $clientId: $e');
      return null;
    }
  }

// ✅ Исправленный метод _viewClientProfile
  // lib/presentation/screens/cleaner/my_invitations_screen.dart

  void _viewClientProfile(CleanerInvitation invitation) async {
    // ✅ Проверяем clientId
    if (invitation.clientId == null || invitation.clientId == 0) {
      print('⚠️ clientId отсутствует или равен 0');
      CustomSnackbar.showError(context, 'Информация о клиенте недоступна');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ Пытаемся получить userId, если не получается - используем clientId
      int? userId = await _getUserIdByClientId(invitation.clientId!);

      // ✅ Если userId не найден, используем clientId как fallback
      if (userId == null || userId <= 0) {
        userId = invitation.clientId!;
        print('⚠️ Используем clientId как userId: $userId');
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📸 ПЕРЕХОД В ПРОФИЛЬ КЛИЕНТА:');
      print('  - clientId: ${invitation.clientId}');
      print('  - clientName: ${invitation.clientName ?? 'Неизвестно'}');
      print('  - полученный userId: $userId');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (userId > 0) {
        context.push('/profile/$userId');
      } else {
        CustomSnackbar.showError(context, 'Информация о клиенте недоступна');
      }
    } catch (e) {
      print('❌ Ошибка перехода в профиль: $e');
      // ✅ Fallback - пробуем использовать clientId напрямую
      try {
        context.push('/profile/${invitation.clientId}');
      } catch (_) {
        CustomSnackbar.showError(context, 'Ошибка загрузки профиля');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _viewJobDetails(CleanerInvitation invitation) {
    if (invitation.orderId == null || invitation.orderId == 0) {
      CustomSnackbar.showError(context, 'Информация о заказе недоступна');
      return;
    }
    context.push('/job-details/${invitation.orderId}');
  }

  List<CleanerInvitation> _getFilteredInvitations(List<CleanerInvitation> invitations) {
    if (_filter == 'ALL') return invitations;
    if (_filter == 'PENDING') {
      return invitations.where((inv) => inv.status == 'PENDING').toList();
    }
    if (_filter == 'COUNTER_OFFER') {
      return invitations.where((inv) => inv.status == 'COUNTER_OFFER').toList();
    }
    if (_filter == 'ACCEPTED') {
      return invitations.where((inv) => inv.status == 'ACCEPTED').toList();
    }
    return invitations;
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final invitationState = ref.watch(invitationProvider);
    final canPop = Navigator.canPop(context);

    final filteredInvitations = invitationState.cleanerInvitations != null
        ? _getFilteredInvitations(invitationState.cleanerInvitations!)
        : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: Column(
        children: [
          // ✅ Header
          _buildHeader(canPop),

          // ✅ Фильтры
          _buildFilterBar(),

          // ✅ Контент
          Expanded(
            child: invitationState.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
                : invitationState.isError
                ? _buildErrorWidget(invitationState.error)
                : filteredInvitations.isEmpty
                ? _buildEmptyWidget()
                : RefreshIndicator(
              onRefresh: () async {
                await ref.read(invitationProvider.notifier).loadCleanerInvitations();
              },
              color: const Color(0xFF6C5CE7),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: filteredInvitations.length,
                itemBuilder: (context, index) {
                  final invitation = filteredInvitations[index];
                  return _buildInvitationCard(invitation);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Header
  Widget _buildHeader(bool canPop) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF8B7FF0),
            Color(0xFFA29BFE)
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (canPop)
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  if (canPop) const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Приглашения',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Приглашения от клиентов',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  ref.read(invitationProvider.notifier).loadCleanerInvitations();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Фильтры
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (ctx, i) {
          final chip = _filters[i];
          final isSelected = _filter == chip.value;
          return GestureDetector(
            onTap: () {
              setState(() => _filter = chip.value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                )
                    : null,
                color: isSelected ? null : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chip.icon,
                    size: 13,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    chip.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEB3B5A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.exclamationmark_triangle, size: 40, color: Color(0xFFEB3B5A)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ошибка загрузки',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error ?? 'Неизвестная ошибка',
            style: const TextStyle(fontSize: 13, color: Color(0xFF636E72), fontFamily: 'Poppins'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(invitationProvider.notifier).loadCleanerInvitations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Повторить', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.mail,
              size: 48,
              color: Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет приглашений',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'ALL'
                ? 'Когда клиенты пригласят вас,\nони появятся здесь'
                : 'Нет приглашений с выбранным статусом',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(CleanerInvitation invitation) {
    final isExpired = invitation.isExpired;
    final isPending = invitation.status == 'PENDING';
    final isCounterOffer = invitation.status == 'COUNTER_OFFER';
    final isAccepted = invitation.status == 'ACCEPTED';
    final isDeclined = invitation.status == 'DECLINED';
    final images = invitation.imageObjectNames ?? [];

    if (isAccepted || isDeclined || isExpired) {
      return _buildStatusCard(invitation);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isCounterOffer ? const Color(0xFF0984E3).withOpacity(0.06) : const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: isCounterOffer
            ? Border.all(color: const Color(0xFF0984E3).withOpacity(0.3), width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Заголовок ─────────────────────────────────────
              GestureDetector(
                onTap: () => _viewJobDetails(invitation),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        invitation.serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                          color: Color(0xFF2D3436),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isCounterOffer
                            ? const Color(0xFF0984E3).withOpacity(0.12)
                            : const Color(0xFFFFA94D).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isCounterOffer ? 'Встречное предложение' : 'Ожидает ответа',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                          color: isCounterOffer ? const Color(0xFF0984E3) : const Color(0xFFFFA94D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F2F6)),
              const SizedBox(height: 14),

              // ─── Информация ────────────────────────────────────
              _invitationInfoRow(CupertinoIcons.person, 'Клиент: ${invitation.clientName}'),
              const SizedBox(height: 8),
              _invitationInfoRow(CupertinoIcons.money_rubl, 'Предложено: ${invitation.proposedPrice.toInt()} ₸', isPrice: true),
              const SizedBox(height: 8),
              _invitationInfoRow(CupertinoIcons.location, invitation.orderAddress),
              const SizedBox(height: 8),
              _invitationInfoRow(CupertinoIcons.time, 'Действительно до: ${_formatDate(invitation.expiresAt)}', isGrey: true),

              // ─── Фото ──────────────────────────────────────────
              if (images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length > 4 ? 4 : images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = images[index];
                      return Container(
                        width: 72,
                        height: 72,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDFE6E9), width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl.startsWith('http')
                                ? imageUrl
                                : 'http://localhost:8080/api/files/$imageUrl',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFFF1F2F6),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFF1F2F6),
                              child: const Icon(CupertinoIcons.photo, size: 20, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // ─── Сообщение клиента ─────────────────────────────
              if (invitation.clientComment != null && invitation.clientComment!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💬 Сообщение от клиента:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB2BEC3),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invitation.clientComment!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          color: Color(0xFF2D3436),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ─── Кнопки ─────────────────────────────────────────
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewJobDetails(invitation),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Детали',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFF6C5CE7)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewClientProfile(invitation),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF0984E3), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Профиль',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFF0984E3)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCounterOfferDialog(invitation),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: const BorderSide(color: Color(0xFFFFA94D), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Предложить цену',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFFFA94D)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptInvitation(invitation.id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: const Color(0xFF20BF6B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Принять',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _declineInvitation(invitation.id),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEB3B5A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Отклонить',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(CleanerInvitation invitation) {
    final isAccepted = invitation.status == 'ACCEPTED';
    final isDeclined = invitation.status == 'DECLINED';
    final isExpired = invitation.isExpired;
    final images = invitation.imageObjectNames ?? [];

    Color color;
    IconData icon;
    String statusText;

    if (isAccepted) {
      color = const Color(0xFF20BF6B);
      icon = CupertinoIcons.checkmark_alt_circle_fill;
      statusText = 'Принято';
    } else if (isDeclined) {
      color = const Color(0xFFEB3B5A);
      icon = CupertinoIcons.xmark_circle_fill;
      statusText = 'Отклонено';
    } else {
      color = const Color(0xFFB2BEC3);
      icon = CupertinoIcons.time_solid;
      statusText = 'Истекло';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    invitation.serviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins',
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F2F6)),
            const SizedBox(height: 12),
            _invitationInfoRow(CupertinoIcons.person, 'Клиент: ${invitation.clientName}'),
            const SizedBox(height: 6),
            _invitationInfoRow(CupertinoIcons.money_rubl, 'Цена: ${invitation.proposedPrice.toInt()} ₸'),
            const SizedBox(height: 6),
            _invitationInfoRow(CupertinoIcons.location, invitation.orderAddress),
            if (images.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length > 4 ? 4 : images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = images[index];
                    return Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDFE6E9), width: 0.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl.startsWith('http')
                              ? imageUrl
                              : 'http://localhost:8080/api/files/$imageUrl',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF1F2F6),
                            child: const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF1F2F6),
                            child: const Icon(CupertinoIcons.photo, size: 18, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _invitationInfoRow(IconData icon, String text, {bool isPrice = false, bool isGrey = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: isPrice ? const Color(0xFF6C5CE7) : const Color(0xFFB2BEC3)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isPrice ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Poppins',
              color: isPrice
                  ? const Color(0xFF6C5CE7)
                  : isGrey
                  ? const Color(0xFFB2BEC3)
                  : const Color(0xFF636E72),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _acceptInvitation(int invitationId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Принять приглашение', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
          content: const Text('Вы уверены, что хотите принять это приглашение?', style: TextStyle(fontFamily: 'Poppins')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20BF6B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Принять', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final notifier = ref.read(invitationProvider.notifier);
        await notifier.acceptInvitation(invitationId);
        await notifier.loadCleanerInvitations();

        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Приглашение принято!');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  Future<void> _declineInvitation(int invitationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Отклонить приглашение', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: const Text('Вы уверены, что хотите отклонить это приглашение?', style: TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB3B5A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Отклонить', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(invitationProvider.notifier);
        await notifier.declineInvitation(invitationId);
        await notifier.loadCleanerInvitations();

        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Приглашение отклонено');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Ошибка: $e');
        }
      }
    }
  }

  Future<void> _showCounterOfferDialog(CleanerInvitation invitation) async {
    final priceController = TextEditingController(
      text: invitation.proposedPrice.toString(),
    );
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '💰 Встречное предложение',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Предложите свою цену',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: priceController,
                label: 'Ваша цена (₸)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
              ),
              const SizedBox(height: 12),
              const Text(
                'Комментарий (необязательно)',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: messageController,
                label: 'Сообщение',
                maxLines: 3,
                prefixIcon: Icons.message,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price == null || price <= 0) {
                CustomSnackbar.showError(context, 'Введите корректную цену');
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Отправить', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      final price = double.parse(priceController.text);
      final message = messageController.text;

      try {
        final notifier = ref.read(invitationProvider.notifier);
        await notifier.counterOffer(invitation.id, price, message.isNotEmpty ? message : null);
        await notifier.loadCleanerInvitations();

        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Встречное предложение отправлено!');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Ошибка: $e');
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _FilterChip {
  final String value;
  final String label;
  final IconData icon;
  const _FilterChip({
    required this.value,
    required this.label,
    required this.icon,
  });
}