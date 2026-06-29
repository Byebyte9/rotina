import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _kBaseUrl = 'https://api.rotina.life';

class AuthResult {
  final bool success;
  final String? token;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthResult({this.success = false, this.token, this.user, this.error});
}

class SyncResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? syncedAt;
  final String? error;

  const SyncResult({this.success = false, this.data, this.syncedAt, this.error});
}

class AuthService {
  static const _headers = {'Content-Type': 'application/json'};

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<AuthResult> register({
    required String email,
    required String senha,
    required String nome,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode({'email': email, 'senha': senha, 'nome': nome}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201) {
        return AuthResult(
          success: true,
          token: body['token'] as String,
          user: body['user'] as Map<String, dynamic>,
        );
      }
      return AuthResult(error: body['error'] as String? ?? 'Erro ao cadastrar');
    } catch (_) {
      return const AuthResult(error: 'Não foi possível conectar ao servidor');
    }
  }

  static Future<AuthResult> login({
    required String email,
    required String senha,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'senha': senha}),
          )
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200) {
        return AuthResult(
          success: true,
          token: body['token'] as String,
          user: body['user'] as Map<String, dynamic>,
        );
      }
      return AuthResult(error: body['error'] as String? ?? 'Email ou senha incorretos');
    } catch (_) {
      return const AuthResult(error: 'Não foi possível conectar ao servidor');
    }
  }

  static Future<SyncResult> pushData({
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBaseUrl/sync'),
            headers: _authHeaders(token),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return SyncResult(success: true, syncedAt: body['synced_at'] as String?);
      }
      return const SyncResult(error: 'Erro ao sincronizar');
    } catch (_) {
      return const SyncResult(error: 'Sem conexão com o servidor');
    }
  }

  static Future<SyncResult> pullData({required String token}) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_kBaseUrl/sync'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return SyncResult(
          success: true,
          data: body['data'] as Map<String, dynamic>?,
          syncedAt: body['synced_at'] as String?,
        );
      }
      return const SyncResult(error: 'Erro ao buscar dados');
    } catch (_) {
      return const SyncResult(error: 'Sem conexão com o servidor');
    }
  }

  /// Solicita redefinição de senha por email.
  static Future<({bool ok, String? error})> forgotPassword({
    required String email,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/forgot-password'),
            headers: _headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return (ok: true, error: null);
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (ok: false, error: body['error'] as String? ?? 'Erro ao enviar email');
      } catch (_) {
        return (ok: false, error: 'Erro ao enviar email');
      }
    } catch (_) {
      return (ok: false, error: 'Não foi possível conectar ao servidor');
    }
  }

  /// Verifica o email com código de 6 dígitos.
  static Future<({bool ok, String? error})> verifyEmailCode({
    required String token,
    required String code,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/verify-email'),
            headers: _authHeaders(token),
            body: jsonEncode({'code': code}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return (ok: true, error: null);
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (ok: false, error: body['error'] as String? ?? 'Código inválido');
      } catch (_) {
        return (ok: false, error: 'Código inválido');
      }
    } catch (_) {
      return (ok: false, error: 'Não foi possível conectar ao servidor');
    }
  }

  /// Reenvia o email de verificação.
  static Future<({bool ok, String? error})> resendVerification({
    required String token,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/resend-verification'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return (ok: true, error: null);
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (ok: false, error: body['error'] as String? ?? 'Erro ao enviar email');
      } catch (_) {
        return (ok: false, error: 'Erro ao enviar email');
      }
    } catch (_) {
      return (ok: false, error: 'Não foi possível conectar ao servidor');
    }
  }

  static Future<({bool ok, String? error})> sendFeedback({
    required String token,
    required String tipo,
    required String mensagem,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBaseUrl/feedback'),
            headers: _authHeaders(token),
            body: jsonEncode({'tipo': tipo, 'mensagem': mensagem}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return (ok: true, error: null);
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (ok: false, error: body['error'] as String? ?? 'Erro ao enviar feedback');
      } catch (_) {
        return (ok: false, error: 'Erro ao enviar feedback');
      }
    } catch (_) {
      return (ok: false, error: 'Não foi possível conectar ao servidor');
    }
  }

  static Future<({bool ok, String? error})> changePassword({
    required String token,
    required String senhaAtual,
    required String novaSenha,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_kBaseUrl/auth/change-password'),
            headers: _authHeaders(token),
            body: jsonEncode({'senhaAtual': senhaAtual, 'novaSenha': novaSenha}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) return (ok: true, error: null);
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (ok: false, error: body['error'] as String? ?? 'Erro ao alterar a senha');
      } catch (_) {
        return (ok: false, error: 'Erro ao alterar a senha');
      }
    } catch (_) {
      return (ok: false, error: 'Não foi possível conectar ao servidor');
    }
  }

  static Future<bool> updateName({
    required String token,
    required String nome,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$_kBaseUrl/auth/me'),
            headers: _authHeaders(token),
            body: jsonEncode({'nome': nome}),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteAccountOnServer({required String token}) async {
    try {
      final res = await http
          .delete(
            Uri.parse('$_kBaseUrl/auth/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200 || res.statusCode == 404;
    } catch (e) {
      debugPrint('[AuthService] deleteAccountOnServer erro: $e');
      return false;
    }
  }
}
