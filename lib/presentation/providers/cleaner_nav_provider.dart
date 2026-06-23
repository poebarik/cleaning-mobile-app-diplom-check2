import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateProvider to track active tab for cleaner: 0=Home, 1=Orders, 2=Invitations, 3=Profile
final cleanerTabProvider = StateProvider<int>((ref) => 0);
