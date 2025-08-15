import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  final MediaQueryData media;

  const BannerWidget({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFBE0C0C);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Centro de Control",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Bienvenido, aquí podrás gestionar tu negocio.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/control.png',
            height: media.size.height * 0.12,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
