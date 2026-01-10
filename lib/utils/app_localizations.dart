import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('es', ''), // Español
    Locale('en', ''), // Inglés
    Locale('pt', ''), // Portugués
    Locale('fr', ''), // Francés
  ];

  // Método para obtener el idioma actual
  String get languageCode => locale.languageCode;

  // Textos de la aplicación
  String get appTitle => _getText('app_title');
  String get settings => _getText('settings');
  String get theme => _getText('theme');
  String get language => _getText('language');
  String get notifications => _getText('notifications');
  String get privacy => _getText('privacy');
  String get location => _getText('location');
  String get about => _getText('about');
  String get helpSupport => _getText('help_support');
  String get lightMode => _getText('light_mode');
  String get darkMode => _getText('dark_mode');
  String get systemMode => _getText('system_mode');
  String get spanish => _getText('spanish');
  String get english => _getText('english');
  String get portuguese => _getText('portuguese');
  String get french => _getText('french');
  String get messages => _getText('messages');
  String get business => _getText('business');

  String _getText(String key) {
    switch (locale.languageCode) {
      case 'es':
        return _spanishTexts[key] ?? key;
      case 'en':
        return _englishTexts[key] ?? key;
      case 'pt':
        return _portugueseTexts[key] ?? key;
      case 'fr':
        return _frenchTexts[key] ?? key;
      default:
        return _spanishTexts[key] ?? key;
    }
  }

  static const Map<String, String> _spanishTexts = {
    'app_title': 'GlowNic',
    'settings': 'Configuración',
    'theme': 'Tema',
    'language': 'Idioma',
    'notifications': 'Notificaciones',
    'privacy': 'Privacidad',
    'location': 'Ubicación',
    'about': 'Acerca de',
    'help_support': 'Ayuda y Soporte',
    'light_mode': 'Claro',
    'dark_mode': 'Oscuro',
    'system_mode': 'Sistema',
    'spanish': 'Español',
    'english': 'English',
    'portuguese': 'Português',
    'french': 'Français',
    'messages': 'Mensajes',
    'business': 'Empresarial',
  };

  static const Map<String, String> _englishTexts = {
    'app_title': 'Find Me',
    'settings': 'Settings',
    'theme': 'Theme',
    'language': 'Language',
    'notifications': 'Notifications',
    'privacy': 'Privacy',
    'location': 'Location',
    'about': 'About',
    'help_support': 'Help & Support',
    'light_mode': 'Light',
    'dark_mode': 'Dark',
    'system_mode': 'System',
    'spanish': 'Español',
    'english': 'English',
    'portuguese': 'Português',
    'french': 'Français',
    'messages': 'Messages',
    'business': 'Business',
  };

  static const Map<String, String> _portugueseTexts = {
    'app_title': 'Encontre-me',
    'settings': 'Configurações',
    'theme': 'Tema',
    'language': 'Idioma',
    'notifications': 'Notificações',
    'privacy': 'Privacidade',
    'location': 'Localização',
    'about': 'Sobre',
    'help_support': 'Ajuda e Suporte',
    'light_mode': 'Claro',
    'dark_mode': 'Escuro',
    'system_mode': 'Sistema',
    'spanish': 'Español',
    'english': 'English',
    'portuguese': 'Português',
    'french': 'Français',
    'messages': 'Mensagens',
    'business': 'Empresarial',
  };

  static const Map<String, String> _frenchTexts = {
    'app_title': 'Trouvez-moi',
    'settings': 'Paramètres',
    'theme': 'Thème',
    'language': 'Langue',
    'notifications': 'Notifications',
    'privacy': 'Confidentialité',
    'location': 'Localisation',
    'about': 'À propos',
    'help_support': 'Aide et Support',
    'light_mode': 'Clair',
    'dark_mode': 'Sombre',
    'system_mode': 'Système',
    'spanish': 'Español',
    'english': 'English',
    'portuguese': 'Português',
    'french': 'Français',
    'messages': 'Messages',
    'business': 'Entreprise',
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en', 'pt', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
