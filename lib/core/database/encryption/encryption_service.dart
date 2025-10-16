import 'dart:convert';
import 'dart:typed_data';
import 'package:clinic_core/core/utils/logger_util.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const String _keyStorageKey = 'clinic_encryption_key';
  static const String _ivStorageKey = 'clinic_encryption_iv';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  encrypt.Key? _key;
  encrypt.IV? _iv;
  encrypt.Encrypter? _encrypter;

  Future<void> initialize() async {
    try {
      // Check if encryption keys exist
      String? storedKey = await _secureStorage.read(key: _keyStorageKey);
      String? storedIv = await _secureStorage.read(key: _ivStorageKey);

      if (storedKey == null || storedIv == null) {
        // Generate new keys
        _key = encrypt.Key.fromSecureRandom(32); // 256-bit key
        _iv = encrypt.IV.fromSecureRandom(16); // 128-bit IV

        // Store keys securely
        await _secureStorage.write(
          key: _keyStorageKey,
          value: base64.encode(_key!.bytes),
        );
        await _secureStorage.write(
          key: _ivStorageKey,
          value: base64.encode(_iv!.bytes),
        );

        LoggerUtil.info('New encryption keys generated and stored');
      } else {
        // Load existing keys
        _key = encrypt.Key(base64.decode(storedKey));
        _iv = encrypt.IV(base64.decode(storedIv));

        LoggerUtil.info('Encryption keys loaded from secure storage');
      }

      _encrypter = encrypt.Encrypter(encrypt.AES(_key!));
    } catch (e) {
      LoggerUtil.error('Error initializing encryption service: $e');
      rethrow;
    }
  }

  String encryptString(String plainText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      LoggerUtil.error('Error encrypting string: $e');
      rethrow;
    }
  }

  String decryptString(String encryptedText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv);
    } catch (e) {
      LoggerUtil.error('Error decrypting string: $e');
      rethrow;
    }
  }

  String hashPassword(String password, {String? salt}) {
    salt ??= encrypt.Key.fromSecureRandom(16).base64;
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  bool verifyPassword(String password, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');
      if (parts.length != 2) return false;

      final salt = parts[0];
      final hash = parts[1];

      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);

      return digest.toString() == hash;
    } catch (e) {
      LoggerUtil.error('Error verifying password: $e');
      return false;
    }
  }

  Future<Uint8List> encryptFile(Uint8List fileBytes) async {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = _encrypter!.encryptBytes(fileBytes, iv: _iv);
      return encrypted.bytes;
    } catch (e) {
      LoggerUtil.error('Error encrypting file: $e');
      rethrow;
    }
  }

  Future<Uint8List> decryptFile(Uint8List encryptedBytes) async {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = encrypt.Encrypted(encryptedBytes);
      return Uint8List.fromList(_encrypter!.decryptBytes(encrypted, iv: _iv));
    } catch (e) {
      LoggerUtil.error('Error decrypting file: $e');
      rethrow;
    }
  }
}
