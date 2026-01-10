import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemMovilTheme.getStatusBarStyle(false),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo simple
            Image.asset(
              'assets/images/logo5.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/logo5.png',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                );
              },
            ),
            const SizedBox(height: 40),
            
            // Loader simple
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(SystemMovilColors.primary),
                strokeWidth: 3,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

