import 'dart:developer' as developer;
import 'package:system_movil/services/navigation/navigation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'utils/app_localizations.dart';
import 'utils/snackbar_helper.dart';
import 'providers/settings/settings_notifier.dart';
import 'routes/auth_wrapper.dart';
import 'main_theme.dart';
import 'screens/auth/login.dart';
import 'screens/home_screen.dart';
import 'services/notification/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializar Firebase
  try {
    developer.log('🔥 [MAIN] Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('✅ [MAIN] Firebase inicializado correctamente');
    
    // ✅ Inicializar notificaciones locales
    developer.log('🔔 [MAIN] Inicializando notificaciones locales...');
    await FlutterLocalNotifications.init();
    developer.log('✅ [MAIN] Notificaciones locales inicializadas correctamente');
  } catch (e, stackTrace) {
    developer.log('❌ [MAIN] Error inicializando Firebase', error: e, stackTrace: stackTrace);
  }

  // Configurar orientación
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Asegurar que la UI del sistema sea visible
  SystemChrome.setEnabledSystemUIMode(  
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  runApp(const ProviderScope(child: SystemMovilApp()));
}

class SystemMovilApp extends StatelessWidget {
  const SystemMovilApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final settings = ref.watch(settingsNotifierProvider);
        return MaterialApp(
          title: 'GlowNic',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: settings.themeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(settings.language),
          navigatorKey: NavigationService.navigatorKey,
          scaffoldMessengerKey: SnackbarHelper.scaffoldMessengerKey,
          initialRoute: AuthWrapper.routeName,
          routes: {
            AuthWrapper.routeName: (context) => const AuthWrapper(),
            LoginScreen.routeName: (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
          debugShowCheckedModeBanner: false,
          builder: (context, child) => _AuthSideEffects(child: child),
        );
      },
    );
  }
}

class _AuthSideEffects extends ConsumerStatefulWidget {
  const _AuthSideEffects({required this.child});
  final Widget? child;

  @override
  ConsumerState<_AuthSideEffects> createState() => _AuthSideEffectsState();
}

class _AuthSideEffectsState extends ConsumerState<_AuthSideEffects> {
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: widget.child ?? const SizedBox.shrink(),
    );
  }
}
