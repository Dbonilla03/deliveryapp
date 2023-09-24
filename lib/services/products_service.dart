import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

FirebaseFirestore bd = FirebaseFirestore.instance;

//CRUD
Future<List<Map<String, dynamic>>> getProduct() async {
  List<Map<String, dynamic>> product = [];

  CollectionReference collectionReferenceProduct = bd.collection('products');

  QuerySnapshot queryProduct = await collectionReferenceProduct.get();

  queryProduct.docs.forEach((documento) {
    final Map<String, dynamic>? data =
        documento.data() as Map<String, dynamic>?;

    if (data != null) {
      final element = {
        'name': data['name'],
        'price': data['price'],
        'presentation': data['presentation'],
        'image': data['image'],
        'uid': documento.id
      };
      product.add(element);
    }
  });

  return product;
}

Future<void> addProduct(
    String name, int price, String presentation, String imageUrl) async {
  await bd.collection('products').add({
    'name': name,
    'price': price,
    'presentation': presentation,
    'image': imageUrl
  });
}

Future<void> updateProduct(String uid, String newName, int newPrice,
    String newPresentation, String newImageUrl) async {
  await bd.collection('products').doc(uid).set({
    'name': newName,
    'price': newPrice,
    'presentation': newPresentation,
    'image': newImageUrl
  });
}

Future<void> deleteProduct(String uid) async {
  await bd.collection('products').doc(uid).delete();
}

//Imagenes

final FirebaseStorage storage = FirebaseStorage.instance;

Future<String> uploadImageToFirebaseStorage(File image) async {
  final String nameFile = image.path.split('/').last;
  final Reference ref = storage.ref().child('images').child(nameFile);
  final UploadTask uploadTask = ref.putFile(image);
  final TaskSnapshot snapshot = await uploadTask.whenComplete(() => true);
  final String url = await snapshot.ref.getDownloadURL();

  return url;
}

Future<String?> doesImageExistInFirebaseStorage(String? imageName) async {
  final ref = FirebaseStorage.instance.ref('images/$imageName');

  try {
    final metadata = await ref.getMetadata();
    return metadata.fullPath;
  } catch (e) {
    return null; // La imagen no existe en Firebase Storage
  }
}

//Inventario
Future<void> addToInventory(String productUid, int amount) async {
  await bd.collection('inventories').add({
    'productUid': productUid,
    'cantidad': amount, // Puedes ajustar la cantidad según tu lógica
  });
}

Future<void> deleteProductInventory(String uid) async {
  try {
    final documentReference = bd.collection('inventories').doc(uid);
    await documentReference.delete();
    print('Documento eliminado exitosamente: $uid');
  } catch (error) {
    print('Error al eliminar el documento: $error');
  }
}

Future<List<String>> getInventoryDocumentIds() async {
  List<String> documentIds = [];

  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('inventories').get();

  snapshot.docs.forEach((DocumentSnapshot document) {
    String documentId = document.id;
    documentIds.add(documentId);
  });

  return documentIds;
}
