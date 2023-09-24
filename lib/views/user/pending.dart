import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryapp/views/user/products.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login.dart';

class Pending extends StatefulWidget {
  const Pending({Key? key});

  @override
  State<Pending> createState() => _PendingState();
}

class _PendingState extends State<Pending> {
  List<Map<String, dynamic>> deliveryDataList = [];
  List<QueryDocumentSnapshot> deliveryDocs = [];

  @override
  void initState() {
    super.initState();
    loadDeliveryData();
  }

  Future<void> loadDeliveryData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String userUid = user.uid;

      final QuerySnapshot deliverySnapshot = await FirebaseFirestore.instance
          .collection('deliveries')
          .where('userUid', isEqualTo: userUid) // Filtra por el UID del usuario
          .get();

      deliveryDocs = deliverySnapshot.docs;

      final List<Map<String, dynamic>> deliveries = [];

      for (final QueryDocumentSnapshot deliveryDoc in deliveryDocs) {
        final deliveryData = deliveryDoc.data() as Map<String, dynamic>;
        final inventoryUid = deliveryData['inventoryUid'];
        final deliveryStatus = deliveryData['status'];

        // Consulta el inventario correspondiente al delivery
        final inventorySnapshot = await FirebaseFirestore.instance
            .collection('inventories')
            .doc(inventoryUid)
            .get();

        if (inventorySnapshot.exists) {
          final inventoryData =
              inventorySnapshot.data() as Map<String, dynamic>;
          final productUid = inventoryData['productUid'];

          deliveries.add({
            'productUid': productUid, // Agrega el productUid
            'deliveryStatus': deliveryStatus,
          });
        }
      }

      setState(() {
        deliveryDataList = deliveries;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Domicilios Pendientes'),
        automaticallyImplyLeading: false,
        actions: [
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
      body: _buildDeliveryList(),
    );
  }

  Widget _buildDeliveryList() {
    if (deliveryDataList.isEmpty) {
      return const Center(child: Text('No hay domicilios pendientes.'));
    }

    // Crea una lista de Future<DocumentSnapshot> para cargar los datos del producto
    final List<Future<DocumentSnapshot>> productFutures = deliveryDataList
        .map((deliveryData) => FirebaseFirestore.instance
            .collection('products')
            .doc(deliveryData['productUid'])
            .get())
        .toList();

    // Usa Future.wait para cargar todos los datos del producto de una vez
    return FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait(productFutures),
      builder: (BuildContext context,
          AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        // Construye la lista de ListTile con los datos del producto y el domicilio
        final productSnapshots = snapshot.data ?? [];

        return ListView.builder(
          itemCount: deliveryDataList.length,
          itemBuilder: (context, index) {
            final deliveryData = deliveryDataList[index];
            final productSnapshot = productSnapshots[index];
            final deliveryStatus = deliveryData['deliveryStatus'];

            if (productSnapshot.exists) {
              final productData =
                  productSnapshot.data() as Map<String, dynamic>;
              final productName = productData['name'] ?? 'Nombre no disponible';

              return ListTile(
                leading: Image.network(
                  productData['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
                title: Text(productName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Precio: ${productData['price']}'),
                    Text('Presentación: ${productData['presentation']}'),
                    Text('Estado del Domicilio: $deliveryStatus'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono para cancelar el domicilio si el estado es "Pendiente"
                    Visibility(
                        visible: deliveryStatus == 'pendiente',
                        child: IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            // Verifica si hay entregas disponibles antes de intentar eliminar
                            if (deliveryDocs.isNotEmpty) {
                              // Muestra un cuadro de diálogo de confirmación
                              bool confirmCancel = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                      '¿Estás seguro de que quieres cancelar este domicilio?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(false); // No confirmar
                                      },
                                      child: Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(true); // Confirmar
                                      },
                                      child: Text(
                                        'Sí',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmCancel == true) {
                                final deliveryId = deliveryDocs[index].id;
                                await FirebaseFirestore.instance
                                    .collection('deliveries')
                                    .doc(deliveryId)
                                    .delete();

                                // Actualiza la lista de entregas después de eliminar
                                setState(() {
                                  deliveryDocs.removeAt(index);
                                });

                                // Vuelve a cargar los datos para asegurarte de que la vista se actualice
                                loadDeliveryData();
                              }
                            }
                          },
                        )),
                  ],
                ),
              );
            } else {
              return const Text('Producto no encontrado');
            }
          },
        );
      },
    );
  }
}
