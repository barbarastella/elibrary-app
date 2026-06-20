import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/pages/login_page.dart';

import './features/books/book_repository.dart';
import './features/books/bloc/book_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ElibraryApp());
}

class ElibraryApp extends StatelessWidget {
  const ElibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final bookRepository = BookRepository(
      firestore: FirebaseFirestore.instance,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) {
            final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

            final bloc = AuthBloc(
              firebaseAuth: FirebaseAuth.instance,
              googleSignIn: GoogleSignIn(clientId: kIsWeb ? webClientId : null),
            );

            bloc.add(const AuthCheckRequestedEvent());
            return bloc;
          },
        ),
        BlocProvider<BookBloc>(
          create: (context) => BookBloc(bookRepository: bookRepository),
        ),
      ],
      child: MaterialApp(
        title: 'eLibrary App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const LoginPage(),
      ),
    );
  }
}
