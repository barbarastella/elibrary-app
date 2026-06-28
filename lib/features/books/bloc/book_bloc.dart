import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/book_repository.dart';
import 'book_event.dart';
import 'book_state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final BookRepository _bookRepository;

  BookBloc({required BookRepository bookRepository})
    : _bookRepository = bookRepository,
      super(const BooksInitial()) {
    on<LoadBooksRequestedEvent>(_onLoadBooksRequested);
    on<AddBookRequestedEvent>(_onAddBookRequested);
    on<UpdateBookRequestedEvent>(_onUpdateBookRequested);
    on<DeleteBookRequestedEvent>(_onDeleteBookRequested);
    on<GenerateBookInsightsEvent>(_onGenerateBookInsights);
  }

  Future<void> _onLoadBooksRequested(
    LoadBooksRequestedEvent event,
    Emitter<BookState> emit,
  ) async {
    emit(const BooksLoading());

    await emit.forEach(
      _bookRepository.getUserBookStream(event.userId),
      onData: (books) => BooksLoaded(books),
      onError: (e, stackTrace) => BooksError('Erro a carregar books: $e'),
    );
  }

  Future<void> _onAddBookRequested(
    AddBookRequestedEvent event,
    Emitter<BookState> emit,
  ) async {
    try {
      await _bookRepository.addBook(userId: event.userId, book: event.book);
    } catch (e) {
      emit(BooksError('Erro ao adicionar book: $e'));
    }
  }

  Future<void> _onUpdateBookRequested(
    UpdateBookRequestedEvent event,
    Emitter<BookState> emit,
  ) async {
    try {
      await _bookRepository.updateBook(userId: event.userId, book: event.book);
    } catch (e) {
      emit(BooksError('Erro ao atualizar book: $e'));
    }
  }

  Future<void> _onDeleteBookRequested(
    DeleteBookRequestedEvent event,
    Emitter emit,
  ) async {
    try {
      await _bookRepository.deleteBook(
        userId: event.userId,
        bookId: event.bookId,
      );
    } catch (e) {
      emit(BooksError('Erro ao deletar book: $e'));
    }
  }

  Future<void> _onGenerateBookInsights(GenerateBookInsightsEvent event, Emitter<BookState> emit) async {
    try {
      emit(BooksLoading());
      await _bookRepository.generateAndSaveInsights(userId: event.userId, book: event.book);
    } catch (e) {
      emit(BooksError('Erro ao conectar com o Gemini: ${e.toString()}'));
    }
}
}
