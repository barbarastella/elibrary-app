import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthBloc({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn
  })
      : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn,
        super(const AuthInitialState()) {
    on<AuthCheckRequestedEvent>(_onAuthCheckRequested);
    on<AuthGoogleLoginRequestedEvent>(_onAuthGoogleLoginRequested);
    on<AuthLogoutRequestedEvent>(_onAuthLogoutRequested);
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequestedEvent event,
      Emitter<AuthState> emit) async {
    final user = _firebaseAuth.currentUser;

    if (user != null)
      emit(AuthenticatedState(user));
    else
      emit(const UnauthenticatedState());
  }

  Future<void> _onAuthGoogleLoginRequested(AuthGoogleLoginRequestedEvent event,
      Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        emit(const UnauthenticatedState());
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      if (userCredential.user != null)
        emit(AuthenticatedState(userCredential.user!));
      else
        emit(const AuthFailureState('Falha ao obter os dados do usuário.'));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailureState(e.message ?? 'Erro de autenticação no Firebase.'));
    } catch (e) {
      emit(AuthFailureState('Erro inesperado: $e'));
    }
  }

  Future<void> _onAuthLogoutRequested(AuthLogoutRequestedEvent event,
      Emitter<AuthState> emit) async {
    emit(const AuthLoadingState());

    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      emit(const UnauthenticatedState());
    }
    catch (e) {
      emit(AuthFailureState('Erro ao sair da conta.'));
    }
  }
}