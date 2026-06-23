import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../auth_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final NuraVibe vibe;
  final Color accent;

  const ProfileSetupScreen({
    super.key,
    required this.vibe,
    required this.accent,
  });

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _bioController = TextEditingController();
  File? _avatarFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final bio = _bioController.text.trim();
    if (bio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci una Bio per continuare')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser!.id;

      String avatarUrl;
      if (_avatarFile != null) {
        final ext = _avatarFile!.path.split('.').last;
        final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path = 'public/$fileName';

        await client.storage.from('avatars').upload(path, _avatarFile!);
        avatarUrl = client.storage.from('avatars').getPublicUrl(path);
      } else {
        avatarUrl = 'https://ui-avatars.com/api/?name=Nura+User&background=00768A&color=fff&size=256';
      }

      // 2. Update profile
      await client.from('profiles').update({
        'bio': bio,
        'avatar_url': avatarUrl,
      }).eq('id', userId);

      // 3. Refresh auth state to proceed
      ref.invalidate(authStateProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NuraBrand.deepest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Completamento Profilo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Aggiungi i tuoi dettagli per far sapere agli altri chi sei.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: NuraBrand.deep,
                backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                child: _avatarFile == null
                    ? const Icon(Icons.camera_alt, size: 40, color: NuraBrand.mint)
                    : null,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _bioController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Bio',
                labelStyle: const TextStyle(color: NuraBrand.mint),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: NuraBrand.mint),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: NuraBrand.mint, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Completa Registrazione',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
