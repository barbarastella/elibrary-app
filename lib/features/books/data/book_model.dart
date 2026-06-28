import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_status_enum.dart';

class BookModel {
  final String? id;
  final String isbn;
  final String title;
  final String author;
  final String? genre;
  final int pageCount;
  final String? coverUrl;
  final BookStatus status;
  final bool addedViaScanner;
  final String? geminiSummary;
  final List<String>? geminiRecommendations;
  final DateTime? addedAt;

  const BookModel({
    this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.genre,
    required this.pageCount,
    this.coverUrl,
    required this.status,
    required this.addedViaScanner,
    this.geminiSummary,
    this.geminiRecommendations,
    this.addedAt,
  });

  BookModel copyWith({
    String? id,
    String? isbn,
    String? title,
    String? author,
    String? genre,
    int? pageCount,
    String? coverUrl,
    BookStatus? status,
    bool? addedViaScanner,
    String? geminiSummary,
    List<String>? geminiRecommendations,
    DateTime? addedAt,
  }) {
    return BookModel(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      pageCount: pageCount ?? this.pageCount,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      addedViaScanner: addedViaScanner ?? this.addedViaScanner,
      geminiSummary: geminiSummary ?? this.geminiSummary,
      geminiRecommendations:
      geminiRecommendations ?? this.geminiRecommendations,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  factory BookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final rawRecommendations = data['geminiRecommendations'];
    List<String>? parsedRecommendations;

    if (rawRecommendations is String) {parsedRecommendations = rawRecommendations
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .toList();
    } else if (rawRecommendations is List) {
      parsedRecommendations = List<String>.from(rawRecommendations);
    }

    return BookModel(
      id: doc.id,
      isbn: data['isbn'] ?? '',
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      genre: data['genre'],
      pageCount: (data['pageCount'] as num?)?.toInt() ?? 0,
      coverUrl: data['coverUrl'] ?? '',
      status: BookStatus.fromString(data['status'] ?? ''),
      addedViaScanner: data['addedViaScanner'] ?? false,
      geminiSummary: data['geminiSummary'],
      geminiRecommendations: parsedRecommendations,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isbn': isbn,
      'title': title,
      'author': author,
      'genre': genre,
      'pageCount': pageCount,
      'coverUrl': coverUrl,
      'status': status.toShortString(),
      'addedViaScanner': addedViaScanner,
      'geminiSummary': geminiSummary,
      'geminiRecommendations': geminiRecommendations,
      'addedAt': addedAt != null
          ? Timestamp.fromDate(addedAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}