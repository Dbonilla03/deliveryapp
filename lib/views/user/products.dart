import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryapp/views/user/pending.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../const.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const Pending(),
                  ),
                );
              },
              icon: Icon(Icons.shopping_cart)),
          IconButton(
            onPressed: () {
              Constants.logout(context);
            },
            icon: const Tooltip(
              message: 'Cerrar sesión',
              child: Icon(Icons.logout_outlined),
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('inventories').snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<QuerySnapshot> inventorySnapshot) {
          if (inventorySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (inventorySnapshot.hasError) {
            return Text('Error: ${inventorySnapshot.error}');
          }

          final inventoryProducts = inventorySnapshot.data?.docs ?? [];

          if (inventoryProducts.isEmpty) {
            return const Center(child: Text('No hay productos disponibles.'));
          }

          return ListView.builder(
            itemCount: inventoryProducts.length,
            itemBuilder: (context, index) {
              final productData =
                  inventoryProducts[index].data() as Map<String, dynamic>;
              final productUid = productData[
                  'productUid']; // Asegúrate de que el campo sea el UID del producto

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .doc(productUid)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                  if (productSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (productSnapshot.hasError) {
                    return Text('Error: ${productSnapshot.error}');
                  }

                  final product =
                      productSnapshot.data?.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
                    child: ListTile(
                      leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product['image'] == ''
                              // ignore: sized_box_for_whitespace
                              ? Container(
                                  width: 60,
                                  height: 60,
                                  child: const Icon(Icons
                                      .image)) // Show an icon if no image URL is found
                              : Image.network(
                                  product[
                                      'image'], // Use the image URL from the data
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )),
                      title: Text(product['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cantidad: ${productData['cantidad']}'),
                          Text('Precio: ${product['price']}'),
                          Text('Presentación: ${product['presentation']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              _requestDelivery(productUid: productUid);
                            },
                            icon: Icon(Icons
                                .local_shipping), // Agrega un icono para pedir domicilio
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _requestDelivery({required String productUid}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String deliveryAddress =
            ''; // Variable para almacenar la dirección de entrega
        int quantity = 1; // Cantidad inicial

        return AlertDialog(
          title: Text('Pedir Domicilio'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  onChanged: (value) {
                    deliveryAddress =
                        value; // Actualiza la dirección cuando el usuario la ingresa
                  },
                  decoration: InputDecoration(
                    labelText: 'Dirección de Entrega',
                  ),
                ),
                TextFormField(
                  onChanged: (value) {
                    quantity = int.tryParse(value) ??
                        1; // Actualiza la cantidad cuando el usuario la ingresa
                  },
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Realiza la lógica para obtener el UID del inventario correspondiente al producto
                _getInventoryUid(productUid, (String? inventoryUid) {
                  if (inventoryUid != null) {
                    // Obten el inventario correspondiente al producto
                    _checkInventory(inventoryUid, quantity,
                        (int availableQuantity) {
                      if (quantity <= availableQuantity) {
                        // La cantidad es válida, guarda el pedido con el UID del inventario
                        _saveDelivery(inventoryUid, deliveryAddress, quantity);
                        Navigator.of(context).pop(); // Cierra el modal
                      } else {
                        // La cantidad es mayor que la disponible en el inventario, muestra un mensaje de error
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'La cantidad solicitada es mayor que la disponible en el inventario.'),
                        ));
                      }
                    });
                  } else {
                    // No se encontró el inventario correspondiente al producto
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'No se pudo encontrar el inventario correspondiente al producto seleccionado.'),
                    ));
                  }
                });
              },
              child: Text('Enviar Pedido'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el modal sin hacer nada
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _getInventoryUid(String productUid, Function(String?) callback) {
    FirebaseFirestore.instance
        .collection('inventories')
        .where('productUid', isEqualTo: productUid)
        .get()
        .then((QuerySnapshot inventorySnapshot) {
      if (inventorySnapshot.docs.isNotEmpty) {
        // Se encontró un inventario que coincide con el producto seleccionado
        final inventoryUid = inventorySnapshot.docs.first.id;
        callback(inventoryUid);
      } else {
        // No se encontró un inventario correspondiente al producto
        callback(null);
      }
    }).catchError((error) {
      print('Error al obtener el UID del inventario: $error');
      callback(null);
    });
  }

  void _checkInventory(
      String productUid, int requestedQuantity, Function(int) callback) {
    FirebaseFirestore.instance
        .collection('inventories')
        .doc(productUid)
        .get()
        .then((DocumentSnapshot inventorySnapshot) {
      if (inventorySnapshot.exists) {
        final inventoryData = inventorySnapshot.data() as Map<String, dynamic>;
        final int availableQuantity = inventoryData['cantidad'] ?? 0;
        callback(availableQuantity);
      } else {
        // El documento no existe en la colección 'inventories'
        print('El documento con productUid $productUid no existe.');
        callback(0); // Puedes manejar esto de acuerdo a tus necesidades
      }
    }).catchError((error) {
      print('Error al obtener la cantidad en el inventario: $error');
      callback(0); // Maneja el error como consideres apropiado
    });
  }

  void _saveDelivery(String productUid, String deliveryAddress, int quantity) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String userUid = user.uid;

      // Puedes establecer el estado inicial del pedido como "pendiente" o cualquier otro valor
      String deliveryStatus = "pendiente";

      // Agrega el pedido a la colección 'deliveries'
      FirebaseFirestore.instance.collection('deliveries').add({
        'inventoryUid': productUid,
        'deliveryAddress': deliveryAddress,
        'quantity': quantity, // Almacena la cantidad solicitada
        'status': deliveryStatus,
        'userUid': userUid, // Almacena el UID del usuario
        // Otros campos que necesites para el pedido
      }).then((_) {
        // Registro exitoso, muestra un SnackBar de éxito
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pedido registrado con éxito.'),
          duration: Duration(seconds: 2), // Duración del SnackBar
        ));
      }).catchError((error) {
        print('Error al guardar el pedido: $error');
        // Aquí puedes mostrar un mensaje de error si ocurriera un problema en el registro
      });
    } else {
      // El usuario no está autenticado, maneja esta situación según tus requisitos
      print('El usuario no está autenticado.');
    }
  }
}
