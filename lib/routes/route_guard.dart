import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'auth_wrapper.dart';

class RouteGuard extends ConsumerWidget {
  final Widget child;
  final bool requiresAuth;
  final bool requiresGuest;

  const RouteGuard({
    Key? key,
    required this.child,
    this.requiresAuth = false,
    this.requiresGuest = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Si aún no se ha inicializado, mostrar splash
    if (!authState.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si la pantalla requiere autenticación y NO está autenticado
    if (requiresAuth && !authState.isAuthenticated) {
      // Redirigir a login después de un frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 🔒 SEGURIDAD: Verificar que el context esté montado antes de navegar
        if (!context.mounted) return;
        
        if (Navigator.canPop(context)) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        Navigator.of(context).pushReplacementNamed(AuthWrapper.routeName);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si la pantalla es para invitados y SÍ está autenticado
    if (requiresGuest && authState.isAuthenticated) {
      // Redirigir a home después de un frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 🔒 SEGURIDAD: Verificar que el context esté montado antes de navegar
        if (!context.mounted) return;
        
        Navigator.of(context).pushReplacementNamed('/home');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si todo está bien, mostrar la pantalla
    return child;
  }
}

// Widget helper para pantallas que requieren autenticación
class AuthRequired extends StatelessWidget {
  final Widget child;

  const AuthRequired({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      requiresAuth: true,
      child: child,
    );
  }
}

// Widget helper para pantallas de invitados (login, registro, etc.)
class GuestOnly extends StatelessWidget {
  final Widget child;

  const GuestOnly({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      requiresGuest: true,
      child: child,
    );
  }
}

// Widget helper para pantallas públicas (accesibles siempre)
class PublicRoute extends StatelessWidget {
  final Widget child;

  const PublicRoute({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RouteGuard(
      child: child,
    );
  }
}
