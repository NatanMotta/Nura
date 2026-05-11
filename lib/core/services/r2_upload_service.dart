import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';

class R2SignedUploadTicket {
  final String uploadUrl;
  final String storagePath;
  final Map<String, String> headers;

  const R2SignedUploadTicket({
    required this.uploadUrl,
    required this.storagePath,
    required this.headers,
  });

  factory R2SignedUploadTicket.fromJson(Map<String, dynamic> json) {
    final headersRaw = (json['headers'] as Map?)?.cast<String, dynamic>() ?? {};
    return R2SignedUploadTicket(
      uploadUrl: (json['uploadUrl'] as String?) ?? '',
      storagePath: (json['storagePath'] as String?) ?? '',
      headers: headersRaw.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

class R2UploadResult {
  final String storagePath;

  const R2UploadResult({required this.storagePath});
}

class R2UploadService {
  SupabaseClient _client() {
    if (!SupabaseBootstrap.isInitialized) {
      throw StateError(
        'SUPABASE_NOT_INITIALIZED: avvia con --dart-define SUPABASE_URL e SUPABASE_ANON_KEY',
      );
    }
    return Supabase.instance.client;
  }

  Future<R2SignedUploadTicket> requestSignedUpload({
    required String fileName,
    required String contentType,
    required int bytesLength,
  }) async {
    final client = _client();

    final response = await client.functions.invoke(
      'r2-sign-upload',
      body: {
        'fileName': fileName,
        'contentType': contentType,
        'bytesLength': bytesLength,
      },
    );

    if (response.status != 200) {
      throw StateError('R2 sign failed: status=${response.status} data=${response.data}');
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('R2 sign failed: invalid response body');
    }

    final ticket = R2SignedUploadTicket.fromJson(data);
    if (ticket.uploadUrl.isEmpty || ticket.storagePath.isEmpty) {
      throw StateError('R2 sign failed: missing uploadUrl/storagePath');
    }

    return ticket;
  }

  Future<R2UploadResult> uploadBytes({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final ticket = await requestSignedUpload(
      fileName: fileName,
      contentType: contentType,
      bytesLength: bytes.length,
    );

    final uri = Uri.parse(ticket.uploadUrl);
    final http = HttpClient();

    try {
      final req = await http.putUrl(uri);
      req.headers.set(HttpHeaders.contentTypeHeader, contentType);
      for (final entry in ticket.headers.entries) {
        req.headers.set(entry.key, entry.value);
      }
      req.add(bytes);
      final res = await req.close();
      final body = await utf8.decodeStream(res);

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw StateError('R2 upload failed: status=${res.statusCode} body=$body');
      }

      return R2UploadResult(storagePath: ticket.storagePath);
    } finally {
      http.close(force: true);
    }
  }
}
