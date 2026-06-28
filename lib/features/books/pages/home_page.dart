import 'package:flutter/material.dart';
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

    if (scannedIsbn != null && scannedIsbn.isNotEmpty) {
      if (mounted) {
        context.read<BookBloc>().add(FetchBookFromScannerEvent(isbn: scannedIsbn));
      }
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
      builder: (context) {
        return SafeArea(
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
                  color: const Color(0xFF00E5FF),
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
        );
      },
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
          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
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
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: BlocConsumer<BookBloc, BookState>(
          listener: (context, state) {
            if (state is BookScannerSuccess) {
              _navigateToForm(state.scannedBook);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Livro encontrado! Confirme os dados e salve.', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: Colors.green[800],
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              );
            } else if (state is BookScannerNotFound) {
              _navigateToForm(BookModel(
                isbn: state.isbn, title: '', author: '', pageCount: 0, status: BookStatus.toRead, addedViaScanner: true,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Livro não encontrado. Preencha manualmente.', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: Colors.red[800],
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              );
            } else if (state is BookScannerError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is BooksInitial || state is BooksLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }

            if (state is BooksError) {
              return Center(child: Text('Erro ao carregar dados: ${state.message}'));
            }

            if (state is BooksLoaded) {
              final bool isProcessingScanner = state is BookScannerProcessing;

              final List<BookModel> allBooks = state.books.where((book) {
                final searchLower = _searchQuery.toLowerCase();
                return book.title.toLowerCase().contains(searchLower) ||
                    book.author.toLowerCase().contains(searchLower) ||
                    book.isbn.contains(searchLower);
              }).toList();

              final List<BookModel> mysteryBooks = allBooks.where((book) {
                final genre = (book.genre ?? '').toLowerCase();
                return genre.contains('investigação') || genre.contains('policial');
              }).toList();

              final List<BookModel> classicBooks = allBooks.where((book) {
                final genre = (book.genre ?? '').toLowerCase();
                final isClassic = genre.contains('clássico');
                final isMystery = genre.contains('investigação') || genre.contains('policial');
                return isClassic && !isMystery;
              }).toList();

              return Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: bottomPadding + 40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'eLibrary',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Descubra, catalogue e analise.\nSua estante literária com o poder\nda inteligência artificial.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        /*TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() { _searchQuery = value; });
                          },
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Pesquisar por título, autor ou ISBN...',
                            hintStyle: GoogleFonts.spaceGrotesk(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search, color: Colors.black),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.black),
                              onPressed: () {
                                _searchController.clear();
                                setState(() { _searchQuery = ''; });
                              },
                            )
                                : null,
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 3),
                              borderRadius: BorderRadius.zero,
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 4),
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),*/

                        GestureDetector(
                          onTap: _showAddBookOptions,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            decoration: BoxDecoration(
                              color: accentColor,
                              border: Border.all(color: Colors.black, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(6, 6))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.document_scanner_rounded, size: 32, color: Colors.black),
                                const SizedBox(width: 12),
                                Text(
                                  'ADICIONAR LIVRO',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        _buildSectionTitle('Clássicos essenciais', accentColor),
                        const SizedBox(height: 16),
                        _buildHorizontalShelf(classicBooks),

                        const SizedBox(height: 40),

                        _buildSectionTitle('Mistério & Policial', accentColor),
                        const SizedBox(height: 16),
                        _buildHorizontalShelf(mysteryBooks),
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
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Colors.black, strokeWidth: 4),
                              const SizedBox(height: 24),
                              Text(
                                'Buscando metadados no\nGoogle Books...',
                                textAlign: TextAlign.center,
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

  Widget _buildSectionTitle(String title, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildHorizontalShelf(List<BookModel> books) {
    if (books.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Nenhum livro cadastrado nesta seção.',
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
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BookDetailsPage(book: book),
                ),
              );
            },
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 16, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                child: (book.coverUrl ?? '').isNotEmpty
                    ? Image.network(
                  book.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildNoCoverFallback(book.title),
                )
                    : _buildNoCoverFallback(book.title),
              ),
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
}