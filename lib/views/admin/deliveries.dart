import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryapp/views/admin/add_products.dart';
import 'package:deliveryapp/views/admin/inventory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login.dart';

class Deliveries extends StatefulWidget {
  const Deliveries({Key? key});

  @override
  State<Deliveries> createState() => _DeliveriesState();
}

class _DeliveriesState extends State<Deliveries> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Entregas'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Inventory()),
                );
              },
              icon: const Icon(Icons.store_sharp)),
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const Products(),
                ),
              );
            },
            icon: const Icon(Icons.fastfood_outlined),
          ),
          IconButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const Login(),
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('deliveries').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          final deliveryDocs = snapshot.data?.docs ?? [];

          if (deliveryDocs.isEmpty) {
            return const Center(child: Text('No hay pedidos de domicilio.'));
          }

          return ListView.builder(
            itemCount: deliveryDocs.length,
            itemBuilder: (context, index) {
              final deliveryData =
                  deliveryDocs[index].data() as Map<String, dynamic>;

              // Función para cambiar el estado del pedido
              void changeStatus(String newStatus) async {
                await FirebaseFirestore.instance
                    .collection('deliveries')
                    .doc(deliveryDocs[index].id)
                    .update({'status': newStatus});
              }

              // Obtener el UID del inventario desde los datos de entrega
              final inventoryUid = deliveryData['inventoryUid'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('inventories')
                    .doc(inventoryUid)
                    .get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> inventorySnapshot) {
                  if (inventorySnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Text('Cargando...');
                  }
                  if (inventorySnapshot.hasError) {
                    return Text('Error: ${inventorySnapshot.error}');
                  }

                  final inventoryData =
                      inventorySnapshot.data?.data() as Map<String, dynamic>?;

                  if (inventoryData != null) {
                    // Obtener el UID del producto desde los datos del inventario
                    final productUid = inventoryData['productUid'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('products')
                          .doc(productUid)
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> productSnapshot) {
                        if (productSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Text('Cargando...');
                        }
                        if (productSnapshot.hasError) {
                          return Text('Error: ${productSnapshot.error}');
                        }

                        final productData = productSnapshot.data?.data()
                            as Map<String, dynamic>?;

                        if (productData != null) {
                          final productName =
                              productData['name'] ?? 'Nombre no disponible';

                          // Mostrar el nombre del producto en lugar del UID
                          return ListTile(
                            title: Text(productName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Dirección: ${deliveryData['deliveryAddress']}'),
                                Text(
                                    'Estado del Domicilio: ${deliveryData['status']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icono para marcar como "En Proceso"
                                Visibility(
                                  visible:
                                      deliveryData['status'] != 'Entregado',
                                  child: IconButton(
                                    icon: const Icon(Icons.hourglass_empty),
                                    onPressed: () async {
                                      // Cambiar el estado a "En Proceso"
                                      changeStatus('En Proceso');
                                      // Muestra un SnackBar con el mensaje
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Estado cambiado a "En Proceso"'),
                                          duration: const Duration(
                                              seconds:
                                                  2), // Duración del SnackBar
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Icono para marcar como "Entregado"
                                Visibility(
                                  visible:
                                      deliveryData['status'] != 'Entregado',
                                  child: IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: () async {
                                      // Cambiar el estado a "Entregado"
                                      changeStatus('Entregado');
                                      // Muestra un SnackBar con el mensaje
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Estado cambiado a "Entregado"'),
                                          duration: const Duration(
                                              seconds:
                                                  2), // Duración del SnackBar
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Manejar el caso en el que no se encuentre el producto
                          return const Text('Producto no encontrado');
                        }
                      },
                    );
                  } else {
                    // Manejar el caso en el que no se encuentre el inventario
                    return const Text('Inventario no encontrado');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
