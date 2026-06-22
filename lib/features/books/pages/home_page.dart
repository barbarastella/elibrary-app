import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/book_model.dart';
import '../pages/book_form_page.dart';

class HomePage extends StatefulWidget {
  final String userId;
  const HomePage({super.key, required this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _booksStream;

  @override
  void initState() {
    super.initState();
    _booksStream = _firestore.collection('users').doc(widget.userId).collection('books').snapshots();
  }

  Widget build(BuildContext context) {
    const Color focalColor = Color(0xFFFFE800);
    const Color surfaceColor = Color(0xFFF4F4F0);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _booksStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.black));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
            }

            final List<BookModel> allBooks = snapshot.data?.docs.map((doc) {
              return BookModel.fromFirestore(doc);
            }).toList() ?? [];

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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('eLibrary', style: GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2, color: Colors.black)),
                  const SizedBox(height: 8),
                  Text('Descubra, catalogue e analise.\nSua estante literária com o poder\nda inteligência artificial.', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87, height: 1.2)),
                  const SizedBox(height: 32),

                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BookFormPage()));
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: focalColor,
                        border: Border.all(color: Colors.black, width: 3),
                        boxShadow: const [ BoxShadow(color: Colors.black, offset: Offset(6, 6), blurRadius: 0) ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.document_scanner_rounded, size: 32, color: Colors.black),
                          const SizedBox(width: 12),
                          Text('ADICIONAR LIVRO', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  _buildSectionTitle('Clássicos essenciais'),
                  const SizedBox(height: 16),
                  _buildHorizontalShelf(classicBooks),

                  const SizedBox(height: 40),

                  _buildSectionTitle('Mistério & Policial'),
                  const SizedBox(height: 16),
                  _buildHorizontalShelf(mysteryBooks),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black, width: 2)),
      child: Text(title.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
    );
  }

  Widget _buildHorizontalShelf(List<BookModel> books) {
    if (books.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text('Nenhum livro cadastrado nesta seção.', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: Colors.black54)),
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
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 16, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              boxShadow: const [ BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0) ],
            ),
            child: ClipRRect(
              child: (book.coverUrl ?? '').isNotEmpty
                  ? Image.network(
                book.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildNoCoverFallback(book.title),
              ) : _buildNoCoverFallback(book.title),
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
        child: Text(title, textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk( fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}
