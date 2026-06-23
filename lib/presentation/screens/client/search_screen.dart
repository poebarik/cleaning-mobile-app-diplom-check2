// lib/presentation/screens/client/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/service_provider.dart';
import '../../../data/models/service/popular_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Все';
  double? _minPrice;
  double? _maxPrice;
  bool _isPopular = false;
  bool _showFilters = false;

  late Debouncer<String> _debouncer;

  final Map<String, String> _categoryIcons = {
    'Все': '🏠',
    'HOME': '🏡',
    'OFFICE': '🏢',
    'FURNITURE': '🪑',
    'SPECIAL': '⭐',
    'CAR': '🚗',
    'REPAIR': '🔧',
  };

  final Map<String, String> _categoryLabels = {
    'Все': 'Все',
    'HOME': 'Дом',
    'OFFICE': 'Офис',
    'FURNITURE': 'Мебель',
    'SPECIAL': 'Спец. услуги',
    'CAR': 'Авто',
    'REPAIR': 'Ремонт',
  };

  // ✅ Градиенты для категорий
  final Map<String, List<Color>> _categoryGradients = {
    'HOME': [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
    'OFFICE': [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
    'FURNITURE': [const Color(0xFFFFA94D), const Color(0xFFFFCC80)],
    'SPECIAL': [const Color(0xFF00CEC9), const Color(0xFF55EFC4)],
    'CAR': [const Color(0xFF0984E3), const Color(0xFF74B9FF)],
    'REPAIR': [const Color(0xFF6C5CE7), const Color(0xFFFF7675)],
  };

  @override
  void initState() {
    super.initState();

    _debouncer = Debouncer<String>(
      const Duration(milliseconds: 500),
      initialValue: '',
      checkEquality: true,
    );

    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(allServicesProvider.notifier).loadWithFilters();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    _debouncer.setValue(query);
    _debouncer.values.listen((value) {
      if (mounted) {
        setState(() {
          _searchQuery = value;
        });
        _performSearch(value);
      }
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      ref.read(allServicesProvider.notifier).loadWithFilters(
        category: _selectedCategory == 'Все' ? null : _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        isPopular: _isPopular ? true : null,
      );
    } else {
      ref.read(searchServicesProvider(query).future).then((results) {
        ref.read(allServicesProvider.notifier).updateResults(results);
      }).catchError((error) {
        print('❌ Ошибка поиска: $error');
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    ref.read(allServicesProvider.notifier).loadWithFilters(
      category: _selectedCategory == 'Все' ? null : _selectedCategory,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      isPopular: _isPopular ? true : null,
    );
  }

  void _applyFilters() {
    setState(() {
      _showFilters = false;
    });

    final category = _selectedCategory == 'Все' ? null : _selectedCategory;
    final query = _searchController.text.trim();

    if (query.isNotEmpty) {
      ref.read(searchServicesProvider(query).future).then((results) {
        var filtered = results;

        if (category != null) {
          filtered = filtered.where((s) => s.category == category).toList();
        }
        if (_minPrice != null) {
          filtered = filtered.where((s) => s.price != null && s.price! >= _minPrice!).toList();
        }
        if (_maxPrice != null) {
          filtered = filtered.where((s) => s.price != null && s.price! <= _maxPrice!).toList();
        }
        if (_isPopular) {
          filtered = filtered.where((s) => s.isPopular).toList();
        }

        ref.read(allServicesProvider.notifier).updateResults(filtered);
      });
    } else {
      ref.read(allServicesProvider.notifier).loadWithFilters(
        category: category,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        isPopular: _isPopular ? true : null,
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Все';
      _minPrice = null;
      _maxPrice = null;
      _isPopular = false;
      _searchController.clear();
      _searchQuery = '';
    });
    ref.read(allServicesProvider.notifier).loadWithFilters();
  }

  // ✅ Метод для получения градиента услуги
  List<Color> _getServiceGradient(PopularService service) {
    if (service.category == 'HOME') {
      return [const Color(0xFF6C5CE7), const Color(0xFF8B7FF0)];
    } else if (service.category == 'FURNITURE') {
      return [const Color(0xFFFFA94D), const Color(0xFFFFCC80)];
    } else if (service.category == 'SPECIAL') {
      return [const Color(0xFF00CEC9), const Color(0xFF55EFC4)];
    } else if (service.category == 'CAR') {
      return [const Color(0xFF0984E3), const Color(0xFF74B9FF)];
    } else if (service.category == 'OFFICE') {
      return [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)];
    }
    return [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)];
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final servicesState = ref.watch(allServicesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2D3436), size: 18),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EFF8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(
                Icons.search,
                size: 20,
                color: Color(0xFF6C5CE7),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Поиск услуг...',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9E9E9E),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                      onPressed: _clearSearch,
                    )
                        : null,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D3436),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
              color: _showFilters ? const Color(0xFF6C5CE7) : Colors.grey.shade600,
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(categoriesAsync),
          Expanded(
            child: servicesState.when(
              data: (services) {
                if (_searchQuery.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Row(
                          children: [
                            Text(
                              'Найдено',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${services.length}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6C5CE7),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              ' результатов',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(services[index]);
                          },
                        ),
                      ),
                    ],
                  );
                }

                if (services.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return _buildServiceCard(services[index]);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C5CE7),
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Загрузка услуг...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'Ошибка загрузки',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3436),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Не удалось загрузить услуги',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(allServicesProvider.notifier).loadWithFilters();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C5CE7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Повторить',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AsyncValue<List<String>> categoriesAsync) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Фильтры',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3436),
                  fontFamily: 'Poppins',
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6C5CE7),
                ),
                child: const Text(
                  'Сбросить',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Категория',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          categoriesAsync.when(
            data: (categories) {
              final allCategories = ['Все', ...categories];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allCategories.map((category) {
                  final isSelected = category == _selectedCategory;
                  final icon = _categoryIcons[category] ?? '🏠';
                  final label = _categoryLabels[category] ?? category;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: _categoryGradients[category] ??
                              [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
                        )
                            : null,
                        color: isSelected ? null : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            icon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),
          Text(
            'Цена',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'От',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    _minPrice = double.tryParse(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'До',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    _maxPrice = double.tryParse(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isPopular,
                onChanged: (value) {
                  setState(() {
                    _isPopular = value ?? false;
                  });
                },
                activeColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Только популярные',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Применить фильтры',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(PopularService service) {
    final gradients = _getServiceGradient(service);
    final textColor = Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradients.first.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Декор фон
          Positioned(
            right: -15,
            top: -15,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 15,
            bottom: -25,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Большой emoji декор
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: 0.2,
                child: Text(
                  service.icon ?? '🧹',
                  style: const TextStyle(fontSize: 70),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    service.icon ?? '🧹',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  service.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontFamily: 'Poppins',
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (service.description != null &&
                    service.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 200,
                    child: Text(
                      service.description!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: textColor.withOpacity(0.8),
                        fontFamily: 'Poppins',
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (service.price != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'от',
                            style: TextStyle(
                              fontSize: 10,
                              color: textColor.withOpacity(0.75),
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            '${service.price!.toInt()} ₸',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    GestureDetector(
                      onTap: () {
                        context.push(
                          '/draft-order',
                          extra: {
                            'cleaningType': service.defaultCleaningType ?? 'CUSTOM',
                            'serviceName': service.name,
                            'serviceId': service.id,
                            'servicePrice': service.price,
                            'serviceDescription': service.description,
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'Заказать',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: gradients.first,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF6C5CE7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Ничего не найдено',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D3436),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Попробуйте изменить параметры поиска',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Сбросить фильтры',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
}