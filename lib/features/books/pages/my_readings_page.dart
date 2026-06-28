import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/book_bloc.dart';
import '../bloc/book_state.dart';
import '../data/book_model.dart';
import '../data/book_status_enum.dart';
import 'book_details_page.dart';

class MyReadingsPage extends StatelessWidget {
  const MyReadingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color surfaceColor = Color(0xFFF4F4F0);
    const Color accentColor = Color(0xFF28A745);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(backgroundColor: accentColor, title: Text("MINHAS LEITURAS", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: Colors.black)),
      bottom: PreferredSize(preferredSize: const Size.fromHeight(3.0), child: Container(color: Colors.black, height: 3.0)),
      ),
      body: BlocBuilder<BookBloc, BookState>(
        builder: (context, state) {
          if (state is BooksLoaded) {
            return ListView(padding: const EdgeInsets.all(16),
            children: [
              _buildSection(context, 'Lendo', state.books.where((b) => b.status == BookStatus.reading).toList(), accentColor),
              _buildSection(context, 'Quero Ler', state.books.where((b) => b.status == BookStatus.toRead).toList(), accentColor),
              _buildSection(context, 'Lidos', state.books.where((b) => b.status == BookStatus.read).toList(), accentColor),
              _buildSection(context, 'Abandonados', state.books.where((b) => b.status == BookStatus.abandoned).toList(), accentColor),
            ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        }
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<BookModel> books, Color accentColor) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Text(
                title.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)
            ),
          ),
        ),
        ...books.map((book) => _buildBookTile(context, book, accentColor)),
      ],
    );
  }

  Widget _buildBookTile(BuildContext context, BookModel book, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2)
      ),
      child: ListTile(
        title: Text(book.title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        subtitle: Text(book.author),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 20, color: accentColor, weight: 900),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsPage(book: book))),
      ),
    );
  }

}