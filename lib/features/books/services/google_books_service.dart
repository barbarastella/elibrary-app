import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../data/book_model.dart';
import '../data/book_status_enum.dart';

class GoogleBooksService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  Future<List<BookModel>> getBooksByIsbnList(List<String> isbns) async {
    try {
      final String apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';

      List<Future<BookModel?>> fetchTasks = isbns.map((isbn) async {
        final Uri url = Uri.parse('$_baseUrl?q=isbn:$isbn&key=$apiKey');
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final List<dynamic> items = data['items'] ?? [];

          if (items.isNotEmpty) {
            final item = items.first;
            final volumeInfo = item['volumeInfo'] ?? {};

            String rawCoverUrl = volumeInfo['imageLinks']?['thumbnail'] ?? '';
            String finalCoverUrl = rawCoverUrl.replaceAll('http:', 'https:');

            if (kIsWeb && finalCoverUrl.isNotEmpty) {
              finalCoverUrl = 'https://corsproxy.io/?${Uri.encodeComponent(finalCoverUrl)}';
            }

            return BookModel(
              isbn: isbn,
              title: volumeInfo['title'] ?? 'Título Desconhecido',
              author: (volumeInfo['authors'] as List<dynamic>?)?.first ?? 'Autor Desconhecido',
              pageCount: volumeInfo['pageCount'] ?? 0,
              coverUrl: finalCoverUrl,
              status: BookStatus.toRead,
              addedViaScanner: false,
            );
          }
        }
        return null;
      }).toList();

      final List<BookModel?> results = await Future.wait(fetchTasks);
      return results.whereType<BookModel>().toList();
    } catch (e) {
      throw Exception('Erro ao buscar lista de ISBNs: $e');
    }
  }
}
