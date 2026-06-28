import 'package:equatable/equatable.dart';
import '../data/book_model.dart';

abstract class BookState extends Equatable {
  const BookState();

  @override
  List<Object?> get props => [];
}

class BooksInitial extends BookState {
  const BooksInitial();
}

class BooksLoading extends BookState {
  const BooksLoading();
}

class BooksLoaded extends BookState {
  final List<BookModel> books;
  const BooksLoaded(this.books);

  @override
  List<Object?> get props => [books];
}

class BooksError extends BookState {
  final String message;
  const BooksError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookScannerProcessing extends BooksLoaded {
  const BookScannerProcessing({required List<BookModel> books}) : super(books);
}

class BookScannerSuccess extends BooksLoaded {
  final BookModel scannedBook;
  const BookScannerSuccess({
    required List<BookModel> books,
    required this.scannedBook,
  }) : super(books);

  @override
  List<Object?> get props => [books, scannedBook];
}

class BookScannerNotFound extends BooksLoaded {
  final String isbn;
  const BookScannerNotFound({
    required List<BookModel> books,
    required this.isbn,
  }) : super(books);

  @override
  List<Object?> get props => [books, isbn];
}

class BookScannerError extends BooksLoaded {
  final String message;
  const BookScannerError({
    required List<BookModel> books,
    required this.message,
  }) : super(books);

  @override
  List<Object?> get props => [books, message];
}
