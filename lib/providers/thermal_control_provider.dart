import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThermalControlState {
  final bool isEconomyMode;
  final bool isLowBattery;

  const ThermalControlState({
    this.isEconomyMode = false,
    this.isLowBattery = false,
  });

  ThermalControlState copyWith({
    bool? isEconomyMode,
    bool? isLowBattery,
  }) {
    return ThermalControlState(
      isEconomyMode: isEconomyMode ?? this.isEconomyMode,
      isLowBattery: isLowBattery ?? this.isLowBattery,
    );
  }
}

class ThermalControlNotifier extends StateNotifier<ThermalControlState> {
  ThermalControlNotifier() : super(const ThermalControlState()) {
    // In a real app, we would listen to Battery state here using battery_plus package
    // For now, we simulate or allow manual toggle
    _initThermalMonitoring();
  }

  void _initThermalMonitoring() {
    // Placeholder for battery monitoring logic
    // checkBatteryLevel();
  }

  void setEconomyMode(bool enabled) {
    state = state.copyWith(isEconomyMode: enabled);
  }

  void setLowBattery(bool low) {
    bool shouldBeEco = low || state.isEconomyMode; // If low battery, force eco?
    if (low) shouldBeEco = true;
    
    state = state.copyWith(
      isLowBattery: low,
      isEconomyMode: shouldBeEco,
    );
  }
}

final thermalControlProvider = StateNotifierProvider<ThermalControlNotifier, ThermalControlState>((ref) {
  return ThermalControlNotifier();
});
