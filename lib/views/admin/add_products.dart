import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deliveryapp/const.dart';
import 'package:deliveryapp/services/image_service.dart';
import 'package:deliveryapp/services/products_service.dart';
import 'package:deliveryapp/views/admin/deliveries.dart';
import 'package:deliveryapp/views/admin/inventory.dart';
import 'package:flutter/material.dart';

class Products extends StatefulWidget {
  const Products({super.key});

  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  final TextEditingController _nameproductController = TextEditingController();
  final TextEditingController _priceproductController = TextEditingController();
  final TextEditingController _presentationproductController =
      TextEditingController();
  // ignore: non_constant_identifier_names
  File? image_to_upload;
  // ignore: unused_field
  String? _existingImageUrl;

  bool isSaving = false;

  List products = [];

  void _clearForm() {
    _nameproductController.clear();
    _priceproductController.clear();
    _presentationproductController.clear();
  }

  void _updateProductList() async {
    List<Map<String, dynamic>> updatedProducts = await getProduct();
    setState(() {
      products = updatedProducts;
    });
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Agregar Producto'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final imagen = await getImage();
                        if (imagen != null) {
                          setState(() {
                            image_to_upload = File(imagen.path);
                          });
                        }
                      },
                      child: const Text('Seleccionar Imagen'),
                    ),
                    const SizedBox(height: 10.0),
                    image_to_upload != null
                        ? Image.file(
                            File(image_to_upload!.path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : SizedBox.shrink(),
                    TextFormField(
                      controller: _nameproductController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ingrese nombre del producto',
                        suffixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      controller: _priceproductController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        hintText: 'Ingrese precio del producto',
                        suffixIcon: Icon(Icons.attach_money_outlined),
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      controller: _presentationproductController,
                      decoration: const InputDecoration(
                        labelText: 'Presentación',
                        hintText: 'Ingrese presentación del producto',
                        suffixIcon: Icon(Icons.straighten_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    setState(() {
                      isSaving = true;
                    });
                    String priceText = _priceproductController.text;
                    int priceInt = int.parse(priceText);

                    String? imageUrl;
                    if (image_to_upload != null) {
                      imageUrl =
                          await uploadImageToFirebaseStorage(image_to_upload!);
                    }

                    await addProduct(_nameproductController.text, priceInt,
                        _presentationproductController.text, imageUrl ?? '');

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Producto registrado con éxito')),
                    );
                    setState(() {
                      isSaving = false;
                    });
                    _updateProductList();
                    image_to_upload = null;
                    setState(() {
                      _clearForm(); // Limpiar el formulario después de agregar el producto
                    });
                    Navigator.pop(context);
                  },
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(Colors.green)),
                  child: isSaving
                      ? CircularProgressIndicator() // Muestra el CircularProgressIndicator si está guardando
                      : const Text(
                          'Agregar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                TextButton(
                  onPressed: () {
                    _clearForm();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editProduct({Map<String, dynamic>? product}) {
    if (product == null) return;

    String uid = product['uid'];

    File? selectedLocalImage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            _nameproductController.text = product['name'] ?? '';
            _priceproductController.text = (product['price'] ?? 0).toString();
            _presentationproductController.text = product['presentation'] ?? '';

            return AlertDialog(
              title: const Text('Editar Producto'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final selectedImage = await getImage();
                        if (selectedImage != null) {
                          setState(() {
                            selectedLocalImage = File(selectedImage.path);
                          });
                        }
                      },
                      child: const Text('Seleccionar Imagen'),
                    ),
                    if (selectedLocalImage != null)
                      Image.file(
                        selectedLocalImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    else if (product['image'] != null)
                      Image.network(
                        product['image'],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    else
                      // Mostrar algo en caso de que no haya imagen
                      SizedBox.shrink(),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      controller: _nameproductController,
                      decoration: const InputDecoration(
                          labelText: 'Nombre',
                          suffixIcon: Icon(Icons.label_outlined)),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _priceproductController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Precio',
                          suffixIcon: Icon(Icons.attach_money_outlined)),
                    ),
                    TextFormField(
                      controller: _presentationproductController,
                      decoration: const InputDecoration(
                          labelText: 'Presentación',
                          suffixIcon: Icon(Icons.straighten_outlined)),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          isSaving = true;
                        });

                        String priceText = _priceproductController.text;
                        int priceInt = int.parse(priceText);

                        String imageUrl;
                        if (selectedLocalImage != null) {
                          imageUrl = await uploadImageToFirebaseStorage(
                              selectedLocalImage!);
                        } else {
                          // Mantener la misma imagen existente si no se selecciona una nueva
                          imageUrl = product['image'];
                        }

                        await updateProduct(
                          uid,
                          _nameproductController.text,
                          priceInt,
                          _presentationproductController.text,
                          imageUrl,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Producto editado con éxito')),
                        );
                        _updateProductList();

                        setState(() {
                          isSaving = false;
                        });
                        Navigator.pop(context);
                      },
                      style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.green)),
                      child: isSaving
                          ? CircularProgressIndicator() // Muestra el CircularProgressIndicator si está guardando
                          : const Text(
                              'Guardar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addToInventory(
      {required Map<String, dynamic> productData, required String productUid}) {
    final TextEditingController _quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enviar Producto al Inventario'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Mostrar información del producto seleccionado
                ListTile(
                  leading: Image.network(productData['image']),
                  title: Text(productData['name']),
                  subtitle: Text('Precio: ${productData['price']}'),
                ),
                const SizedBox(height: 10.0),

                // Agregar campo para ingresar cantidad
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    hintText: 'Ingrese la cantidad a añadir al inventario',
                    suffixIcon: Icon(Icons.add_shopping_cart),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                setState(() {
                  isSaving = true;
                });
                int quantity = int.tryParse(_quantityController.text) ?? 0;
                final existingInventoryDoc = await FirebaseFirestore.instance
                    .collection('inventories')
                    .where('productUid', isEqualTo: productUid)
                    .limit(1)
                    .get();

                if (existingInventoryDoc.docs.isNotEmpty) {
                  // El producto ya está en el inventario, actualiza la cantidad
                  final existingQuantity =
                      existingInventoryDoc.docs.first['cantidad'];
                  final newQuantity = existingQuantity + quantity;

                  await existingInventoryDoc.docs.first.reference.update({
                    'cantidad': newQuantity,
                  });

                  if (newQuantity <= 0) {
                    String inventoryDocumentUid =
                        existingInventoryDoc.docs.first.id;
                    print('Token: $inventoryDocumentUid');
                    await deleteProductInventory(inventoryDocumentUid);
                  }
                } else {
                  // El producto no está en el inventario, agrégalo
                  await addToInventory(productUid, quantity);
                }
                setState(() {
                  isSaving = false;
                });
                Navigator.pop(
                    context); // Cierra el formulario después de agregar al inventario
              },
              child: const Text('Enviar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el formulario sin hacer nada
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

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
                    builder: (context) => const Deliveries(),
                  ),
                );
              },
              icon: Icon(Icons.pending_outlined)),
          IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Inventory()),
                );
              },
              icon: const Icon(Icons.store_sharp)),
          IconButton(
            onPressed: _addProduct,
            icon: const Tooltip(
              message: 'Añadir productos',
              child: Icon(Icons.add_outlined),
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
      body: FutureBuilder(
          future: getProduct(),
          builder: ((context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Muestra el CircularProgressIndicator mientras se cargan los datos
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              // Muestra un mensaje de error si hay un problema con la carga de datos
              return const Center(
                child: Text('Error al cargar los productos'),
              );
            } else if (snapshot.hasData) {
              if (snapshot.data?.isEmpty ?? true) {
                return const Center(
                  child: Text('No hay productos registrados'),
                );
              }
              return ListView.builder(
                  itemCount: snapshot.data?.length,
                  itemBuilder: (context, index) {
                    if (snapshot.hasData) {
                      dynamic price = snapshot.data?[index]['price'];
                      return Dismissible(
                        key: Key(snapshot.data?[index]['uid']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) async {
                          showDialog(
                            context: context,
                            barrierDismissible:
                                false, // Evita que el diálogo se cierre tocando fuera de él
                            builder: (BuildContext context) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );
                          final productUid = snapshot.data?[index]['uid'];

                          await deleteProduct(snapshot.data?[index]['uid']);
                          final inventoryDocs = await FirebaseFirestore.instance
                              .collection('inventories')
                              .where('productUid', isEqualTo: productUid)
                              .get();

                          for (final doc in inventoryDocs.docs) {
                            await doc.reference.delete();
                          }

                          snapshot.data?.removeAt(index);

                          Navigator.pop(context);

                          // Actualiza la vista
                          setState(() {});
                        },
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirmar eliminación'),
                                content: Text(
                                    '¿Estás seguro de que deseas eliminar este producto: ${snapshot.data?[index]['name']}?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        context, false), // No eliminar
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
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
                                child: snapshot.data?[index]['image'] == null ||
                                        snapshot.data?[index]['image'] == ''
                                    ? Container(
                                        child: const Icon(Icons.image),
                                        width: 60,
                                        height:
                                            60) // Show an icon if no image URL is found
                                    : Image.network(
                                        snapshot.data?[index][
                                            'image'], // Use the image URL from the data
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      )),
                            title: Text(snapshot.data?[index]['name']),
                            subtitle: Text('Precio: ${price.toString()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _editProduct(
                                      product: snapshot.data?[index],
                                    );
                                  },
                                  icon: const Tooltip(
                                    message: 'Editar',
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _addToInventory(
                                        productData: snapshot.data![index],
                                        productUid: snapshot.data?[index]
                                            ['uid']);
                                  },
                                  icon: const Tooltip(
                                    message: 'Enviar',
                                    child: Icon(
                                      Icons.send_and_archive_outlined,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } else {
                      const Center(child: CircularProgressIndicator());
                    }
                    return null;
                  });
            } else {
              return const Center(
                child: Text('No hay productos disponibles'),
              );
            }
          })),
    );
  }
}
