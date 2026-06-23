import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/cleaner_nav_provider.dart';
import 'home_screen.dart';
import 'assigned_orders_screen.dart';
import 'my_invitations_screen.dart';
import '../common/my_profile_screen.dart';

class CleanerMainScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const CleanerMainScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<CleanerMainScreen> createState() => _CleanerMainScreenState();
}

class _CleanerMainScreenState extends ConsumerState<CleanerMainScreen>
    with TickerProviderStateMixin {
  late AnimationController _navAnimController;

  @override
  void initState() {
    super.initState();
    _navAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cleanerTabProvider.notifier).state = widget.initialTab;
    });
  }

  @override
  void didUpdateWidget(CleanerMainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cleanerTabProvider.notifier).state = widget.initialTab;
      });
    }
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(cleanerTabProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: IndexedStack(
        index: activeTab,
        children: const [
          CleanerHomeScreen(),
          AssignedOrdersScreen(),
          MyInvitationsScreen(),
          MyProfileScreen(),
        ],
      ),
      bottomNavigationBar: _PremiumBottomNav(
        activeIndex: activeTab,
        onTap: (index) {
          ref.read(cleanerTabProvider.notifier).state = index;
        },
      ),
    );
  }
}

// ─── Premium animated bottom navigation ──────────────────────────────────────

class _PremiumBottomNav extends StatefulWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _PremiumBottomNav({
    required this.activeIndex,
    required this.onTap,
  });

  @override
  State<_PremiumBottomNav> createState() => _PremiumBottomNavState();
}

class _PremiumBottomNavState extends State<_PremiumBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  int _prevIndex = 0;

  static const _primaryColor = Color(0xFF6C5CE7);
  static const _inactiveColor = Color(0xFFB2BEC3);

  final _items = const [
    _NavItem(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Главная',
    ),
    _NavItem(
      icon: CupertinoIcons.briefcase,
      activeIcon: CupertinoIcons.briefcase_fill,
      label: 'Заказы',
    ),
    _NavItem(
      icon: CupertinoIcons.mail,
      activeIcon: CupertinoIcons.mail,
      label: 'Приглашения',
    ),
    _NavItem(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      label: 'Профиль',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _prevIndex = widget.activeIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(_PremiumBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _prevIndex = oldWidget.activeIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final isActive = index == widget.activeIndex;
              return _buildNavItem(index, isActive);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isActive) {
    final item = _items[index];

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(index),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final scale = (index == widget.activeIndex && _prevIndex != index)
                ? _scaleAnim.value
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: isActive ? 48 : 36,
                height: isActive ? 36 : 36,
                decoration: isActive
                    ? BoxDecoration(
                        color: _primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      )
                    : null,
                child: Center(
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: isActive ? 22 : 22,
                    color: isActive ? _primaryColor : _inactiveColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? _primaryColor : _inactiveColor,
                  fontFamily: 'Poppins',
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
