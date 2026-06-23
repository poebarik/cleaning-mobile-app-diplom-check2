import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateProvider to track active tab: 0=Home, 1=Orders, 2=Offers/Responses, 3=Profile
final clientTabProvider = StateProvider<int>((ref) => 0);
