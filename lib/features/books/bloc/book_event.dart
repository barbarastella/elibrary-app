import 'package:equatable/equatable.dart';
import '../data/book_model.dart';

abstract class BookEvent extends Equatable {
  const BookEvent();

  @override
  List<Object?> get props => [];
}

class LoadBooksRequestedEvent extends BookEvent {
  final String userId;
  const LoadBooksRequestedEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddBookRequestedEvent extends BookEvent {
  final String userId;
  final BookModel book;

  const AddBookRequestedEvent({required this.userId, required this.book});

  @override
  List<Object?> get props => [userId, book];
}

class UpdateBookRequestedEvent extends BookEvent {
  final String userId;
  final BookModel book;

  const UpdateBookRequestedEvent({required this.userId, required this.book});

  @override
  List<Object?> get props => [userId, book];
}

class DeleteBookRequestedEvent extends BookEvent {
  final String userId;
  final String bookId;

  const DeleteBookRequestedEvent({required this.userId, required this.bookId});

  @override
  List<Object?> get props => [userId, bookId];
}

class BooksStreamUpdatedEvent extends BookEvent {
  final List<BookModel> books;
  const BooksStreamUpdatedEvent(this.books);

  @override
  List<Object?> get props => [books];
}

class GenerateBookInsightsEvent extends BookEvent {
  final String userId;
  final BookModel book;

  const GenerateBookInsightsEvent({required this.userId, required this.book});

  @override
  List<Object?> get props => [userId, book];
}

