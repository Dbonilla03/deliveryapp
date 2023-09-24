import 'package:deliveryapp/services/products_service.dart';
import 'package:deliveryapp/views/admin/add_products.dart';
import 'package:deliveryapp/views/admin/deliveries.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../const.dart';

class Inventory extends StatefulWidget {
  const Inventory({super.key});

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  int currentQuantity = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const Deliveries(),
                  ),
                );
              },
              icon: Icon(Icons.pending_outlined)),
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Products()),
              );
            },
            icon: const Tooltip(
              message: 'Productos',
              child: Icon(Icons.fastfood_outlined),
            ),
          ),
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
            return const Center(
                child: Text('No hay productos en el inventario.'));
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
                    return Center(child: CircularProgressIndicator());
                  }
                  if (productSnapshot.hasError) {
                    return Text('Error: ${productSnapshot.error}');
                  }

                  final product =
                      productSnapshot.data?.data() as Map<String, dynamic>;

                  return Dismissible(
                    key: Key(inventoryProducts[index].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: AlignmentDirectional.centerEnd,
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      await deleteProductInventory(inventoryProducts[index].id);
                    },
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: Text(
                                '¿Estás seguro de que deseas eliminar este producto: ${product['name']}?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(
                                    context, false), // No eliminar
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                //Eliminar
                                child: const Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 1),
                      child: ListTile(
                        leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product['image'] == ''
                                ? Container(
                                    child: const Icon(Icons.image),
                                    width: 60,
                                    height:
                                        60) // Show an icon if no image URL is found
                                : Image.network(
                                    product[
                                        'image'], // Use the image URL from the data
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )),
                        title: Text(product['name']),
                        subtitle: Text(
                            'Cantidad: ${productData['cantidad']}'), // Asegúrate de que el campo sea 'cantidad' en inventoryProducts
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () async {
                                setState(() {
                                  currentQuantity = productData[
                                      'cantidad']; // Actualizar la cantidad actual con la cantidad del producto
                                });

                                // Obtener la referencia al documento en "inventories"
                                DocumentReference inventoryDocRef =
                                    FirebaseFirestore.instance
                                        .collection('inventories')
                                        .doc(inventoryProducts[index].id);

                                // Incrementar la cantidad en el mismo documento de "inventories"
                                await inventoryDocRef.update(
                                    {'cantidad': FieldValue.increment(1)});
                                setState(() {
                                  currentQuantity = currentQuantity + 1;
                                });
                              },
                              icon: const Tooltip(
                                message: 'Agregar',
                                child: Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                setState(() {
                                  currentQuantity = productData[
                                      'cantidad']; // Actualizar la cantidad actual con la cantidad del producto
                                });

                                // Verificar si la cantidad actual es mayor a 0 antes de restar
                                if (currentQuantity > 0) {
                                  // Obtener la referencia al documento en "inventories"
                                  DocumentReference inventoryDocRef =
                                      FirebaseFirestore.instance
                                          .collection('inventories')
                                          .doc(inventoryProducts[index].id);

                                  // Decrementar la cantidad en el mismo documento de "inventories"
                                  await inventoryDocRef.update(
                                      {'cantidad': FieldValue.increment(-1)});

                                  // Actualizar la cantidad en la interfaz
                                  setState(() {
                                    currentQuantity = currentQuantity - 1;
                                  });
                                  if (currentQuantity == 0) {
                                    await inventoryDocRef
                                        .delete(); // Eliminar el documento del inventario
                                  }
                                }
                              },
                              icon: const Tooltip(
                                message: 'Restar',
                                child: Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
