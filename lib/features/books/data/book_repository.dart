import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'book_model.dart';

class BookRepository {
  final FirebaseFirestore _firestore;

  BookRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    Gemini.init(
      apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      enableDebugging: true,
    );
  }

  CollectionReference<Map<String, dynamic>> _userBooksCollection(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).collection('books');
  }

  Future<void> addBook({
    required String userId,
    required BookModel book,
  }) async {
    try {
      final docRef = _userBooksCollection(userId).doc(book.isbn);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists)
        throw 'Um livro com este ISBN já está na sua estante.';

      await docRef.set(book.toFirestore());
    } catch (e) {
      throw Exception(e.toString().replaceAll('Erro ao adicionar livro: ', ''));
    }
  }

  Stream<List<BookModel>> getUserBookStream(String userId) {
    return _userBooksCollection(
      userId,
    ).orderBy('addedAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> updateBook({
    required String userId,
    required BookModel book,
  }) async {
    try {
      if (book.id == null) throw Exception('O bookId não pode ser nulo');

      await _userBooksCollection(
        userId,
      ).doc(book.id).update(book.toFirestore());
    } catch (e) {
      throw Exception('Erro ao fazer update do book: $e');
    }
  }

  Future<void> deleteBook({
    required String userId,
    required String bookId,
  }) async {
    try {
      await _userBooksCollection(userId).doc(bookId).delete();
    } catch (e) {
      throw Exception('Erro ao fazer delete do book: $e');
    }
  }

  Future<void> generateAndSaveInsights({
    required String userId,
    required BookModel book,
  }) async {
    try {
      print("\n\n\n---------- INICIANDO GEMINI ----------");

      final String prompt = '''
        Escreva uma sinopse direta, comercial e envolvente do livro '${book.title}' escrito por ${book.author} (Gênero: ${book.genre ?? 'Desconhecido'}).
        Regras para a sinopse:
        1. Deve ter no máximo 120 palavras.
        2. Não faça análises críticas acadêmicas, foque no enredo e na premissa.
        3. Use texto puro e limpo, proibido usar negritos com asteriscos (**) ou títulos com hashtags (#).

        Em seguida, liste exatamente 3 livros similares ou que dialoguem com esta obra, focando em clássicos ou alta literatura. Formate cada indicação como "Título do Livro (Ano) - Autor".

        Retorne a resposta ESTRITAMENTE no seguinte formato exato, separando o resumo das recomendações com três barras verticais (|||):

        [Sua sinopse de até 250 palavras aqui]
        |||
        [Livro 1]
        [Livro 2]
        [Livro 3]
      ''';

      final response = await Gemini.instance.prompt(parts: [Part.text(prompt)]);
      final String responseText = response?.output ?? '';

      if (responseText.isEmpty)
        throw Exception('A API do Gemini retornou resposta vazia.');

      final parts = responseText.split('|||');

      final String summary = parts.isNotEmpty
          ? parts[0].trim()
          : "Erro ao gerar resumo";
      final String recommendations = parts.length > 1
          ? parts[1].trim()
          : "Erro ao gerar recomendações";

      await _userBooksCollection(userId).doc(book.id ?? book.isbn).update({
        'geminiSummary': summary,
        'geminiRecommendations': recommendations,
      });
    } catch (e) {
      final errorString = e.toString();

      print("\n\n\n---------- ERRO DO GEMINI ----------");

      if (errorString.contains('503') || errorString.contains('UNAVAILABLE') || errorString.contains('high demand'))  {
            print('\n\n\n Gemini indisponível!');

            // textos genéricos
            final fallbackSummary = "Uma obra que captura a essência do seu gênero através de uma narrativa envolvente e bem construída. O autor explora a premissa com maestria, conduzindo o leitor por uma jornada que equilibra perfeitamente o desenvolvimento do enredo e a profundidade dos temas centrais. Uma leitura recomendada para quem busca uma experiência literária instigante.";
            final fallbackRecommendations = "O Conde de Monte Cristo (1844) - Alexandre Dumas\nDom Quixote (1605) - Miguel de Cervantes\nOs Miseráveis (1862) - Victor Hugo";

            await _userBooksCollection(userId).doc(book.id ?? book.isbn).update({
              'geminiSummary': fallbackSummary,
              'geminiRecommendations': fallbackRecommendations
            });

            return;
      }

      if (errorString.contains('SocketException') || errorString.contains('Failed host lookup')) {
        throw Exception('Erro de conexão com a internet.');
      }

      throw Exception('Erro ao gerar insights do Gemini.');
    }
  }
}
