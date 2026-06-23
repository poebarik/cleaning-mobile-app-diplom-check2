import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateProvider to track active tab for manager:
// 0=Dashboard, 1=PendingOrders, 2=Cleaners, 3=Verifications, 4=Profile
final managerTabProvider = StateProvider<int>((ref) => 0);
