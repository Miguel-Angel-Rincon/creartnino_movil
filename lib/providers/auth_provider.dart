import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/usuario_model.dart';

class AuthProvider with ChangeNotifier {
  Usuario? _usuario;

  Usuario? get usuario => _usuario;

  void setUsuario(Usuario user) {
    _usuario = user;
    notifyListeners();
  }

  void logout() {
    _usuario = null;
    notifyListeners();
  }

  // Esto permite usar: AuthProvider.of(context)
  static AuthProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<AuthProvider>(context, listen: listen);
  }
}
