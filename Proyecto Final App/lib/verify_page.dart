import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'login_page.dart';

const Color kGreenPrimary = Color(0xFF00D26A);

class VerifyCodePage extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final int age;
  final String expectedCode;

  VerifyCodePage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.age,
    required this.expectedCode,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

// Pantalla que valida el código y, si es correcto, registra al usuario en Firebase
class _VerifyCodePageState extends State<VerifyCodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final enteredCode = _codeController.text.trim();

    // 1) Validar código ingresado
    if (enteredCode != widget.expectedCode) {
      setState(() {
        _isLoading = false;
        _error = 'El código ingresado es incorrecto.';
      });
      return;
    }

    // 2) Registrar usuario en Firebase
    final error = await _authService.register(
      name: widget.name,
      email: widget.email,
      password: widget.password,
      age: widget.age,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _error = error;
      });
      return;
    }

    // 3) Registro correcto: se envió correo de verificación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Usuario registrado.\n'
              'Te enviamos un correo de verificación a ${widget.email}. '
              'Revisa tu bandeja de entrada o spam.',
        ),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verificar código'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingresa el código de verificación',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hemos generado un código para completar tu registro. '
                    'Ingresa el código que viste en pantalla.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),

              // Muestra el código en pantalla (modo demo)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Código (demo): ${widget.expectedCode}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(height: 24),

              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'Código de verificación',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el código';
                  }
                  if (value.trim().length != 6) {
                    return 'El código debe tener 6 dígitos';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),

              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Colors.red),
                ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreenPrimary,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    'Verificar y registrarme',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
