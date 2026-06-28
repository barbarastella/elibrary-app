import 'dart:async';
import 'package:elibrary/features/books/services/google_books_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/book_model.dart';
import '../data/book_repository.dart';
import 'book_event.dart';
import 'book_state.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final BookRepository _bookRepository;
  final GoogleBooksService _googleBooksService;

  BookBloc({
    required BookRepository bookRepository,
    GoogleBooksService? googleBooksService
  }) : _bookRepository = bookRepository,
        _googleBooksService = googleBooksService ?? GoogleBooksService(),

        super(const BooksInitial()) {
    on<LoadBooksRequestedEvent>(_onLoadBooksRequested);
    on<AddBookRequestedEvent>(_onAddBookRequested);
    on<UpdateBookRequestedEvent>(_onUpdateBookRequested);
    on<DeleteBookRequestedEvent>(_onDeleteBookRequested);
    on<GenerateBookInsightsEvent>(_onGenerateBookInsights);
    on<FetchBookFromScannerEvent>(_onFetchBookFromScanner);
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

Future<void> _onFetchBookFromScanner(FetchBookFromScannerEvent event, Emitter<BookState> emit) async {
    final currentState = state;
    List<BookModel> currentBooks = [];

    if (currentState is BooksLoaded) currentBooks = currentState.books;

    try {
      emit(BookScannerProcessing(books: currentBooks));
      final results = await _googleBooksService.getBooksByIsbnList([event.isbn]);

      if (results.isNotEmpty) emit(BookScannerSuccess(books: currentBooks, scannedBook: results.first));
      else emit(BookScannerNotFound(books: currentBooks, isbn: event.isbn));

    } catch (e) {
      emit(BookScannerError(books: currentBooks, message: 'Erro ao buscar livro no Google Books.'));
    }
}
}
