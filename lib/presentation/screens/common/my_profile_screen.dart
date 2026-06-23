// lib/presentation/screens/common/my_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/repositories/cleaner_repository.dart';
import '../../../domain/entities/user_entity.dart';
// ✅ Импортируем Review из review.dart с алиасом ReviewModel
import '../../../data/models/review/review.dart' as review_model;
// ✅ Импортируем Cleaner из cleaner.dart (в нем тоже есть Review, но мы не используем его)
import '../../../data/models/cleaner/cleaner.dart';
import '../../../domain/enums/user_role.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../routes/route_names.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  // ─── Состояние ──────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _showMyReviews = true;
  bool _showAllReviews = false;
  bool _isLoadingCleaner = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ─── Контроллеры ──────────────────────────────────────────────────
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  // ─── Репозитории ──────────────────────────────────────────────────
  final UserRepository _userRepository = UserRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();
  final CleanerRepository _cleanerRepository = CleanerRepository();

  Cleaner? _cleanerData;

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
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _descriptionController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCleanerDataIfNeeded();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ Загрузка данных клинера
  Future<void> _loadCleanerDataIfNeeded() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthStateAuthenticated) return;

    final user = authState.user;
    if (user.role != UserRole.cleaner || user.cleanerId == null || user.cleanerId! <= 0) return;

    setState(() => _isLoadingCleaner = true);
    try {
      final cleaner = await _cleanerRepository.getCleanerById(user.cleanerId!);
      setState(() {
        _cleanerData = cleaner;
        _isLoadingCleaner = false;
      });
    } catch (e) {
      print('❌ Ошибка загрузки данных клинера: $e');
      setState(() => _isLoadingCleaner = false);
    }
  }

  void _loadUserData(UserEntity user) {
    if (_nameController.text.isEmpty) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _descriptionController.text = user.description ?? '';
    }
  }

  // ─── BottomSheet: Редактирование профиля ──────────────────────────

  void _showEditProfileSheet() {
    final authState = ref.read(authProvider);
    if (authState is AuthStateAuthenticated) {
      final user = authState.user;
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? '';
      _descriptionController.text = user.description ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Редактирование профиля',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _darkText,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSheetTextField(
                    controller: _nameController,
                    label: 'Имя',
                  ),
                  const SizedBox(height: 12),
                  _buildSheetTextField(
                    controller: _phoneController,
                    label: 'Телефон',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildSheetTextField(
                    controller: _descriptionController,
                    label: 'О себе',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: _lightGray),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Отмена',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: _grayText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _updateProfileFromSheet(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _primaryPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Сохранить',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateProfileFromSheet(BuildContext context) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty && phone.isEmpty && description.isEmpty) {
      CustomSnackbar.showError(context, 'Заполните хотя бы одно поле');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedUser = await _userRepository.updateProfile(
        name: name.isNotEmpty ? name : null,
        phone: phone.isNotEmpty ? phone : null,
        description: description.isNotEmpty ? description : null,
      );

      final authState = ref.read(authProvider);
      if (authState is AuthStateAuthenticated) {
        final oldUser = authState.user;
        final newUser = UserEntity(
          id: oldUser.id,
          fullName: updatedUser.fullName ?? oldUser.fullName,
          email: oldUser.email,
          phone: updatedUser.phone ?? oldUser.phone,
          role: oldUser.role,
          isActive: oldUser.isActive,
          avatar: oldUser.avatar,
          rating: oldUser.rating,
          completedOrders: oldUser.completedOrders,
          cleanerId: oldUser.cleanerId,
          description: updatedUser.description ?? oldUser.description,
        );
        ref.read(authProvider.notifier).updateUser(newUser);
      }

      ref.invalidate(profileProvider(updatedUser.id));

      setState(() => _isLoading = false);
      Navigator.pop(context);

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Профиль обновлен');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  // ─── BottomSheet: Смена пароля ────────────────────────────────────

  void _showChangePasswordSheet() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Смена пароля',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _darkText,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSheetTextField(
                    controller: _currentPasswordController,
                    label: 'Текущий пароль',
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSheetTextField(
                    controller: _newPasswordController,
                    label: 'Новый пароль',
                    obscureText: true,
                    helperText: 'Минимум 6 символов',
                  ),
                  const SizedBox(height: 12),
                  _buildSheetTextField(
                    controller: _confirmPasswordController,
                    label: 'Подтвердите пароль',
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: _lightGray),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Отмена',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: _grayText,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _changePasswordFromSheet(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _accentRed,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Сменить',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changePasswordFromSheet(BuildContext context) async {
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty) {
      CustomSnackbar.showError(context, 'Введите текущий пароль');
      return;
    }
    if (newPass.isEmpty) {
      CustomSnackbar.showError(context, 'Введите новый пароль');
      return;
    }
    if (newPass.length < 6) {
      CustomSnackbar.showError(context, 'Пароль должен быть не менее 6 символов');
      return;
    }
    if (newPass != confirmPass) {
      CustomSnackbar.showError(context, 'Пароли не совпадают');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _userRepository.changePassword(
        currentPassword: currentPass,
        newPassword: newPass,
      );

      setState(() {
        _isLoading = false;
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });

      Navigator.pop(context);

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Пароль успешно изменен');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMessage = 'Ошибка смены пароля';
        if (e.toString().contains('401')) {
          errorMessage = 'Неверный текущий пароль';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Некорректный запрос. Проверьте введенные данные';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Внутренняя ошибка сервера. Попробуйте позже';
        }
        CustomSnackbar.showError(context, errorMessage);
      }
    }
  }

  // ─── BottomSheet: Мои отзывы ──────────────────────────────────────

  void _showReviewsSheet(UserEntity user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Мои отзывы',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _darkText,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _bgLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              label: 'Мои',
                              isSelected: _showMyReviews,
                              onTap: () => setSheetState(() {
                                _showMyReviews = true;
                                _showAllReviews = false;
                              }),
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton(
                              label: 'Обо мне',
                              isSelected: !_showMyReviews,
                              onTap: () => setSheetState(() {
                                _showMyReviews = false;
                                _showAllReviews = false;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _showMyReviews
                          ? _buildMyReviewsSheet(scrollController)
                          : _buildReviewsAboutMeSheet(user, scrollController),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ✅ Используем review_model.Review для списка отзывов
  Widget _buildMyReviewsSheet(ScrollController scrollController) {
    return FutureBuilder<List<review_model.Review>>(
      future: _reviewRepository.getMyReviews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: _accentRed, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Ошибка загрузки',
                  style: TextStyle(color: _grayText, fontFamily: 'Poppins'),
                ),
              ],
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return _buildEmptyState(
            icon: Icons.rate_review_outlined,
            text: 'Вы еще не оставляли отзывы',
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: reviews.length,
          itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
        );
      },
    );
  }

  Widget _buildReviewsAboutMeSheet(UserEntity user, ScrollController scrollController) {
    return FutureBuilder(
      future: Future.wait([
        _reviewRepository.getUserReviews(user.id),
        _reviewRepository.getUserAverageRating(user.id),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _primaryPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Ошибка загрузки',
              style: TextStyle(color: _grayText, fontFamily: 'Poppins'),
            ),
          );
        }

        final data = snapshot.data;
        final reviews = data != null && data.isNotEmpty ? data[0] as List<review_model.Review> : [];
        final averageRating =
        data != null && data.length > 1 ? data[1] as double? : null;

        if (reviews.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_outline,
            text: 'Пока нет отзывов о вас',
          );
        }

        return Column(
          children: [
            if (averageRating != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _primaryPurple.withOpacity(0.1),
                      _secondaryPurple.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryPurple.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Средний рейтинг',
                            style: TextStyle(
                              fontSize: 11,
                              color: _grayText,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: _darkText,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${reviews.length} ${_getReviewsWord(reviews.length)})',
                                style: TextStyle(
                                  color: _grayText,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: reviews.length,
                itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Общий TextField для BottomSheet ─────────────────────────────

  Widget _buildSheetTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: _lightGray,
          fontSize: 14,
        ),
        helperText: helperText,
        helperStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: _lightGray,
          fontSize: 11,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEEF0F5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEEF0F5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryPurple, width: 1.5),
        ),
        filled: true,
        fillColor: _bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: _darkText,
        fontSize: 14,
      ),
    );
  }

  // ─── Смена аватарки ───────────────────────────────────────────────

  Future<void> _changeAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final avatarUrl = await _userRepository.uploadAvatar(pickedFile);

      final authState = ref.read(authProvider);
      if (authState is AuthStateAuthenticated) {
        final oldUser = authState.user;
        final newUser = UserEntity(
          id: oldUser.id,
          fullName: oldUser.fullName,
          email: oldUser.email,
          phone: oldUser.phone,
          role: oldUser.role,
          isActive: oldUser.isActive,
          avatar: avatarUrl,
          rating: oldUser.rating,
          completedOrders: oldUser.completedOrders,
          cleanerId: oldUser.cleanerId,
          description: oldUser.description,
        );
        ref.read(authProvider.notifier).updateUser(newUser);
      }

      setState(() => _isLoading = false);

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Аватар обновлен');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String errorMessage = 'Ошибка загрузки аватарки';
        if (e.toString().contains('MultipartFile')) {
          errorMessage = 'Проблема с загрузкой файла. Попробуйте еще раз.';
        } else if (e.toString().contains('_Namespace')) {
          errorMessage = 'Ошибка на веб-платформе. Попробуйте использовать мобильное приложение.';
        }
        CustomSnackbar.showError(context, errorMessage);
      }
    }
  }

  // ─── Выход ─────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Выход из аккаунта',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            color: _darkText,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Вы уверены, что хотите выйти? Вам придется войти снова, чтобы продолжить.',
          style: TextStyle(fontFamily: 'Poppins', color: _grayText, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _lightGray),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: _grayText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _accentRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Выйти',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Ошибка выхода: $e');
        }
      }
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthStateAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _bgCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 56, color: _primaryPurple),
              ),
              const SizedBox(height: 20),
              const Text(
                'Пожалуйста, войдите в систему',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: CustomButton(
                  onPressed: () => context.go('/login'),
                  text: 'Войти',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = authState.user;
    _loadUserData(user);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(color: _primaryPurple),
              )
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeroSection(user),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildInfoCard(user),
                          const SizedBox(height: 16),
                          _buildMenuSection(user),
                          const SizedBox(height: 16),
                          if (user.role == UserRole.cleaner) ...[
                            if (_isLoadingCleaner)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _primaryPurple,
                                    ),
                                  ),
                                ),
                              )
                            else
                              _buildCleanerSection(),
                            const SizedBox(height: 16),
                          ],
                          _buildLogoutButton(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Section ─────────────────────────────────────────────────

  // ─── Hero Section ─────────────────────────────────────────────────

  Widget _buildHeroSection(UserEntity user) {
    final hasAvatar = user.avatar != null && user.avatar!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryPurple, _secondaryPurple],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Мой профиль',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _changeAvatar,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: hasAvatar
                              ? CachedNetworkImage(
                            imageUrl: user.avatar!,
                            fit: BoxFit.cover,
                            width: 112,
                            height: 112,
                            placeholder: (context, url) => Container(
                              color: _bgCard,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _primaryPurple,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildAvatarPlaceholder(user),
                          )
                              : _buildAvatarPlaceholder(user),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: _primaryPurple,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getRoleText(user.role.name),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      if (user.role == UserRole.cleaner && user.rating != null) ...[
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 1,
                          height: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          user.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  Widget _buildAvatarPlaceholder(UserEntity user) {
    return Container(
      width: 112,
      height: 112,
      color: _bgCard,
      child: Center(
        child: Text(
          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: _primaryPurple,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // ─── Info Card ────────────────────────────────────────────────────

  Widget _buildInfoCard(UserEntity user) {
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
          const Text(
            'Личная информация',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: _darkText,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Email', user.email),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Телефон',
            user.phone.isNotEmpty ? user.phone : 'Не указан',
          ),
          if (user.description != null && user.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('О себе', user.description!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: _lightGray,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _darkText,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Menu Section ──────────────────────────────────────────────────

  Widget _buildMenuSection(UserEntity user) {
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
      child: Column(
        children: [
          _buildMenuItem(
            title: 'Редактировать профиль',
            subtitle: 'Изменить имя, телефон и описание',
            onTap: _showEditProfileSheet,
            gradientColors: const [_primaryPurple, _secondaryPurple],
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            title: 'Сменить пароль',
            subtitle: 'Обновить пароль для безопасности',
            onTap: _showChangePasswordSheet,
            gradientColors: const [_accentRed, Color(0xFFFF8E8E)],
          ),
          _buildMenuDivider(),
          _buildMenuItem(
            title: 'Мои отзывы',
            subtitle: 'Посмотреть оставленные и полученные',
            onTap: () => _showReviewsSheet(user),
            gradientColors: const [_accentTeal, Color(0xFF55EFC4)],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Color> gradientColors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _lightGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _bgLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _lightGray,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFEEF0F5),
      indent: 34,
    );
  }

  // ─── Cleaner Section ──────────────────────────────────────────────

  Widget _buildCleanerSection() {
    final status = _cleanerData?.verificationStatus;
    final isVerified = status == 'VERIFIED';
    final isPending = status == 'PENDING';
    final isRejected = status == 'REJECTED';

    String subtitle;
    List<Color> gradientColors;

    if (isVerified) {
      subtitle = '✅ Профиль подтвержден';
      gradientColors = const [_successGreen, Color(0xFF55EFC4)];
    } else if (isPending) {
      subtitle = '⏳ Верификация на проверке';
      gradientColors = const [_accentOrange, Color(0xFFFFD180)];
    } else if (isRejected) {
      subtitle = '❌ Верификация отклонена';
      gradientColors = const [_accentRed, Color(0xFFFF8E8E)];
    } else {
      subtitle = 'Пройдите верификацию для доверия клиентов';
      gradientColors = const [_accentOrange, Color(0xFFFFD180)];
    }

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
      child: Column(
        children: [
          _buildMenuItem(
            title: 'Верификация клинера',
            subtitle: subtitle,
            onTap: () {
              context.push('/cleaner-verification').then((_) {
                _loadCleanerDataIfNeeded();
              });
            },
            gradientColors: gradientColors,
          ),
        ],
      ),
    );
  }

  // ─── Logout Button ────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _accentRed.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accentRed.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Выйти из аккаунта',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Завершить текущую сессию',
                      style: TextStyle(
                        fontSize: 12,
                        color: _lightGray,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _lightGray,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Segment Button ──────────────────────────────────────────────

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
              color: isSelected ? _primaryPurple : _lightGray,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: _lightGray),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                color: _grayText,
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Используем review_model.Review для карточки отзыва
  Widget _buildReviewCard(review_model.Review review) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(16),
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
                  gradient: const LinearGradient(
                    colors: [_primaryPurple, _secondaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    review.authorName.isNotEmpty
                        ? review.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        color: _darkText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                            (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 12,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 12,
                color: _grayText,
                height: 1.4,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _formatDate(review.createdAt),
            style: TextStyle(
              fontSize: 10,
              color: _lightGray,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  String _getRoleText(String role) {
    switch (role.toUpperCase()) {
      case 'CLIENT':
        return 'Клиент';
      case 'CLEANER':
        return 'Клинер';
      case 'MANAGER':
        return 'Менеджер';
      case 'ADMIN':
        return 'Администратор';
      default:
        return role;
    }
  }

  String _getReviewsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'отзыв';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'отзыва';
    }
    return 'отзывов';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}