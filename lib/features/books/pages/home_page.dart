import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/book_bloc.dart';
import '../bloc/book_event.dart';
import '../bloc/book_state.dart';
import '../data/book_model.dart';
import '../data/book_status_enum.dart';
import '../pages/book_form_page.dart';
import '../pages/book_details_page.dart';
import '../pages/barcode_scanner_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<BookBloc>().add(LoadBooksRequestedEvent(widget.userId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _startScannerFlow() async {
    final String? scannedIsbn = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    if (scannedIsbn != null && scannedIsbn.isNotEmpty && mounted) {
      context.read<BookBloc>().add(
        FetchBookFromScannerEvent(isbn: scannedIsbn),
      );
    }
  }

  void _navigateToForm(BookModel? initialData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookFormPage(existingBook: initialData),
      ),
    );
  }

  void _showAddBookOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: Colors.black, width: 3),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ADICIONAR LIVRO',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildOptionButton(
                icon: Icons.qr_code_scanner,
                label: 'ESCANEAR CÓDIGO DE BARRAS',
                color: const Color(0xFFFFE800),
                onTap: () {
                  Navigator.pop(context);
                  _startScannerFlow();
                },
              ),
              const SizedBox(height: 16),
              _buildOptionButton(
                icon: Icons.edit_note,
                label: 'PREENCHER MANUALMENTE',
                color: const Color(0xFFFFE800),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToForm(null);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color(0xFFFFE800);
    const Color surfaceColor = Color(0xFFF4F4F0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: accentColor),
      child: Scaffold(
        backgroundColor: surfaceColor,
        body: BlocConsumer<BookBloc, BookState>(
          listener: (context, state) {
            if (state is BookScannerSuccess) {
              _navigateToForm(state.scannedBook);
            } else if (state is BookScannerNotFound) {
              _navigateToForm(
                BookModel(
                  isbn: state.isbn,
                  title: '',
                  author: '',
                  pageCount: 0,
                  status: BookStatus.toRead,
                  addedViaScanner: true,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is BooksInitial || state is BooksLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            if (state is BooksError) {
              return Center(child: Text('Erro: ${state.message}'));
            }

            if (state is BooksLoaded) {
              final bool isProcessingScanner = state is BookScannerProcessing;

              String normalize(String? text) => (text ?? '').toLowerCase();

              final List<BookModel> filteredBooks = state.books
                  .where(
                    (b) =>
                        normalize(b.title).contains(normalize(_searchQuery)) ||
                        normalize(b.author).contains(normalize(_searchQuery)),
                  )
                  .toList();

              final List<BookModel> mystery = filteredBooks
                  .where(
                    (b) =>
                        normalize(b.genre).contains('investigação') ||
                        normalize(b.genre).contains('policial'),
                  )
                  .toList();

              final List<BookModel> classics = filteredBooks.where((b) {
                final genre = normalize(b.genre);
                return genre.contains('clássico') &&
                    !(genre.contains('investigação') ||
                        genre.contains('policial'));
              }).toList();

              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 40,
                            bottom: 40,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            border: const Border(
                              bottom: BorderSide(color: Colors.black, width: 3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.menu_book_rounded, size: 50),
                              Text(
                                'eLibrary',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Estante literária virtual com\nintegração de Inteligência Artificial.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _showAddBookOptions,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(3, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_box, size: 28),
                                      const SizedBox(width: 12),
                                      Text(
                                        'ADICIONAR LIVRO',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              _buildContainerSection(
                                'Clássicos',
                                _buildHorizontalShelf(classics),
                              ),
                              const SizedBox(height: 24),
                              _buildContainerSection(
                                'Mistério',
                                _buildHorizontalShelf(mystery),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isProcessingScanner)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(8, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 4,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Buscando...',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContainerSection(String title, Widget shelf) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE800),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 16),
          shelf,
        ],
      ),
    );
  }

  Widget _buildHorizontalShelf(List<BookModel> books) {
    if (books.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Nenhum livro aqui.',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookDetailsPage(book: book),
              ),
            ),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 16, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(3, 3)),
                ],
              ),
              child: (book.coverUrl ?? '').isNotEmpty
                  ? Image.network(
                      book.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          _buildNoCoverFallback(book.title),
                    )
                  : _buildNoCoverFallback(book.title),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoCoverFallback(String title) {
    return Container(
      color: const Color(0xFFC4A1FF),
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  InputDecoration _neobrutalistInput(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 4),
      ),
    );
  }
}
