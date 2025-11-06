import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SesionProvider extends ChangeNotifier {
  String? _id;
  String? _rol;
  bool _sesionCargada = false;

  String? get id => _id;
  String? get rol => _rol;
  bool get sesionCargada => _sesionCargada;
  bool get estaAutenticado => _id != null;

  Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    _id = prefs.getString('id');
    _rol = prefs.getString('rol');
    _sesionCargada = true;
    notifyListeners();
  }

  Future<void> iniciarSesion(
    String id, {
    String rol = 'usuario',
    bool recordar = false,
  }) async {
    _id = id;
    _rol = rol;
    if (recordar) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id', id);
      await prefs.setString('rol', rol);
    }
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    _id = null;
    _rol = null;
    _sesionCargada = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('id');
    await prefs.remove('rol');
    notifyListeners();
  }
}
