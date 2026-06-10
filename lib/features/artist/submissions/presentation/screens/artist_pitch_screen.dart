import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/models/track.dart';
import '../../../../../core/services/audio_preview_service.dart';
import '../../../../shared/data/mock_nura_data.dart';
import '../providers/pitch_providers.dart';

class ArtistPitchScreen extends ConsumerStatefulWidget {
  final bool isActive;
  final double safeTop;
  final double safeBottom;
  const ArtistPitchScreen({super.key, this.isActive = true, this.safeTop = 16.0, this.safeBottom = 16.0});

  @override
  ConsumerState<ArtistPitchScreen> createState() => _ArtistPitchScreenState();
}

class _ArtistPitchScreenState extends ConsumerState<ArtistPitchScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollNotifier = ValueNotifier<double>(0.0);
  int _activeTab = 0; // 0 = Nuovo Pitch, 1 = I Miei Pitch

  // Form State
  String? _selectedTrackId;
  String? _selectedLabelId;
  bool _isSubmitting = false;
  
  // Step 3 Message State
  final TextEditingController _messageController = TextEditingController();

  // Filters State
  final TextEditingController _searchController = TextEditingController();
  String _labelSearchQuery = '';
  String _selectedLabelSizeFilter = 'all'; // all, small, medium, big

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollNotifier.value = _scrollController.offset;
      // Ferma l'anteprima audio se l'utente scorre giù verso le etichette per evitare disturbi
      if (_scrollController.offset > 150 &&
          AudioPreviewService.instance.playingTrackId.value != null) {
        AudioPreviewService.instance.stop();
      }
    });
  }

  Timer? _lifecycleDebouncer;

  @override
  void didUpdateWidget(ArtistPitchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && !widget.isActive) {
      _lifecycleDebouncer?.cancel();
      _lifecycleDebouncer = Timer(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        AudioPreviewService.instance.stop();
        setState(() {
          _selectedTrackId = null;
          _selectedLabelId = null;
          _messageController.clear();
          _activeTab = 0;
          _labelSearchQuery = '';
          _searchController.clear();
          _selectedLabelSizeFilter = 'all';
        });
      });
    }
  }

  @override
  void dispose() {
    _lifecycleDebouncer?.cancel();
    _scrollController.dispose();
    _scrollNotifier.dispose();
    _messageController.dispose();
    _searchController.dispose();
    AudioPreviewService.instance.stop();
    super.dispose();
  }

  Future<void> _submitPitch(String artistId, String labelName) async {
    if (_selectedTrackId == null || _selectedLabelId == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final messageText = _messageController.text.trim();
      final service = ref.read(artistPitchServiceProvider);
      await service.sendPitch(
        artistId: artistId,
        labelId: _selectedLabelId!,
        trackId: _selectedTrackId!,
        message: messageText.isNotEmpty ? messageText : null,
      );

      // Trigger Haptic Vibe
      await HapticFeedback.mediumImpact();

      // Show immersive glass success modal
      if (mounted) {
        _showSuccessDialog(labelName);
      }

      // Reset selection
      setState(() {
        _selectedTrackId = null;
        _selectedLabelId = null;
        _messageController.clear();
      });

      // Invalidate the cache to reload history
      ref.invalidate(artistPitchesProvider(artistId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'invio del pitch: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(String labelName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim, secondAnim, child) {
        final scale = 0.85 + (anim.value * 0.15);
        final opacity = anim.value;

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: AlertDialog(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              elevation: 20,
              shadowColor: Colors.black12,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.black.withValues(alpha: 0.05), width: 1.5),
              ),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Spunta Animata
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [NuraBrand.pink, Color(0xFFFF529D)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: NuraBrand.pink.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'PITCH INVIATO!',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'La tua proposta è stata consegnata con successo ai curatori A&R di $labelName.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Perfetto',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final artistIdAsync = ref.watch(resolvedArtistIdProvider);

    return artistIdAsync.when(
      data: (artistId) {
        if (artistId == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            body: Center(
              child: Text(
                'Utente non connesso.',
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        return _buildMainContent(context, artistId);
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(color: NuraBrand.pink),
        ),
      ),
      error: (err, _) => const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: Text(
            'Errore nel caricamento dell\'utente.',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, String artistId) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // 1. HIGH-END PARALLAX ORGANIC MESH BACKGROUND (Coerente col Profilo Artista)
          Positioned.fill(
            child: ValueListenableBuilder<double>(
              valueListenable: _scrollNotifier,
              builder: (context, scrollOffset, _) {
                return RepaintBoundary(
                  child: CustomPaint(
                    painter: ParallaxOrganicMeshPainter(
                      scrollOffset: scrollOffset,
                      musicuraBlu: NuraBrand.deep,
                      nuraPink: NuraBrand.pink,
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. MAIN SCROLLABLE CONTENT
          Positioned.fill(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Top Header Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, widget.safeTop + 56.0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Proponi i tuoi brani direttamente alle etichette discografiche di Nura.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Segmented Control (Tabs)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _tabButton(
                                  label: 'Nuovo Pitch',
                                  isActive: _activeTab == 0,
                                  onTap: () => setState(() => _activeTab = 0),
                                ),
                              ),
                              Expanded(
                                child: _tabButton(
                                  label: 'I Miei Pitch',
                                  isActive: _activeTab == 1,
                                  onTap: () => setState(() => _activeTab = 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dynamic Body based on Active Tab
                if (_activeTab == 0) ...[
                  // Tab 0: Nuovo Pitch Form Flow
                  _buildFormFlow(artistId),
                ] else ...[
                  // Tab 1: Pitches sent History Feed
                  _buildHistoryFeed(artistId),
                ],

                // Bottom Padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF1A1A1A) : Colors.black45,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFormFlow(String artistId) {
    final tracksAsync = ref.watch(artistTracksProvider(artistId));
    final labelsAsync = ref.watch(availableLabelsProvider);

    return SliverList(
      delegate: SliverChildListDelegate([
        // STEP 1: SELEZIONE BRANO
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 8),
              const Text(
                'SELEZIONA IL TUO BRANO',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Horizontally Scrollable Tracks List
        tracksAsync.when(
          data: (tracks) {
            if (tracks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.music_off_outlined, color: Colors.black26, size: 44),
                      const SizedBox(height: 12),
                      const Text(
                        'Nessun brano caricato',
                        style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Carica prima una traccia demo all\'interno del tuo profilo per poterla candidare.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),

                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isSelected = _selectedTrackId == track.id;

                  return VinylTrackCard(
                    track: track,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      final isSelectedNow = !isSelected;
                      setState(() {
                        _selectedTrackId = isSelectedNow ? track.id : null;
                      });
                      if (isSelectedNow) {
                        AudioPreviewService.instance.togglePreview(
                          trackId: track.id,
                          assetPath: track.audioAsset,
                        );
                      } else {
                        AudioPreviewService.instance.stop();
                      }
                    },
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 170,
            child: Center(child: CircularProgressIndicator(color: NuraBrand.pink)),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Errore nel caricamento delle tracce: $err', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),

        const SizedBox(height: 36),

        // STEP 2: SELEZIONE LABEL
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 8),
              const Text(
                'SELEZIONA L\'ETICHETTA DISCOGRAFICA',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // SEARCH AND FILTERS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Search Input
              Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Center(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _labelSearchQuery = value.toLowerCase()),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
                    decoration: const InputDecoration(
                      hintText: 'Cerca etichetta...',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w500),
                      icon: Icon(Icons.search, color: Colors.black38, size: 20),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Size Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                child: Row(
                  children: [
                    _buildSizeFilterChip('all', 'Tutte'),
                    const SizedBox(width: 8),
                    _buildSizeFilterChip('small', 'Small'),
                    const SizedBox(width: 8),
                    _buildSizeFilterChip('medium', 'Medium'),
                    const SizedBox(width: 8),
                    _buildSizeFilterChip('big', 'Big'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Vertical Record Labels Frosted List
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: labelsAsync.when(
            data: (labels) {
              final filteredLabels = labels.where((l) {
                final matchesSearch = l.name.toLowerCase().contains(_labelSearchQuery);
                final matchesSize = _selectedLabelSizeFilter == 'all' || l.size == _selectedLabelSizeFilter;
                return matchesSearch && matchesSize;
              }).toList();

              if (filteredLabels.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Text('Nessuna etichetta trovata.', style: TextStyle(color: Colors.black38)),
                );
              }

              return Column(
                children: filteredLabels.map((label) {
                  final isSelected = _selectedLabelId == label.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedLabelId = isSelected ? null : label.id;
                      });
                      // Ferma l'anteprima audio quando si sceglie un'etichetta
                      AudioPreviewService.instance.stop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: isSelected ? 0.95 : 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? NuraBrand.pink : Colors.black.withValues(alpha: 0.05),
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: NuraBrand.pink.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Frosted circular logo
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 56,
                              height: 56,
                              color: Colors.black.withValues(alpha: 0.05),
                              child: Image.asset(
                                label.logoAsset,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                cacheWidth: 200,
                                errorBuilder: (_, __, ___) => const Icon(Icons.domain, color: Colors.black26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Text Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              label.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF1A1A1A),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: NuraBrand.pink.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: NuraBrand.pink.withValues(alpha: 0.3)),
                                            ),
                                            child: Text(
                                              label.size.toUpperCase(),
                                              style: const TextStyle(
                                                color: NuraBrand.pink,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        label.city.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.black45,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  label.bio,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Subtitle "Cerca Sonorità"
                                Row(
                                  children: [
                                    Icon(Icons.search_outlined, size: 12, color: Colors.black.withValues(alpha: 0.35)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'GENERI RICERCATI:',
                                      style: TextStyle(
                                        color: Colors.black.withValues(alpha: 0.35),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Curated genre tags wrap
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: _getSearchGenres(label.name, label.id).map((g) {
                                    final col = _getGenreColor(g);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: col.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: col.withValues(alpha: 0.25),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        g,
                                        style: TextStyle(
                                          color: col,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: NuraBrand.pink)),
            error: (err, _) => Text('Errore caricamento etichette: $err', style: const TextStyle(color: Colors.redAccent)),
          ),
        ),

        // STEP 3: PRESENTATION MESSAGE
        if (_selectedTrackId != null && _selectedLabelId != null) ...[
          const SizedBox(height: 36),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step 3 Header Title
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: NuraBrand.pink,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'SCRIVI LA TUA PRESENTAZIONE',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Text(
                    'Presenta il brano catturando l\'attenzione dei curatori A&R dell\'etichetta discografica.',
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Frosted glass text area
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 4,
                          maxLength: 300,
                          onChanged: (_) {
                            setState(() {});
                          },
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          buildCounter: (
                            BuildContext context, {
                            required int currentLength,
                            required bool isFocused,
                            required int? maxLength,
                          }) {
                            return const SizedBox.shrink(); // Hide default counter
                          },
                          decoration: InputDecoration(
                            hintText: 'Spiega perché questo brano è speciale, le tue ispirazioni, le influenze principali o i tuoi piani di lancio...',
                            hintStyle: TextStyle(
                              color: Colors.black.withValues(alpha: 0.35),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Dynamic neon character counter
                Padding(
                  padding: const EdgeInsets.only(left: 38, right: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${_messageController.text.length} / 300',
                        style: TextStyle(
                          color: _messageController.text.length >= 285
                              ? Colors.redAccent
                              : _messageController.text.isNotEmpty
                                  ? NuraBrand.pink
                                  : Colors.black38,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 36),

        // SUBMIT ACTION CTA BUTTON
        if (_selectedTrackId != null && _selectedLabelId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _isSubmitting ? 0.6 : 1.0,
              child: GestureDetector(
                onTap: () {
                  if (_isSubmitting) return;
                  HapticFeedback.heavyImpact();
                  final labels = labelsAsync.value ?? [];
                  final targetLabel = labels.firstWhere((l) => l.id == _selectedLabelId);
                  _submitPitch(artistId, targetLabel.name);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [NuraBrand.pink, Color(0xFFFF4893)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: NuraBrand.pink.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSubmitting) ...[
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Text(
                        'PROPONI IL BRANO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildHistoryFeed(String artistId) {
    final pitchesAsync = ref.watch(artistPitchesProvider(artistId));

    return pitchesAsync.when(
      data: (pitches) {
        if (pitches.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_outlined, color: Colors.black26, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nessun pitch inviato',
                      style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Non hai ancora proposto canzoni alle etichette. Vai alla scheda "Nuovo Pitch" per inviare la tua prima proposta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final pitch = pitches[index];
              final status = pitch['status'] as String? ?? 'sent';
              final createdAt = DateTime.tryParse(pitch['created_at'] as String? ?? '') ?? DateTime.now();

              final track = pitch['track'] as Map<String, dynamic>? ?? {};
              final label = pitch['label'] as Map<String, dynamic>? ?? {};

              final trackTitle = track['title'] as String? ?? 'Brano sconosciuto';
              final labelName = label['name'] as String? ?? 'Label';
              
              final profile = label['profiles'];
              final logoAsset = profile is Map<String, dynamic>
                  ? profile['image_asset'] as String?
                  : null;

              // Date Formatter
              final dateStr = '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showPitchDetailsBottomSheet(context, pitch);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                    children: [
                      // Label Logo
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.black.withValues(alpha: 0.05),
                          child: Image.asset(
                            logoAsset ?? 'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg',
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            cacheWidth: 200,
                            errorBuilder: (_, __, ___) => const Icon(Icons.domain, color: Colors.black26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Pitch Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trackTitle,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('proposto a ', style: TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w500)),
                                Text(
                                  labelName,
                                  style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dateStr,
                              style: const TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      // Status Badge
                      _statusBadge(status),
                    ],
                  ),
                ),
              ),
            );
          },
            childCount: pitches.length,
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator(color: NuraBrand.pink)),
      ),
      error: (err, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('Errore nel caricamento dello storico: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'viewed':
        bgColor = const Color(0xFFE8E7FD);
        textColor = const Color(0xFF6B4EFF);
        label = 'LETTO';
        break;
      case 'shortlisted':
        bgColor = const Color(0xFFE4F8F0);
        textColor = const Color(0xFF00B37A);
        label = 'SELEZIONATO';
        break;
      case 'rejected':
        bgColor = const Color(0xFFFDECE9);
        textColor = const Color(0xFFF05138);
        label = 'NON SEL.';
        break;
      case 'sent':
      default:
        bgColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF607D8B);
        label = 'INVIATO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
      'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
    ];
    return months[month - 1];
  }

  // ============================================================================
  // IMMERSIVE GLASS BOTTOM SHEET WITH A&R FEEDBACK & COMPACT PLAYER
  // ============================================================================
  void _showPitchDetailsBottomSheet(BuildContext context, Map<String, dynamic> pitch) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final trackData = pitch['track'] as Map<String, dynamic>? ?? {};
          final trackTitle = trackData['title'] as String? ?? '';
          final fullTrack = kTracks.firstWhere((t) => t.track == trackTitle, orElse: () => kTracks[0]);
          final labelData = pitch['label'] as Map<String, dynamic>? ?? {};
          final labelName = labelData['name'] as String? ?? 'Label';
          final status = pitch['status'] as String? ?? 'sent';
          final message = pitch['message'] as String?;
          final createdAt = DateTime.tryParse(pitch['created_at'] as String? ?? '') ?? DateTime.now();
          final dateStr = '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: Stack(
              children: [
                // 1. HIGH-END PARALLAX ORGANIC MESH BACKGROUND
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: ParallaxOrganicMeshPainter(
                        scrollOffset: 0,
                        musicuraBlu: NuraBrand.deep,
                        nuraPink: NuraBrand.pink,
                      ),
                    ),
                  ),
                ),
                
                // 2. CONTENT
                SafeArea(
                  child: Stack(
                    children: [
                      // Scrollable Content
                      Positioned.fill(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 80, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [

                    // Immersive track player card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Rounded cover image with visualizer overlay
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: fullTrack.coverAsset != null
                                      ? Image.asset(
                                          fullTrack.coverAsset!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                          cacheWidth: 200,
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                fullTrack.swatch,
                                                fullTrack.swatch.withValues(alpha: 0.5),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.music_note_outlined,
                                              color: Colors.white38,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              ValueListenableBuilder<String?>(
                                valueListenable: AudioPreviewService.instance.playingTrackId,
                                builder: (context, playingId, _) {
                                  final isPlaying = playingId == fullTrack.id;
                                  if (!isPlaying) return const SizedBox.shrink();
                                  return Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: const _MiniAudioVisualizer(color: NuraBrand.pink),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),

                          // Text details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullTrack.track,
                                  style: const TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fullTrack.artist.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  fullTrack.genre,
                                  style: TextStyle(
                                    color: fullTrack.swatch,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Floating Play / Pause Action
                          ValueListenableBuilder<String?>(
                            valueListenable: AudioPreviewService.instance.playingTrackId,
                            builder: (context, playingId, _) {
                              final isPlaying = playingId == fullTrack.id;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  AudioPreviewService.instance.togglePreview(
                                    trackId: fullTrack.id,
                                    assetPath: fullTrack.audioAsset,
                                  );
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPlaying
                                        ? Colors.black
                                        : NuraBrand.pink.withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: isPlaying
                                          ? Colors.black
                                          : NuraBrand.pink.withValues(alpha: 0.2),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: isPlaying ? Colors.white : NuraBrand.pink,
                                    size: 22,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 2. TIMELINE SECTION
                    const Text(
                      'STATO DELLA PROPOSTA',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTimelineStepper(status, dateStr),
                    const SizedBox(height: 28),

                    // 3. PITCH MESSAGE BOX
                    if (message != null && message.trim().isNotEmpty) ...[
                      const Text(
                        'IL TUO MESSAGGIO DI PRESENTAZIONE',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Text(
                          '"$message"',
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // 4. A&R FEEDBACK NOTE SECTION
                    const Text(
                      'RISPOSTA DELL\'A&R CURATORE',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildARFeedbackBox(status, labelName),
                  ],
                ),
              ),
            ),
                      // Floating Close Button
                      Positioned(
                        top: 16,
                        right: 24,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A), size: 28),
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineStepper(String status, String dateStr) {
    final isViewed = status == 'viewed' || status == 'shortlisted' || status == 'rejected';
    final isShortlisted = status == 'shortlisted';
    final isRejected = status == 'rejected';

    return Column(
      children: [
        // 1. INVIATO (SENT)
        _buildTimelineStep(
          label: 'Proposta Inviata',
          subtitle: 'Il tuo pitch è stato recapitato con successo.',
          time: dateStr,
          isActive: true,
          isCompleted: true,
          accentColor: NuraBrand.pink,
        ),
        _buildTimelineConnector(isActive: isViewed),

        // 2. LETTO (VIEWED)
        _buildTimelineStep(
          label: 'Ascoltato dall\'Etichetta',
          subtitle: isViewed
              ? 'L\'A&R ha ascoltato la preview del tuo brano.'
              : 'In attesa di primo ascolto da parte dei curatori.',
          time: isViewed ? 'Completo' : '',
          isActive: isViewed,
          isCompleted: isViewed,
          accentColor: const Color(0xFF7C5BFF),
        ),
        _buildTimelineConnector(isActive: isShortlisted || isRejected),

        // 3. DECISION (SHORTLISTED OR REJECTED OR SENT/VIEWED)
        _buildTimelineStep(
          label: isShortlisted
              ? 'Shortlisted'
              : isRejected
                  ? 'Valutazione Completata'
                  : 'Esito Valutazione',
          subtitle: isShortlisted
              ? 'CONGRATULAZIONI! Il brano è entrato nella shortlist ufficiale!'
              : isRejected
                  ? 'L\'etichetta ha completato l\'esame della proposta.'
                  : 'Il team A&R sta decidendo se selezionare la traccia.',
          time: isShortlisted ? 'Selezionato' : isRejected ? 'Non selezionato' : 'In esame',
          isActive: isShortlisted || isRejected,
          isCompleted: isShortlisted || isRejected,
          isFinal: true,
          accentColor: isShortlisted
              ? const Color(0xFF10AC84)
              : isRejected
                  ? Colors.redAccent
                  : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String label,
    required String subtitle,
    required String time,
    required bool isActive,
    required bool isCompleted,
    required Color accentColor,
    bool isFinal = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glowing dot
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? accentColor : Colors.white,
                border: Border.all(
                  color: isActive ? accentColor : Colors.black12,
                  width: 2.0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 10)
                  : null,
            ),
          ],
        ),
        const SizedBox(width: 16),

        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? const Color(0xFF1A1A1A) : Colors.black38,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: TextStyle(
                        color: isCompleted ? accentColor : Colors.black26,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: isActive ? Colors.black54 : Colors.black26,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineConnector({required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(left: 9),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 26,
            color: isActive ? NuraBrand.pink : Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildARFeedbackBox(String status, String labelName) {
    final isShortlisted = status == 'shortlisted';
    final isRejected = status == 'rejected';

    Color accentCol;
    String feedbackText;
    IconData icon;

    if (isShortlisted) {
      accentCol = const Color(0xFF10AC84);
      icon = Icons.stars_outlined;
      feedbackText =
          '"Ciao! Ci è piaciuto moltissimo il mood e il groove di questo brano, l\'atmosfera ti rapisce fin dai primi secondi. Vogliamo approfondire la tua visione artistica, ti contatteremo via email nei prossimi giorni per fissare una call conoscitiva!"\n\n— Team A&R, $labelName';
    } else if (isRejected) {
      accentCol = Colors.redAccent;
      icon = Icons.info_outline;
      feedbackText =
          '"Grazie mille per aver condiviso la tua musica con noi. La traccia è prodotta molto bene e le melodie sono forti, tuttavia per le nostre prossime release siamo orientati a sonorità diverse. Ti facciamo i nostri migliori auguri!"\n\n— Direzione Artistica, $labelName';
    } else {
      accentCol = const Color(0xFF7C5BFF);
      icon = Icons.hourglass_empty;
      feedbackText =
          '"Il tuo brano è attualmente all\'attenzione del nostro team A&R per la valutazione. Riceverai una notifica con l\'esito e le note di ascolto non appena avremo completato il review."\n\n— Segreteria A&R, $labelName';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentCol.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentCol.withValues(alpha: 0.25),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentCol, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feedbackText,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeFilterChip(String value, String label) {
    final isSelected = _selectedLabelSizeFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedLabelSizeFilter = value;
          // Se cambi filtro, deseleziona l'etichetta corrente se non corrisponde più ai criteri
          _selectedLabelId = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A1A1A) : Colors.black.withValues(alpha: 0.05),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black45,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ParallaxOrganicMeshPainter extends CustomPainter {
  final double scrollOffset;
  final Color musicuraBlu;
  final Color nuraPink;

  ParallaxOrganicMeshPainter({required this.scrollOffset, required this.musicuraBlu, required this.nuraPink});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    void drawReflection(Offset center, double radius, Color color, double opacity) {
      final glowPaint = Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 55, sigmaY: 55)..color = color.withValues(alpha: opacity);
      final parallaxCenter = Offset(center.dx, center.dy - (scrollOffset * 0.15));
      canvas.drawCircle(parallaxCenter, radius, glowPaint);
    }

    drawReflection(Offset(size.width * 0.15, size.height * 0.1), size.width * 0.5, musicuraBlu, 0.15);
    drawReflection(Offset(size.width * 0.9, size.height * 0.6), size.width * 0.4, musicuraBlu, 0.12);
    drawReflection(Offset(size.width * 0.4, size.height * 0.8), size.width * 0.35, musicuraBlu, 0.10);
    drawReflection(Offset(size.width * 0.85, size.height * 0.2), size.width * 0.25, nuraPink, 0.05);
    drawReflection(Offset(size.width * 0.05, size.height * 0.6), size.width * 0.3, nuraPink, 0.04);
  }

  @override
  bool shouldRepaint(covariant ParallaxOrganicMeshPainter oldDelegate) => oldDelegate.scrollOffset != scrollOffset;
}

// ============================================================================
// INTERACTIVE VINYL DECK SELECTOR CARD (OPZIONE B)
// ============================================================================
class VinylTrackCard extends StatefulWidget {
  final Track track;
  final bool isSelected;
  final VoidCallback onTap;

  const VinylTrackCard({
    super.key,
    required this.track,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<VinylTrackCard> createState() => _VinylTrackCardState();
}

class _VinylTrackCardState extends State<VinylTrackCard> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Listen to audio changes
    AudioPreviewService.instance.playingTrackId.addListener(_onAudioChanged);
    AudioPreviewService.instance.isPlaying.addListener(_onAudioChanged);
    
    _updateSpinState();
  }

  void _onAudioChanged() {
    if (mounted) {
      setState(() {
        _updateSpinState();
      });
    }
  }

  void _updateSpinState() {
    final playingId = AudioPreviewService.instance.playingTrackId.value;
    final isPlaying = AudioPreviewService.instance.isPlaying.value;
    final isCurrentPlaying = playingId == widget.track.id && isPlaying;
    
    debugPrint('[VinylTrackCard] track.id=${widget.track.id} | playingId=$playingId | isPlaying=$isPlaying | isSelected=${widget.isSelected} | isCurrentPlaying=$isCurrentPlaying');
    
    if (widget.isSelected && isCurrentPlaying) {
      if (!_spinController.isAnimating) {
        debugPrint('[VinylTrackCard] -> START SPINNING per ${widget.track.id}');
        _spinController.repeat();
      }
    } else {
      if (_spinController.isAnimating) {
        debugPrint('[VinylTrackCard] -> STOP SPINNING per ${widget.track.id}');
        _spinController.stop();
      }
    }
  }

  @override
  void didUpdateWidget(VinylTrackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSpinState();
  }

  @override
  void dispose() {
    AudioPreviewService.instance.playingTrackId.removeListener(_onAudioChanged);
    AudioPreviewService.instance.isPlaying.removeListener(_onAudioChanged);
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 155,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vinyl and Sleeve Stack
            SizedBox(
              height: 108,
              width: 155,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Vinyl Record (Slides out from behind cover)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 550),
                    curve: isSelected ? Curves.easeOutBack : Curves.easeOut,
                    left: isSelected ? 56 : 12,
                    top: 9,
                    child: AnimatedBuilder(
                      animation: _spinController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _spinController.value * 2 * 3.1415926535,
                          child: child,
                        );
                      },
                      child: _buildVinylRecord(track),
                    ),
                  ),

                  // 2. Sleeve Cover
                  Positioned(
                    left: 6,
                    top: 5,
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                                ? NuraBrand.pink.withValues(alpha: 0.25) 
                                : Colors.black.withValues(alpha: 0.12),
                            blurRadius: isSelected ? 16 : 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Album cover or gradient
                            track.coverAsset != null
                                ? Image.asset(
                                    track.coverAsset!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    cacheWidth: 300,
                                    errorBuilder: (_, __, ___) => _buildPlaceholderCover(track),
                                  )
                                : _buildPlaceholderCover(track),
                            
                            // Glassmorphic overlay border
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected 
                                      ? NuraBrand.pink.withValues(alpha: 0.45) 
                                      : Colors.white.withValues(alpha: 0.15),
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                              ),
                            ),

                            // Selected Check Icon Overlay
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: NuraBrand.pink,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Track Info
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.track,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                      shadows: isSelected ? [
                        Shadow(
                          color: NuraBrand.pink.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ] : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    track.genre.toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? NuraBrand.pink : Colors.black38,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVinylRecord(Track track) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Color(0xFF2C2C2C),
            Color(0xFF151515),
            Color(0xFF0F0F0F),
          ],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Groove concentric lines (simulate physical vinyl)
          _buildVinylGroove(size: 76),
          _buildVinylGroove(size: 62),
          _buildVinylGroove(size: 48),

          // Shiny physical glare overlay that rotates
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.03),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
              ),
            ),
          ),

          // Center Sticker
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Two-toned sticker gradient
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        track.swatch,
                        track.swatch.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                // Center hole
                Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVinylGroove({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
          width: 0.8,
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover(Track track) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [track.swatch, track.swatch.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_outlined,
          color: Colors.white38,
          size: 28,
        ),
      ),
    );
  }
}

// ============================================================================
// EDITORIAL GENRE HELPERS FOR RECORD LABELS
// ============================================================================
List<String> _getSearchGenres(String labelName, String labelId) {
  final name = labelName.toLowerCase();
  if (name.contains('aurora') || labelId == 'l1') {
    return ['Dream Pop', 'Art Folk', 'Indie'];
  } else if (name.contains('north') || labelId == 'l2') {
    return ['Deep House', 'Techno', 'Electro'];
  } else if (name.contains('capitol') || labelId == 'l3') {
    return ['Neo-Classical', 'Ambient', 'Songwriter'];
  }
  return ['Electronic', 'Alternative', 'Pop'];
}

Color _getGenreColor(String genre) {
  switch (genre.toLowerCase()) {
    case 'dream pop': return const Color(0xFFFF529D);
    case 'art folk': return const Color(0xFFFF8A3D);
    case 'indie': return const Color(0xFFE5A93B);
    case 'deep house': return const Color(0xFF7C5BFF);
    case 'techno': return const Color(0xFF00C9A7);
    case 'electro': return const Color(0xFF0089FF);
    case 'neo-classical': return const Color(0xFF33D9FF);
    case 'ambient': return const Color(0xFF1DD1A1);
    case 'singer-songwriter':
    case 'songwriter': return const Color(0xFF10AC84);
    default: return const Color(0xFF888888);
  }
}

// ============================================================================
// BOUNCING NEON SPECTRAL AUDIO VISUALIZER FOR PITCH PLAYERS
// ============================================================================
class _MiniAudioVisualizer extends StatefulWidget {
  final Color color;
  const _MiniAudioVisualizer({required this.color});

  @override
  State<_MiniAudioVisualizer> createState() => _MiniAudioVisualizerState();
}

class _MiniAudioVisualizerState extends State<_MiniAudioVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(3, (index) {
              final scale = index == 0
                  ? 0.3 + (_controller.value * 0.7)
                  : index == 1
                      ? 0.6 - (_controller.value * 0.4)
                      : 0.2 + (_controller.value * 0.8);
              return Container(
                width: 3.5,
                height: 18 * scale,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
