import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_model.dart';

class BookRepository {
  final FirebaseFirestore _firestore;

  BookRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _userBooksCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('books');
  }

  Future<void> addBook({
    required String userId,
    required BookModel book,
  }) async {
    try {
      await _userBooksCollection(userId).add(book.toFirestore());
    } catch (e) {
      throw Exception('Erro ao adicionar livro: $e');
    }
  }

  Stream<List<BookModel>> getUserBookStream(String userId) {
    return _userBooksCollection(userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BookModel.fromFirestore(doc))
              .tolist();
        });
  }
  

}
