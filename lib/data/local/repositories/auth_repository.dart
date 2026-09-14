import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';

/// Authentification locale simple : un seul compte par appareil,
/// stocké de façon chiffrée via flutter_secure_storage (Keystore Android).
/// Correspond aux écrans "Page d'inscription" et "Page de connexion".
class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  /// Hash SHA-256 du mot de passe — jamais stocké en clair.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Indique si un compte a déjà été créé sur cet appareil.
  /// Utilisé pour rediriger vers Inscription ou Connexion au démarrage.
  Future<bool> isRegistered() async {
    final hash = await _storage.read(key: AppConstants.secureKeyPin);
    return hash != null;
  }

  /// Crée le compte local — écran "Page d'inscription".
  /// Un seul mot de passe/PIN par appareil (pas de nom d'utilisateur dans
  /// la maquette) : cohérent avec un agent de terrain = un appareil.
  /// Retourne une erreur explicite si le mot de passe est trop court
  /// ou si la confirmation ne correspond pas.
  Future<void> register({
    required String password,
    required String confirmPassword,
  }) async {
    if (password.length < AppConstants.minPasswordLength) {
      throw AuthException(
        'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caractères.',
      );
    }
    if (password != confirmPassword) {
      throw AuthException('Les mots de passe ne correspondent pas.');
    }

    await _storage.write(
      key: AppConstants.secureKeyPin,
      value: _hashPassword(password),
    );
  }

  /// Vérifie les identifiants — écran "Page de connexion".
  Future<bool> login(String password) async {
    final storedHash = await _storage.read(key: AppConstants.secureKeyPin);
    if (storedHash == null) {
      throw AuthException('Aucun compte enregistré sur cet appareil.');
    }
    return storedHash == _hashPassword(password);
  }

  /// Déconnexion — n'efface pas le compte, seulement l'état de session
  /// (géré côté UI/Provider, pas ici).
  Future<void> resetAccount() async {
    await _storage.deleteAll();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}