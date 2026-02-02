import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CguNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('cgu_accepted') ?? false;
  }

  Future<void> acceptCgu() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cgu_accepted', true);
      return true;
    });
  }
}

final cguProvider = AsyncNotifierProvider<CguNotifier, bool>(() {
  return CguNotifier();
});
