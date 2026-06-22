import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/book_model.dart';
import '../data/book_status_enum.dart';
import '../bloc/book_bloc.dart';
import '../bloc/book_event.dart';
import '../bloc/book_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';


class BookFormPage extends StatefulWidget {
  final BookModel? existingBook;
  const BookFormPage({super.key, this.existingBook});

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _isbnController;
  late TextEditingController _pageCountController;
  late TextEditingController _coverUrlController;

  BookStatus _currentStatus = BookStatus.toRead;
  String? _selectedGenre;

  bool _isSubmitting = false;
  String? _isbnAsyncError;

  static const List<String> _genreOptions = [
    'Clássico',
    'Mistério / Policial',
    'Ficção',
    'Não-ficção',
    'Fantasia',
    'Ficção Científica',
    'Biografia',
    'Tecnologia',
    'Outro',
  ];

  bool get isEditing => widget.existingBook != null;

  @override
  void initState() {
    super.initState();
    final book = widget.existingBook;

    _titleController = TextEditingController(text: book?.title ?? '');
    _authorController = TextEditingController(text: book?.author ?? '');
    _isbnController = TextEditingController(text: book?.isbn ?? '');
    _pageCountController = TextEditingController(
      text: book?.pageCount.toString() ?? '',
    );
    _coverUrlController = TextEditingController(text: book?.coverUrl ?? '');

    if (book != null) _currentStatus = book.status;

    final String? existingGenre = book?.genre;

    if (existingGenre != null && existingGenre.isNotEmpty) {
      _selectedGenre = _genreOptions.contains(existingGenre)
          ? existingGenre
          : 'Outro';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _pageCountController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    setState(() {_isbnAsyncError = null;});

    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthenticatedState) return;

    final String currentUserId = authState.user.uid;
    final String isbn = _isbnController.text.trim();

    setState(() {_isSubmitting = true;});

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('books')
          .doc(isbn)
          .get();

      bool isDuplicate = false;

      if (docSnapshot.exists) {
        if (!isEditing) {
          isDuplicate = true;
        } else if (widget.existingBook?.id != docSnapshot.id) {
          isDuplicate = true;
        }
      }

      if (isDuplicate) {
        setState(() {
          _isbnAsyncError = 'Este ISBN já está cadastrado.';
          _isSubmitting = false;
        });
        _formKey.currentState!.validate();
        return;
      }

      final formData = BookModel(
        id: widget.existingBook?.id,
        isbn: _isbnController.text.trim(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _selectedGenre,
        pageCount: int.tryParse(_pageCountController.text.trim()) ?? 0,
        coverUrl: _coverUrlController.text.trim(),
        status: _currentStatus,
        addedViaScanner: widget.existingBook?.addedViaScanner ?? false,
        geminiSummary: widget.existingBook?.geminiSummary,
        geminiRecommendations: widget.existingBook?.geminiRecommendations,
      );

      if (isEditing) {
        context.read<BookBloc>().add(
          UpdateBookRequestedEvent(userId: currentUserId, book: formData),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alterações salvas!'),
              backgroundColor: Colors.black),
        );
      } else {
        context.read<BookBloc>().add(
          AddBookRequestedEvent(userId: currentUserId, book: formData),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livro adicionado à estante!'),
              backgroundColor: Colors.black),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao verificar conexão com o servidor.'), backgroundColor: Colors.red)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color surfaceColor = Color(0xFFF4F4F0);
    const Color accentColor = Color(0xFF00E5FF);

    return BlocConsumer<BookBloc, BookState>(
      listener: (context, state) {
        if (state is BooksError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        final bool isProcessing = (state is BooksLoading) || _isSubmitting;

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
              isEditing ? 'Editar livro' : 'Adicionar livro',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1,
              ),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: _neobrutalistInput('Título do livro *'),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'O título é obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _authorController,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: _neobrutalistInput('Autor *'),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'O autor é obrigatório'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGenre,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 28,
                        ),
                        dropdownColor: Colors.white,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        decoration: _neobrutalistInput('Gênero literário *'),
                        items: _genreOptions.map((String genre) {
                          return DropdownMenuItem<String>(
                            value: genre,
                            child: Text(genre),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedGenre = newValue;
                          });
                        },
                        validator: (value) =>
                        value == null ? 'Selecione um gênero.' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _isbnController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: _neobrutalistInput('ISBN *'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'O ISBN é obrigatório';
                                }
                                if (value.trim().length < 10) {
                                  return 'ISBN inválido';
                                }
                                if (_isbnAsyncError != null) return _isbnAsyncError;
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _pageCountController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: _neobrutalistInput('Páginas'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _coverUrlController,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: _neobrutalistInput('URL da capa'),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: isProcessing ? null : _submitForm,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: isProcessing ? Colors.grey : accentColor,
                            border: Border.all(color: Colors.black, width: 3),
                            boxShadow: isProcessing ? null : const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(6, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: isProcessing
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 3,
                              ),
                            )
                                : Text(
                              isEditing
                                  ? 'Salvar alterações'
                                  : 'Adicionar à estante',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 1,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isProcessing)
                const ModalBarrier(dismissible: false, color: Colors.black12),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _neobrutalistInput(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.spaceGrotesk(
        color: Colors.black87,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.zero,
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 4),
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}