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
