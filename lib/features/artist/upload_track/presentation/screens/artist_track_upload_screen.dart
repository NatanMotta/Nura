import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_audio_toolkit/flutter_audio_toolkit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/services/r2_upload_service.dart';
import '../../../../discovery/swipe/data/remote_tracks_service.dart';
import '../../../data/track_upload_repository.dart';

class ArtistTrackUploadScreen extends ConsumerStatefulWidget {
  const ArtistTrackUploadScreen({super.key});

  @override
  ConsumerState<ArtistTrackUploadScreen> createState() =>
      _ArtistTrackUploadScreenState();
}

class _ArtistTrackUploadScreenState
    extends ConsumerState<ArtistTrackUploadScreen> {
  final _titleController = TextEditingController();
  final _previewStartController = TextEditingController(text: '0');
  double _previewStartSeconds = 0.0;
  double _trackDuration = 300.0;

  String _selectedGenre = 'Pop';
  final List<String> _genres = [
    'Pop',
    'Rap',
    'Rock',
    'Indie',
    'Elettronica',
    'R&B',
    'Trap',
    'Classica',
    'Jazz'
  ];

  PlatformFile? _audioFile;
  PlatformFile? _coverFile;

  bool _isUploading = false;
  String _uploadStatus = '';

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      double len = 300.0;

      if (file.path != null) {
        try {
          if (!SoLoud.instance.isInitialized) {
            await SoLoud.instance.init();
          }
          final source = await SoLoud.instance.loadFile(file.path!);
          len = SoLoud.instance.getLength(source).inSeconds.toDouble();
          SoLoud.instance.disposeSource(source);
        } catch (e) {
          debugPrint('Could not load duration: $e');
        }
      }

      setState(() {
        _audioFile = file;
        _trackDuration = len;
        _previewStartSeconds = 0.0;
        _previewStartController.text = '0';
      });
    }
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _coverFile = result.files.first;
      });
    }
  }

  Future<void> _upload() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Inserisci un titolo per il brano.');
      return;
    }
    if (_audioFile == null || _audioFile!.bytes == null) {
      _showError('Seleziona il file audio del brano.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Inizializzazione caricamento...';
    });

    try {
      final r2 = R2UploadService();

      String? coverStoragePath;

      if (_coverFile != null && _coverFile!.bytes != null) {
        setState(() => _uploadStatus = 'Caricamento copertina...');
        final coverExt =
            _coverFile!.extension?.replaceAll('jpeg', 'jpg') ?? 'jpg';
        final coverName =
            'cover_${DateTime.now().millisecondsSinceEpoch}.$coverExt';

        final coverResult = await r2.uploadBytes(
          bytes: _coverFile!.bytes!,
          fileName: coverName,
          contentType: 'image/$coverExt',
          objectType: 'cover',
        );
        coverStoragePath = coverResult.storagePath;
      }

      String audioExt = _audioFile!.extension?.toLowerCase() ?? 'mp3';
      Uint8List audioBytes = _audioFile!.bytes!;

      setState(() => _uploadStatus =
          'Caricamento audio in corso (potrebbe volerci un po\')...');

      // SILENT OFFLINE CONVERSION: Convert WAV to M4A to save DB costs and bandwidth
      if (audioExt == 'wav' && _audioFile!.path != null) {
        try {
          final toolkit = FlutterAudioToolkit();
          final tempDir = await getTemporaryDirectory();
          final outputPath =
              '${tempDir.path}/track_${DateTime.now().millisecondsSinceEpoch}.m4a';

          final result = await toolkit.convertAudio(
            inputPath: _audioFile!.path!,
            outputPath: outputPath,
            format: AudioFormat.m4a,
            bitRate: 320,
          );

          final file = File(result.outputPath);
          audioBytes = await file.readAsBytes();
          audioExt = 'm4a';

          try {
            file.delete();
          } catch (_) {}
        } catch (e) {
          debugPrint('Conversion fallita, procedo con file originale: $e');
          audioExt = _audioFile!.extension ?? 'wav';
        }
      } else {
        audioExt = _audioFile!.extension ?? 'wav';
      }

      final fileName =
          'track_${DateTime.now().millisecondsSinceEpoch}.$audioExt';

      final audioContentType = switch (audioExt) {
        'wav' => 'audio/wav',
        'm4a' => 'audio/mp4',
        _ => 'audio/mpeg',
      };
      final requiresTranscoding = audioExt == 'wav';

      final r2Result = await r2.uploadBytes(
        bytes: audioBytes,
        fileName: fileName,
        contentType: audioContentType,
        objectType: requiresTranscoding ? 'audio_raw' : 'audio',
      );

      setState(() => _uploadStatus = 'Salvataggio record nel database...');

      final repo = ref.read(trackUploadRepositoryProvider);
      await repo.createTrackRecord(
        title: _titleController.text.trim(),
        audioStoragePath: r2Result.storagePath,
        coverStoragePath: coverStoragePath,
        durationSeconds: _trackDuration.toInt(),
        genre: _selectedGenre,
        sourceContentType: audioContentType,
        requiresTranscoding: requiresTranscoding,
      );
      RemoteTracksService.clearCache();

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      _showError('Errore durante l\'upload: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showGenrePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Seleziona Genere',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _genres.length,
                itemBuilder: (context, index) {
                  final genre = _genres[index];
                  final isSelected = genre == _selectedGenre;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      genre,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? NuraBrand.pink : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: NuraBrand.pink)
                        : null,
                    onTap: () {
                      setState(() => _selectedGenre = genre);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Nuovo Brano',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dettagli Traccia',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 24),

                  // Titolo
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    cursorColor: NuraBrand.pink,
                    decoration: InputDecoration(
                      labelText: 'Titolo del brano',
                      labelStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Genere
                  GestureDetector(
                    onTap: _showGenrePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Genere',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(_selectedGenre,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black87)),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Cover
                  GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _coverFile != null
                            ? NuraBrand.pink.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _coverFile != null
                              ? NuraBrand.pink
                              : Colors.black12,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.image_outlined,
                            color: _coverFile != null
                                ? NuraBrand.pink
                                : Colors.black45,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _coverFile != null
                                      ? 'Copertina Selezionata'
                                      : 'Copertina (Opzionale)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _coverFile != null
                                        ? NuraBrand.pink
                                        : Colors.black87,
                                  ),
                                ),
                                if (_coverFile != null)
                                  Text(
                                    _coverFile!.name,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                else
                                  const Text(
                                    'Tocca per caricare l\'immagine della traccia',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // File Audio
                  GestureDetector(
                    onTap: _pickAudio,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _audioFile != null
                            ? NuraBrand.mint.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _audioFile != null
                              ? NuraBrand.mint
                              : Colors.black12,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.audiotrack,
                            color: _audioFile != null
                                ? NuraBrand.mint
                                : Colors.black45,
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _audioFile != null
                                      ? 'File Selezionato'
                                      : 'Seleziona Audio (MP3/WAV)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _audioFile != null
                                        ? NuraBrand.mint
                                        : Colors.black87,
                                  ),
                                ),
                                if (_audioFile != null)
                                  Text(
                                    _audioFile!.name,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Preview Start Time
                  const Text(
                    'Scoperta (Preview di 15s)',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Scegli i 15 secondi da mostrare nella discovery.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(_previewStartSeconds ~/ 60)}:${(_previewStartSeconds.toInt() % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: NuraBrand.pink),
                            ),
                            Text(
                              '${((_previewStartSeconds + 15) ~/ 60)}:${((_previewStartSeconds.toInt() + 15) % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 8,
                            activeTrackColor: NuraBrand.pink,
                            inactiveTrackColor:
                                NuraBrand.pink.withValues(alpha: 0.1),
                            thumbColor: NuraBrand.pink,
                            overlayColor: NuraBrand.pink.withValues(alpha: 0.2),
                          ),
                          child: Slider(
                            value: _previewStartSeconds,
                            min: 0,
                            max: _audioFile != null
                                ? (_trackDuration - 15)
                                    .clamp(0.0, double.infinity)
                                : 0.0,
                            onChanged: _audioFile != null
                                ? (val) {
                                    setState(() {
                                      _previewStartSeconds = val;
                                      _previewStartController.text =
                                          val.toInt().toString();
                                    });
                                  }
                                : null,
                          ),
                        ),
                        if (_audioFile == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text('Seleziona l\'audio prima',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.redAccent)),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Bottone Upload
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NuraBrand.pink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Carica Traccia',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: NuraBrand.pink),
                      const SizedBox(height: 24),
                      Text(
                        _uploadStatus,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
