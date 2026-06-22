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
      final docRef = _userBooksCollection(userId).doc(book.isbn);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) throw 'Um livro com este ISBN já está na sua estante.';

      await docRef.set(book.toFirestore());
    } catch (e) {
      throw Exception(e.toString().replaceAll('Erro ao adicionar livro: ', ''));
    }
  }

  Stream<List<BookModel>> getUserBookStream(String userId) {
    return _userBooksCollection(
      userId,
    ).orderBy('addedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateBook({
    required String userId,
    required BookModel book,
  }) async {
    try {
      if (book.id == null) throw Exception('O bookId não pode ser nulo');

      await _userBooksCollection(
        userId,
      ).doc(book.id).update(book.toFirestore());
    } catch (e) {
      throw Exception('Erro ao fazer update do book: $e');
    }
  }

  Future<void> deleteBook({
    required String userId,
    required String bookId,
  }) async {
    try {
      await _userBooksCollection(userId).doc(bookId).delete();
    } catch (e) {
      throw Exception('Erro ao fazer delete do book: $e');
    }
  }
}
