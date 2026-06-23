import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order/order_specification_dto.dart';
import '../../../routes/route_names.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../providers/auth_provider.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final int orderId;
  final Map<String, dynamic>? orderData;
  const OrderDetailsScreen({super.key, required this.orderId, this.orderData});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;
  bool _isReviewing = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final _steps = [
    {'key': 'PENDING', 'label': 'Создан', 'icon': Icons.add_circle_outline_rounded},
    {'key': 'ACCEPTED', 'label': 'Принят', 'icon': Icons.check_circle_outline_rounded},
    {'key': 'IN_PROGRESS', 'label': 'В процессе', 'icon': Icons.autorenew_rounded},
    {'key': 'COMPLETED', 'label': 'Завершён', 'icon': Icons.verified_rounded},
  ];

  // ─── Цветовая палитра ─────────────────────────────────────────────
  static const Color _primaryPurple = Color(0xFF6C5CE7);
  static const Color _secondaryPurple = Color(0xFFA29BFE);
  static const Color _accentTeal = Color(0xFF00CEC9);
  static const Color _accentOrange = Color(0xFFFFA94D);
  static const Color _accentRed = Color(0xFFFF6B6B);
  static const Color _successGreen = Color(0xFF00B894);
  static const Color _darkText = Color(0xFF2D3436);
  static const Color _grayText = Color(0xFF636E72);
  static const Color _lightGray = Color(0xFFB2BEC3);
  static const Color _bgLight = Color(0xFFF8F9FA);
  static const Color _bgCard = Color(0xFFF0EFF8);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    if (widget.orderData != null) {
      _order = widget.orderData;
      _isLoading = false;
    } else {
      _loadOrder();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = DioClient.instance;
      final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.orders}/${widget.orderId}');
      if (response.statusCode == 200) {
        setState(() { _order = response.data; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadOrderDetails() async {
    await _loadOrder();
  }

  int getCurrentStepIndex() {
    final status = _order?['status'] ?? 'PENDING';
    return _steps.indexWhere((s) => s['key'] == status);
  }

  int? _getCleanerIdFromResponses() {
    final responses = _order!['responses'] as List?;
    if (responses == null) return null;

    for (var response in responses) {
      final status = response['status'] as String?;
      if (status == 'ACCEPTED' || status == 'SELECTED') {
        return response['cleanerId'] as int?;
      }
    }
    return null;
  }

  Future<int?> _getUserIdByCleanerId(int cleanerId) async {
    try {
      final dio = DioClient.instance;
      final response = await dio.get('${ApiConstants.baseUrl}/cleaners/$cleanerId');
      final cleanerData = response.data;

      int? userId = cleanerData['userId'] as int?;
      if (userId == null || userId == 0) {
        userId = cleanerData['user']['id'] as int?;
      }
      if (userId == null || userId == 0) {
        userId = cleanerData['user_id'] as int?;
      }

      print('🔍 Cleaner $cleanerId -> UserId: $userId');
      return userId;
    } catch (e) {
      print('Error getting user id for cleaner $cleanerId: $e');
      return null;
    }
  }

  Future<bool> _hasUserReviewed() async {
    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return true;

    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConstants.baseUrl}/reviews/check',
        queryParameters: {
          'orderId': widget.orderId,
          'reviewerId': currentUser.id,
        },
      );
      return response.data == true;
    } catch (e) {
      print('Error checking review: $e');
      return false;
    }
  }

  Widget _buildReviewButton() {
    if (_order == null) return const SizedBox.shrink();

    final status = (_order!['status'] ?? '').toString().toUpperCase();
    final isCompleted = status == 'COMPLETED';

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return const SizedBox.shrink();

    final isClient = currentUser.role.toString().toUpperCase().contains('CLIENT');

    if (!isClient) return const SizedBox.shrink();

    int? cleanerId = _order!['selectedCleanerId'] as int?;
    if (cleanerId == null || cleanerId == 0) {
      cleanerId = _order!['cleanerId'] as int?;
    }
    if (cleanerId == null || cleanerId == 0) {
      cleanerId = _getCleanerIdFromResponses();
    }

    final targetCleanerId = cleanerId ?? 0;
    final cleanerName = _order!['selectedCleanerName'] as String? ??
        _order!['cleanerName'] as String? ??
        'Клинера';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FutureBuilder<bool>(
        future: isCompleted ? _hasUserReviewed() : Future.value(true),
        builder: (context, snapshot) {
          final hasReviewed = snapshot.data ?? false;
          final canReview = isCompleted && targetCleanerId != 0 && !hasReviewed;

          return Column(
            children: [
              CustomButton(
                onPressed: canReview && !_isReviewing
                    ? () async {
                  setState(() => _isReviewing = true);
                  final targetUserId = await _getUserIdByCleanerId(targetCleanerId);

                  if (targetUserId == null || targetUserId == 0) {
                    CustomSnackbar.showError(context, 'Не удалось определить пользователя для отзыва');
                    setState(() => _isReviewing = false);
                    return;
                  }

                  setState(() => _isReviewing = false);

                  context.push(
                    '/create-review',
                    extra: {
                      'orderId': widget.orderId,
                      'targetUserId': targetUserId,
                      'targetUserName': cleanerName,
                      'reviewType': 'CLIENT_TO_CLEANER',
                    },
                  ).then((needRefresh) {
                    if (needRefresh == true) {
                      _loadOrderDetails();
                    }
                  });
                }
                    : null,
                text: hasReviewed ? 'Отзыв уже оставлен' : 'Оставить отзыв',
                icon: Icons.star_rate_rounded,
                isEnabled: canReview && !_isReviewing,
              ),
              if (!isCompleted && status != 'CANCELLED') ...[
                const SizedBox(height: 8),
                Text(
                  'Отзыв можно оставить только после завершения заказа',
                  style: TextStyle(fontSize: 12, color: _grayText),
                ),
              ],
              if (isCompleted && hasReviewed) ...[
                const SizedBox(height: 8),
                Text(
                  'Вы уже оставили отзыв на этот заказ',
                  style: TextStyle(fontSize: 12, color: _successGreen),
                ),
              ],
              if (isCompleted && targetCleanerId == 0 && !hasReviewed) ...[
                const SizedBox(height: 8),
                Text(
                  'Невозможно оставить отзыв: данные о клинере не найдены',
                  style: TextStyle(fontSize: 12, color: _accentOrange),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhotosCard() {
    List<String> images = [];

    if (_order!['imageObjectNames'] != null && _order!['imageObjectNames'] is List) {
      images = List<String>.from(_order!['imageObjectNames']);
    }

    if (images.isEmpty && _order!['specification'] != null) {
      final spec = _order!['specification'];
      if (spec['imageObjectNames'] != null && spec['imageObjectNames'] is List) {
        images = List<String>.from(spec['imageObjectNames']);
      }
    }

    if (images.isEmpty && _order!['images'] != null && _order!['images'] is List) {
      images = List<String>.from(_order!['images']);
    }

    if (images.isEmpty && _order!['photos'] != null && _order!['photos'] is List) {
      images = List<String>.from(_order!['photos']);
    }

    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, size: 18, color: _primaryPurple),
              ),
              const SizedBox(width: 10),
              const Text(
                'Фотографии помещения',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageUrl = '${ApiConstants.baseUrl}/files/${images[index]}';
                return GestureDetector(
                  onTap: () => _showFullScreenImage(imageUrl),
                  child: Container(
                    width: 120,
                    height: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEF0F5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: _bgLight,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _primaryPurple,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: _bgLight,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            size: 32,
                            color: _lightGray,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black,
                    child: const Icon(Icons.error, size: 50, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryPurple))
          : _error != null
          ? _buildError()
          : _order == null
          ? const Center(child: Text('Заказ не найден'))
          : RefreshIndicator(
        onRefresh: _loadOrder,
        color: _primaryPurple,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildSliverHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeline(),
                      const SizedBox(height: 20),
                      _buildDetailsCard(),
                      const SizedBox(height: 20),
                      if (_order!['description'] != null && _order!['description'] != '')
                        _buildDescriptionCard(),
                      const SizedBox(height: 20),
                      _buildPhotosCard(),
                      const SizedBox(height: 20),
                      _buildSpecificationCard(),
                      const SizedBox(height: 20),
                      if (_order!['cleanerName'] != null)
                        _buildCleanerCard(),
                      const SizedBox(height: 20),
                      _buildReviewButton(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    final status = _order!['status'] ?? 'PENDING';
    final isCancelled = status == 'CANCELLED';

    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryPurple, _secondaryPurple],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
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
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.cleaning_services_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _order!['serviceName'] ?? 'Уборка',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                          ],
                        ),
                      ),
                      StatusChip(status: status, isSmall: true),
                    ],
                  ),
                  if (isCancelled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.cancel_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Заказ отменён',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final stepIdx = getCurrentStepIndex();
    final isCancelled = _order?['status'] == 'CANCELLED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timeline_rounded, size: 18, color: _primaryPurple),
              ),
              const SizedBox(width: 10),
              const Text(
                'Статус заказа',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isCancelled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: _accentRed, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Заказ отменён',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: _accentRed,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: _steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final isDone = i <= stepIdx;
                final isCurrent = i == stepIdx;
                final isLast = i == _steps.length - 1;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: isDone
                                    ? const LinearGradient(
                                  colors: [_primaryPurple, _secondaryPurple],
                                )
                                    : null,
                                color: isDone ? null : _bgLight,
                                shape: BoxShape.circle,
                                border: isCurrent
                                    ? Border.all(color: _primaryPurple, width: 2.5)
                                    : null,
                              ),
                              child: Icon(
                                step['icon'] as IconData,
                                size: 18,
                                color: isDone ? Colors.white : _lightGray,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                                color: isDone ? _primaryPurple : _lightGray,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Container(
                          height: 2,
                          width: 16,
                          color: i < stepIdx ? _primaryPurple : _bgLight,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, size: 18, color: _primaryPurple),
              ),
              const SizedBox(width: 10),
              const Text(
                'Детали заказа',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(Icons.location_on_rounded, 'Адрес', _order!['address'] ?? 'Не указан'),
          _detailRow(Icons.calendar_today_rounded, 'Дата', _formatDate(_order!['orderDate'])),
          if (_order!['budget'] != null)
            _detailRow(Icons.monetization_on_rounded, 'Бюджет', '${_order!['budget']} ₸', isHighlight: true),
          if (_order!['fulfillmentType'] != null)
            _detailRow(Icons.category_rounded, 'Тип', _fulfillmentLabel(_order!['fulfillmentType'])),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _primaryPurple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: _primaryPurple),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: _grayText,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                  color: isHighlight ? _primaryPurple : _darkText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_rounded, size: 18, color: _primaryPurple),
              ),
              const SizedBox(width: 10),
              const Text(
                'Описание',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _order!['description'],
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _grayText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanerCard() {
    final cleanerId = _order!['cleanerId'];
    final cleanerName = _order!['cleanerName'] ?? '';

    if (cleanerId == null || cleanerId == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        context.push('/profile/$cleanerId');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryPurple.withOpacity(0.05), _secondaryPurple.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryPurple.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPurple, _secondaryPurple],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  cleanerName.isNotEmpty ? cleanerName[0].toUpperCase() : 'К',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ваш клинер',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: _grayText,
                    ),
                  ),
                  Text(
                    cleanerName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _darkText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: _primaryPurple,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: _accentRed),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _grayText,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOrder,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Повторить',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: _primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificationCard() {
    final specJson = _order?['specification'];
    if (specJson == null) return const SizedBox.shrink();

    final spec = OrderSpecificationDTO.fromJson(specJson);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: const Text(
          'Детали уборки',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _darkText,
            fontFamily: 'Poppins',
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.assignment_rounded, size: 18, color: _primaryPurple),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (spec.locationType != null)
                  _buildSpecDetailRow('Тип помещения', _getLocationTypeName(spec.locationType!), Icons.location_city),
                if (spec.locationCustom != null)
                  _buildSpecDetailRow('Уточнение', spec.locationCustom!, Icons.edit),
                const Divider(height: 16),
                if (spec.area != null)
                  _buildSpecDetailRow('Площадь', '${spec.area} м²', Icons.square_foot),
                const Divider(height: 16),
                if (spec.cleaningType != null)
                  _buildSpecDetailRow('Тип уборки', _getCleaningTypeName(spec.cleaningType!), Icons.cleaning_services),
                const Divider(height: 16),
                if (spec.rooms != null && spec.rooms!.isNotEmpty)
                  _buildSpecDetailRow('Комнаты', spec.rooms!.map((r) => _getRoomName(r)).join(', '), Icons.home),
                if (spec.roomsCustom != null)
                  _buildSpecDetailRow('Уточнение', spec.roomsCustom!, Icons.edit),
                const Divider(height: 16),
                if (spec.roomsCount != null)
                  _buildSpecDetailRow('Количество комнат', '${spec.roomsCount}', Icons.home),
                if (spec.bathrooms != null)
                  _buildSpecDetailRow('Санузлов', '${spec.bathrooms}', Icons.bathtub),
                const Divider(height: 16),
                if (spec.additionalServices != null && spec.additionalServices!.isNotEmpty)
                  _buildSpecDetailRow('Доп. услуги', spec.additionalServices!.map((s) => _getServiceName(s)).join(', '), Icons.more_horiz),
                if (spec.customServices != null && spec.customServices!.isNotEmpty)
                  _buildSpecDetailRow('Свои услуги', spec.customServices!.join(', '), Icons.add_circle),
                const Divider(height: 16),
                if (spec.inventory != null)
                  _buildSpecDetailRow('Инвентарь', _getInventoryName(spec.inventory!), Icons.inventory),
                const Divider(height: 16),
                if (spec.pricingMode != null)
                  _buildSpecDetailRow('Ценообразование', spec.pricingMode == 'FIXED' ? 'Фиксированная цена' : 'Торг', Icons.attach_money),
                if (spec.price != null)
                  _buildSpecDetailRow('Цена', '${spec.price!.toStringAsFixed(0)} ₸', Icons.attach_money, isHighlight: true),
                if (spec.maxPrice != null)
                  _buildSpecDetailRow('Макс. цена', '${spec.maxPrice!.toStringAsFixed(0)} ₸', Icons.attach_money, isHighlight: true),
                const Divider(height: 16),
                if (spec.hasPets != null)
                  _buildSpecDetailRow('Животные', spec.hasPets! ? 'Есть' : 'Нет', Icons.pets),
                if (spec.notes != null && spec.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Заметки',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: _darkText,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spec.notes!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _grayText,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecDetailRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _grayText),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: _grayText,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? _primaryPurple : _darkText,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocationTypeName(String type) {
    switch (type) {
      case 'APARTMENT': return 'Квартира';
      case 'HOUSE': return 'Дом';
      case 'OFFICE': return 'Офис';
      case 'COMMERCIAL': return 'Коммерческое';
      case 'CUSTOM': return 'Другое';
      default: return type;
    }
  }

  String _getCleaningTypeName(String type) {
    switch (type) {
      case 'MAINTENANCE': return 'Поддерживающая';
      case 'DEEP_CLEANING': return 'Генеральная';
      case 'AFTER_RENOVATION': return 'После ремонта';
      case 'MOVE_IN': return 'Перед заездом';
      case 'MOVE_OUT': return 'После выезда';
      case 'CUSTOM': return 'Другое';
      default: return type;
    }
  }

  String _getRoomName(String room) {
    switch (room) {
      case 'ENTIRE': return 'Вся квартира';
      case 'KITCHEN': return 'Кухня';
      case 'BATHROOM': return 'Санузел';
      case 'BALCONY': return 'Балкон';
      case 'BEDROOM': return 'Спальня';
      case 'LIVING_ROOM': return 'Гостиная';
      case 'CUSTOM': return 'Другое';
      default: return room;
    }
  }

  String _getServiceName(String service) {
    switch (service) {
      case 'WINDOWS': return 'Мытьё окон';
      case 'FRIDGE': return 'Мытьё холодильника';
      case 'OVEN': return 'Мытьё духовки';
      case 'FURNITURE': return 'Химчистка мебели';
      case 'IRONING': return 'Глажка белья';
      default: return service;
    }
  }

  String _getInventoryName(String inventory) {
    switch (inventory) {
      case 'CLIENT': return 'Свой';
      case 'CLEANER': return 'Клинера';
      case 'PARTIAL': return 'Частично';
      default: return inventory;
    }
  }

  String _formatDate(String? ds) {
    if (ds == null) return 'Не указана';
    try {
      final d = DateTime.parse(ds);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ds; }
  }

  String _fulfillmentLabel(String type) {
    switch (type) {
      case 'COMPANY_ASSIGNED': return 'Через компанию';
      case 'MARKETPLACE': return 'Маркетплейс';
      case 'DIRECT_INVITATION': return 'Прямое приглашение';
      default: return type;
    }
  }
}