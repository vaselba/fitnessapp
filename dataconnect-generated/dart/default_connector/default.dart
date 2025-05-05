library default_connector;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DefaultConnector {
  final String location;
  final String connectorId;
  final String serviceId;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DefaultConnector._({
    required this.location,
    required this.connectorId,
    required this.serviceId,
    required this.firestore,
    required this.auth,
  });

  static final DefaultConnector _instance = DefaultConnector._(
    location: 'us-central1',
    connectorId: 'default',
    serviceId: 'fitness',
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );

  static DefaultConnector get instance => _instance;

  Future<void> useEmulator(String host, int port) async {
    FirebaseFirestore.instance.useFirestoreEmulator(host, port);
  }

  // Add methods for your specific data operations here
  // For example:
  Future<void> saveData(String collection, String documentId, Map<String, dynamic> data) async {
    await firestore.collection(collection).doc(documentId).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getData(String collection, String documentId) async {
    final doc = await firestore.collection(collection).doc(documentId).get();
    return doc.data();
  }

  Stream<QuerySnapshot> getCollectionStream(String collection) {
    return firestore.collection(collection).snapshots();
  }
}

