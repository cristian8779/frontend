import 'package:flutter/material.dart';
import '../../screens/auth/register_screen.dart';

void mostrarRegistroPantallaCompleta(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const RegisterStepScreen(),
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(0.0, 1.0); // desde abajo
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}
