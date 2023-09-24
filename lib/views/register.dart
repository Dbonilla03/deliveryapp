import 'package:deliveryapp/views/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:deliveryapp/services/auth_service.dart';
import 'admin/deliveries.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  ScaffoldMessengerState? _scaffoldMessengerState;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
    return Scaffold(
        appBar: AppBar(title: const Text('Registro')),
        body: ListView(
          children: [
            Column(
              children: [
                const SizedBox(
                  height: 10.0,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Image.asset(
                    './assets/images/delivery.jpg',
                    width: 200,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 30.0, left: 30.0),
              child: TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  hintText: 'Ingrese nombre usuario',
                  suffixIcon: Icon(Icons.person_outline),
                ),
              ),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 30.0, left: 30.0),
              child: TextFormField(
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                },
                obscureText: _obscureText,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Ingrese contraseña',
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureText =
                            !_obscureText; // Cambiamos el valor para alternar la visibilidad de la contraseña
                      });
                    },
                    child: Icon(_obscureText
                        ? Icons.visibility
                        : Icons
                            .visibility_off), // Cambiamos el icono según la visibilidad
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
                padding: const EdgeInsets.only(right: 80.0, left: 80.0),
                child: GestureDetector(
                  onTap: _register,
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Center(
                      child: Text(
                        'Registrarme',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ))
          ],
        ));
  }

  void _register() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (password.length < 6) {
      _showSnackBar("La contraseña debe tener al menos 6 caracteres");
      return; // No intentar registrar si la contraseña es demasiado corta
    }

    User? user = await _auth.registerWithEmailAndPassword(email, password);

    if (user != null) {
      _showSnackBar("Usuario creado correctamente");
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const Login(),
        ),
      );
    } else {
      _showSnackBar("Error al registrar el usuario");
    }
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    _scaffoldMessengerState?.showSnackBar(snackBar);
  }
}
