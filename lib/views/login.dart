import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryapp/services/auth_service.dart';
import 'package:deliveryapp/views/register.dart';
import 'package:deliveryapp/views/user/products.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin/deliveries.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _obscureText = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Inicio de Sesión'),
          automaticallyImplyLeading: false,
        ),
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
                  onTap: _login,
                  child: Container(
                    width: double.infinity,
                    height: 45,
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Center(
                      child: Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )),
            const SizedBox(
              height: 10,
            ),
            Center(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Register()));
                },
                child: const Text('No tienes una cuenta? ¡Registrate aquí!',
                    style: TextStyle(color: Colors.blue)),
              ),
            )
          ],
        ));
  }

  void _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    User? user = await _auth.signInWithEmailAndPassword(email, password);

    if (user != null) {
      // Obtener el rol del usuario desde Firestore
      String role = await _getUserRole(user.uid);

      // Realizar la navegación según el rol
      if (role == "Admin") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                const Deliveries(), // Reemplaza con tu vista de administrador
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                Products(), // Reemplaza con tu vista de usuario normal
          ),
        );
      }
    } else {
      print("Error al iniciar sesión");
    }
  }

  Future<String> _getUserRole(String uid) async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection("userRoles").doc(uid).get();
      if (snapshot.exists) {
        return snapshot.get("role");
      }
    } catch (e) {
      print("Error al obtener el rol del usuario: $e");
    }
    return "User"; // Por defecto, si no se puede obtener el rol
  }
}
