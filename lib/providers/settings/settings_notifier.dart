import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_state.dart';
import '../../utils/audio_helper.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('theme_mode');
      ThemeMode themeMode;
      
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        themeMode = ThemeMode.values[themeIndex];
        // Si el valor guardado es ThemeMode.system, convertirlo a ThemeMode.light
        if (themeMode == ThemeMode.system) {
          themeMode = ThemeMode.light;
          // Guardar el nuevo valor
          await prefs.setInt('theme_mode', themeMode.index);
        }
      } else {
        // Si no hay valor guardado, usar ThemeMode.light y guardarlo
        themeMode = ThemeMode.light;
        await prefs.setInt('theme_mode', themeMode.index);
      }
      
      final language = prefs.getString('language') ?? 'es';
      final currency = prefs.getString('currency') ?? 'NIO';
      final twoFactor = prefs.getBool('two_factor_auth') ?? false;
      final profilePublic = prefs.getBool('profile_public') ?? true;
      final showOnline = prefs.getBool('show_online_status') ?? true;
      final allowMessages = prefs.getBool('allow_messages') ?? true;
      final isDark = prefs.getBool('is_dark_mode') ?? false;
      final soundsEnabled = prefs.getBool('sounds_enabled') ?? true;
      state = state.copyWith(
        themeMode: themeMode,
        language: language,
        currency: currency,
        twoFactorAuth: twoFactor,
        profilePublic: profilePublic,
        showOnlineStatus: showOnline,
        allowMessages: allowMessages,
        isDarkMode: isDark,
        soundsEnabled: soundsEnabled,
      );
      
      // Inicializar AudioHelper con el valor de settings
      AudioHelper.setEnabled(soundsEnabled);
    } catch (_) {
      // keep defaults on error
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', mode.index);
    } catch (_) {}
  }

  Future<void> setLanguage(String language) async {
    state = state.copyWith(language: language);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
    } catch (_) {}
  }

  Future<void> setCurrency(String currency) async {
    state = state.copyWith(currency: currency);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', currency);
    } catch (_) {}
  }

  Future<void> setTwoFactorAuth(bool enable) async {
    state = state.copyWith(twoFactorAuth: enable);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('two_factor_auth', enable);
    } catch (_) {}
  }

  Future<void> setProfilePublic(bool isPublic) async {
    state = state.copyWith(profilePublic: isPublic);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('profile_public', isPublic);
    } catch (_) {}
  }

  Future<void> setShowOnlineStatus(bool show) async {
    state = state.copyWith(showOnlineStatus: show);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_online_status', show);
    } catch (_) {}
  }

  Future<void> setAllowMessages(bool allow) async {
    state = state.copyWith(allowMessages: allow);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('allow_messages', allow);
    } catch (_) {}
  }

  Future<void> setDarkMode(bool isDark) async {
    state = state.copyWith(isDarkMode: isDark);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', isDark);
    } catch (_) {}
  }

  Future<void> setSoundsEnabled(bool enabled) async {
    state = state.copyWith(soundsEnabled: enabled);
    // Actualizar AudioHelper inmediatamente
    AudioHelper.setEnabled(enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sounds_enabled', enabled);
    } catch (_) {}
  }
}

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

