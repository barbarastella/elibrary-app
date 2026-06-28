import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/book_model.dart';
import '../data/book_status_enum.dart';
import '../bloc/book_bloc.dart';
import '../bloc/book_event.dart';
import '../bloc/book_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import 'book_form_page.dart';

class BookDetailsPage extends StatelessWidget {
  final BookModel book;
  const BookDetailsPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    const Color surfaceColor = Color(0xFFF4F4F0);
    const Color accentColor = Color(0xFFFF5900);

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocConsumer<BookBloc, BookState>(
      listener: (context, state) {
        if (state is BooksError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        BookModel currentBook = book;

        if (state is BooksLoaded) {
          final updatedBooks = state.books.where((b) => b.id == book.id);
          if (updatedBooks.isNotEmpty) currentBook = updatedBooks.first;
        }

        final String statusText = _translateStatus(currentBook.status);
        final bool isLoading = state is BooksLoading;

        return Scaffold(
          backgroundColor: surfaceColor,
          appBar: AppBar(
            backgroundColor: accentColor,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3.0),
              child: Container(color: Colors.black, height: 3.0),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'DETALHES',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.edit_square,
                  color: Colors.black,
                  size: 26,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          BookFormPage(existingBook: currentBook),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.black,
                  size: 28,
                ),
                onPressed: () => _showDeleteConfirmation(context, currentBook),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: bottomInset > 0 ? bottomInset + 24.0 : bottomPadding + 40.0
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(3, 3)),
                        ],
                      ),
                      child: (currentBook.coverUrl ?? '').isNotEmpty
                          ? Image.network(
                              currentBook.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildNoCoverFallback(currentBook.title),
                            )
                          : _buildNoCoverFallback(currentBook.title),
                    ),
                    const SizedBox(width: 20),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentBook.title.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: -0.5,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentBook.author,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDataChip('GÊNERO', currentBook.genre ?? 'N/A'),
                          const SizedBox(height: 8),
                          _buildDataChip(
                            'PÁGINAS',
                            currentBook.pageCount > 0
                                ? currentBook.pageCount.toString()
                                : 'N/A',
                          ),
                          const SizedBox(height: 8),
                          _buildDataChip('STATUS', statusText),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ISBN: ${currentBook.isbn}',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Adicionado em: ${currentBook.addedAt != null ? "${currentBook.addedAt!.day}/${currentBook.addedAt!.month}/${currentBook.addedAt!.year}" : "N/A"}',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  'RESUMO & RECOMENDAÇÕES',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 16),

                if (currentBook.geminiSummary == null ||
                    currentBook.geminiSummary!.isEmpty)
                  _buildEmptyAIFallback(
                    context,
                    currentBook,
                    isLoading,
                    accentColor,
                  )
                else ...[
                  _buildSynopsisCard(currentBook.geminiSummary!, accentColor),

                  const SizedBox(height: 24),

                  if (currentBook.geminiRecommendations != null &&
                      currentBook.geminiRecommendations!.isNotEmpty)
                    _buildRecommendationsCard(
                      currentBook.geminiRecommendations!,
                      accentColor,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSynopsisCard(String summary, Color accentColor) {
    final cleanSummary = summary
        .replaceAll('*', '')
        .trim(); // garantir que não veio com markdown

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(2, 2)),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: Colors.black, size: 22),
                const SizedBox(width: 8),
                Text(
                  'RESUMO DO LIVRO',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            child: Text(
              cleanSummary,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(
    List<String> recommendations,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor,
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore, color: Colors.black, size: 24),
              const SizedBox(width: 8),
              Text(
                'LIVROS SIMILARES',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ...recommendations.map((rec) {
            final cleanRec = rec
                .replaceAll(RegExp(r'^[-*]\s*'), '')
                .replaceAll('*', '')
                .trim();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.book_outlined, color: Colors.black, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cleanRec,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _translateStatus(BookStatus status) {
    switch (status) {
      case BookStatus.toRead:
        return 'Quero Ler';
      case BookStatus.reading:
        return 'Lendo';
      case BookStatus.read:
        return 'Lido';
      default:
        return 'Desconhecido';
    }
  }

  Widget _buildDataChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildNoCoverFallback(String title) {
    return Container(
      color: const Color(0xFFFFE800),
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAIFallback(
    BuildContext context,
    BookModel currentBook,
    bool isLoading,
    Color accentColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.smart_toy_outlined, size: 48, color: Colors.black54),
          const SizedBox(height: 12),
          Text(
            'Gere um breve resumo do livro e\nrecomendações de temática semelhante!',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: isLoading
                ? null
                : () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthenticatedState) {
                      context.read<BookBloc>().add(
                        GenerateBookInsightsEvent(
                          userId: authState.user.uid,
                          book: currentBook,
                        ),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey : accentColor,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: isLoading
                    ? null
                    : const [
                        BoxShadow(color: Colors.black, offset: Offset(3, 3)),
                      ],
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GERAR COM GEMINI',
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, BookModel currentBook) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.black, width: 3),
            borderRadius: BorderRadius.zero,
          ),
          title: Text(
            'EXCLUIR LIVRO?',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Tem certeza que deseja apagar "${currentBook.title}" da sua estante? Esta ação não pode ser desfeita.',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final authState = context.read<AuthBloc>().state;

                if (authState is AuthenticatedState) {
                  context.read<BookBloc>().add(
                    DeleteBookRequestedEvent(
                      userId: authState.user.uid,
                      bookId: currentBook.id ?? currentBook.isbn,
                    ),
                  );

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Livro removido da estante.'),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              child: Text(
                'EXCLUIR',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
