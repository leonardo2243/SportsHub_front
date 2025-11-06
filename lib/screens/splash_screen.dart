import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import '../../providers/sesion_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool cargado = false;

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final sesion = Provider.of<SesionProvider>(context, listen: false);
    await sesion.cargarSesion();

    if (!mounted) return;

    setState(() {
      cargado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!cargado) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer<SesionProvider>(
      builder: (_, __, ___) {
        return const HomeScreen(); // se redibuja si cambia usuario o rol
      },
    );
  }
}
