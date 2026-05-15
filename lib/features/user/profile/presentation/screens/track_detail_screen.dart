import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../social/data/social_engagement_service.dart';

class TrackDetailScreen extends StatefulWidget {
  final String trackId;
  final String initialTitle;
  final String initialGenre;
  final int initialDurationSeconds;
  final String? initialCoverImageAsset;
  final String? ownerArtistId;
  final String? currentUserId;

  const TrackDetailScreen({
    super.key,
    required this.trackId,
    required this.initialTitle,
    required this.initialGenre,
    required this.initialDurationSeconds,
    required this.initialCoverImageAsset,
    required this.ownerArtistId,
    required this.currentUserId,
  });

  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends State<TrackDetailScreen> {
  final _social = const SocialEngagementService();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _genreCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _coverCtrl;

  bool _saving = false;
  bool _deleting = false;
  EngagementCounts _counts = const EngagementCounts();
  List<TrackComment> _comments = const [];

  bool get _canEditDelete =>
      widget.currentUserId != null && widget.currentUserId == widget.ownerArtistId;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _genreCtrl = TextEditingController(text: widget.initialGenre);
    _durationCtrl = TextEditingController(text: widget.initialDurationSeconds.toString());
    _coverCtrl = TextEditingController(text: widget.initialCoverImageAsset ?? '');
    _load();
  }

  Future<void> _load() async {
    final countsMap = await _social.fetchCountsForTrackIds([widget.trackId]);
    final comments = await _social.fetchComments(widget.trackId);
    if (!mounted) return;
    setState(() {
      _counts = countsMap[widget.trackId] ?? const EngagementCounts();
      _comments = comments;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _genreCtrl.dispose();
    _durationCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMetadata() async {
    final client = Supabase.instance.client;
    final duration = int.tryParse(_durationCtrl.text.trim()) ?? widget.initialDurationSeconds;

    setState(() => _saving = true);
    try {
      await client.from('tracks').update({
        'title': _titleCtrl.text.trim(),
        'genre': _genreCtrl.text.trim(),
        'duration_seconds': duration,
        'cover_image_asset': _coverCtrl.text.trim().isEmpty ? null : _coverCtrl.text.trim(),
      }).eq('id', widget.trackId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metadati aggiornati')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore salvataggio: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteTrack() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NuraBrand.deepMid,
        title: const Text('Rimuovere il brano?', style: TextStyle(color: NuraBrand.mint)),
        content: const Text(
          'Questa azione elimina il brano dal profilo.',
          style: TextStyle(color: NuraBrand.mint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Rimuovi')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await Supabase.instance.client.from('tracks').delete().eq('id', widget.trackId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore rimozione: $e')),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NuraBrand.deepest,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: NuraBrand.mint,
        title: const Text('Dettaglio brano'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _titleCtrl.text,
            style: const TextStyle(
              color: NuraBrand.mint,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Stat(label: 'Like', value: _counts.likes.toString()),
              const SizedBox(width: 8),
              _Stat(label: 'Salvati', value: _counts.saves.toString()),
              const SizedBox(width: 8),
              _Stat(label: 'Commenti', value: _counts.comments.toString()),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Commenti', style: TextStyle(color: NuraBrand.mint, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_comments.isEmpty)
            Text('Nessun commento', style: TextStyle(color: NuraBrand.mintAlpha(0.6)))
          else
            ..._comments.map(
              (c) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c.authorName ?? 'Utente', style: const TextStyle(color: NuraBrand.mint, fontSize: 12)),
                subtitle: Text(c.body, style: TextStyle(color: NuraBrand.mintAlpha(0.78), fontSize: 12)),
              ),
            ),
          const SizedBox(height: 16),
          if (_canEditDelete) ...[
            const Text('Modifica metadati', style: TextStyle(color: NuraBrand.mint, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            _Field(label: 'Titolo', controller: _titleCtrl),
            const SizedBox(height: 10),
            _Field(label: 'Genere', controller: _genreCtrl),
            const SizedBox(height: 10),
            _Field(label: 'Durata (sec)', controller: _durationCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            _Field(label: 'Copertina (asset path o URL)', controller: _coverCtrl),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _saving || _deleting ? null : _saveMetadata,
              child: Text(_saving ? 'Salvataggio...' : 'Salva modifiche'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving || _deleting ? null : _deleteTrack,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text(_deleting ? 'Rimozione...' : 'Rimuovi brano'),
            ),
          ] else
            Text(
              'Solo il proprietario del brano può modificare metadati/copertina o rimuoverlo.',
              style: TextStyle(color: NuraBrand.mintAlpha(0.62), fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _Field({required this.label, required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: NuraBrand.mint),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: NuraBrand.mintAlpha(0.7)),
        filled: true,
        fillColor: NuraBrand.deepMidAlpha(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: NuraBrand.mintAlpha(0.2)),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: NuraBrand.deepMidAlpha(0.55),
          border: Border.all(color: NuraBrand.mintAlpha(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: NuraBrand.mint, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: NuraBrand.mintAlpha(0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
