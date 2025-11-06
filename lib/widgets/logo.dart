import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sports',
          style: TextStyle(
            color: Color.fromARGB(255, 33, 50, 145),
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
        Text(
          'Hub',
          style: TextStyle(
            color: Color.fromARGB(255, 56, 144, 185),
            fontWeight: FontWeight.bold,
            fontSize: 30,
          ),
        ),
      ],
    );
  }
}
