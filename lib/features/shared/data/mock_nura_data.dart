import 'package:flutter/material.dart';

import '../../../core/models/genre.dart';
import '../../../core/models/track.dart';
import '../../../core/models/trending.dart';
import '../domain/artist.dart';
import '../domain/label.dart';
import '../domain/normal_user.dart';
import '../domain/pitch_request.dart';

const List<Track> kTracks = [
  Track(
    't1',
    'Mira Solene',
    'Velvet Static',
    'dream pop',
    92,
    332,
    Color(0xFFFF0A75),
    '2:48',
    audioAsset: 'assets/audio/preview_audio_1.mp3',
    coverAsset: 'assets/images/artists/aiony-haust-3TLl_97HNJo-unsplash.jpg',
  ),
  Track(
    't2',
    'Kaspar Vogel',
    'Notturno 03',
    'neo-classical',
    64,
    188,
    Color(0xFFACE7D5),
    '3:31',
    audioAsset: 'assets/audio/preview_audio_2.mp3',
    coverAsset: 'assets/images/artists/christopher-campbell-rDEOVtE7vOs-unsplash.jpg',
  ),
  Track(
    't3',
    'Ronin Avila',
    'Sub Fathom',
    'deep house',
    124,
    260,
    Color(0xFF7C5BFF),
    '5:12',
    audioAsset: 'assets/audio/preview_audio_3.mp3',
    coverAsset: 'assets/images/artists/elevate-nYgy58eb9aw-unsplash.jpg',
  ),
  Track(
    't4',
    'Iva Krause',
    'Tempera',
    'art folk',
    76,
    28,
    Color(0xFFFF8A3D),
    '3:04',
    audioAsset: 'assets/audio/preview_audio_4.mp3',
    coverAsset: 'assets/images/artists/ian-dooley-d1UPkiFd04A-unsplash.jpg',
  ),
  Track(
    't5',
    'Polara',
    'Soft Machine',
    'electro-pop',
    108,
    332,
    Color(0xFFFF0A75),
    '3:22',
    audioAsset: 'assets/audio/preview_audio_5.mp3',
    coverAsset: 'assets/images/artists/jacek-dylag-PMxT0XtQ--A-unsplash.jpg',
  ),
  Track(
    't6',
    'Nube Pequena',
    'Madrugada',
    'latin alt',
    88,
    12,
    Color(0xFFFF5A5F),
    '2:55',
    audioAsset: 'assets/audio/preview_audio_6.mp3',
    coverAsset: 'assets/images/artists/joseph-gonzalez-iFgRcqHznqg-unsplash.jpg',
  ),
  Track(
    't7',
    'Theo Halberg',
    'Iron Lung',
    'post-rock',
    112,
    200,
    Color(0xFF54B6CC),
    '4:48',
    audioAsset: 'assets/audio/preview_audio_7.mp3',
    coverAsset: 'assets/images/artists/jurica-koletic-7YVZYZeITc8-unsplash.jpg',
  ),
];

const List<Genre> kGenres = [
  Genre('g1', 'Dream Pop', 1284, 332),
  Genre('g2', 'Neo-Classical', 412, 188),
  Genre('g3', 'Deep House', 2104, 260),
  Genre('g4', 'Art Folk', 286, 28),
  Genre('g5', 'Latin Alt', 822, 12),
  Genre('g6', 'Post-Rock', 514, 200),
  Genre('g7', 'Electro-Pop', 1670, 332),
  Genre('g8', 'Ambient', 942, 168),
];

const List<Trending> kTrending = [
  Trending(1, 'Polara', 'Soft Machine', '+18', Color(0xFFFF0A75)),
  Trending(2, 'Mira Solene', 'Velvet Static', '+12', Color(0xFFFF0A75)),
  Trending(3, 'Ronin Avila', 'Sub Fathom', '+7', Color(0xFF7C5BFF)),
  Trending(4, 'Iva Krause', 'Tempera', '+4', Color(0xFFFF8A3D)),
  Trending(5, 'Theo Halberg', 'Iron Lung', '−1', Color(0xFF54B6CC)),
];

const List<Artist> kArtists = [
  Artist(
    id: 'a1',
    stageName: 'Mira Solene',
    genre: 'Dream Pop',
    bio: 'Voce eterea e synth analogici tra dream-pop e art-wave.',
    imageAsset: 'assets/images/artists/aiony-haust-3TLl_97HNJo-unsplash.jpg',
  ),
  Artist(
    id: 'a2',
    stageName: 'Kaspar Vogel',
    genre: 'Neo-Classical',
    bio: 'Pianoforte contemporaneo e texture cinematiche minimali.',
    imageAsset: 'assets/images/artists/christopher-campbell-rDEOVtE7vOs-unsplash.jpg',
  ),
  Artist(
    id: 'a3',
    stageName: 'Ronin Avila',
    genre: 'Deep House',
    bio: 'Groove notturni, bassline profonde e percussioni secche.',
    imageAsset: 'assets/images/artists/elevate-nYgy58eb9aw-unsplash.jpg',
  ),
  Artist(
    id: 'a4',
    stageName: 'Iva Krause',
    genre: 'Art Folk',
    bio: 'Songwriting intimo, corde acustiche e armonie stratificate.',
    imageAsset: 'assets/images/artists/ian-dooley-d1UPkiFd04A-unsplash.jpg',
  ),
  Artist(
    id: 'a5',
    stageName: 'Polara',
    genre: 'Electro-Pop',
    bio: 'Hook pop e produzione elettronica ad alto contrasto.',
    imageAsset: 'assets/images/artists/jacek-dylag-PMxT0XtQ--A-unsplash.jpg',
  ),
];

const List<NormalUser> kNormalUsers = [
  NormalUser(
    id: 'u1',
    username: 'elenam',
    fullName: 'Elena Marchetti',
    avatarAsset: 'assets/images/artists/michael-dam-mEZ3PoFGs_k-unsplash.jpg',
    likedTrackIds: ['t1', 't3', 't5', 't7'],
  ),
  NormalUser(
    id: 'u2',
    username: 'lucavibes',
    fullName: 'Luca Ferri',
    avatarAsset: 'assets/images/artists/rayul-_M6gy9oHgII-unsplash.jpg',
    likedTrackIds: ['t2', 't4', 't6'],
  ),
];

const List<Label> kLabels = [
  Label(
    id: 'l1',
    name: 'Aurora Records',
    city: 'Milano, IT',
    bio: 'Boutique label focalizzata su pop alternativo e new wave.',
    logoAsset: 'assets/images/labels/annie-spratt-0ZPSX_mQ3xI-unsplash.jpg',
  ),
  Label(
    id: 'l2',
    name: 'North District',
    city: 'Berlin, DE',
    bio: 'Curation elettronica, deep house e progetti cross-club.',
    logoAsset: 'assets/images/labels/jason-leung-wmyE5IBiOmo-unsplash.jpg',
  ),
  Label(
    id: 'l3',
    name: 'Capitol Side',
    city: 'London, UK',
    bio: 'A&R orientato a voci emergenti e sviluppo artistico.',
    logoAsset: 'assets/images/labels/joel-filipe-QwoNAhbmLLo-unsplash.jpg',
  ),
];

const List<PitchRequest> kPitchRequests = [
  PitchRequest(
    id: 'p1',
    artistId: 'a1',
    labelId: 'l1',
    trackId: 't1',
    visualStatus: PitchVisualStatus.sent,
  ),
  PitchRequest(
    id: 'p2',
    artistId: 'a3',
    labelId: 'l2',
    trackId: 't3',
    visualStatus: PitchVisualStatus.viewed,
  ),
  PitchRequest(
    id: 'p3',
    artistId: 'a5',
    labelId: 'l3',
    trackId: 't5',
    visualStatus: PitchVisualStatus.shortlisted,
  ),
  PitchRequest(
    id: 'p4',
    artistId: 'a4',
    labelId: 'l1',
    trackId: 't4',
    visualStatus: PitchVisualStatus.rejected,
  ),
];


Track? getTrackById(String id) {
  for (final track in kTracks) {
    if (track.id == id) return track;
  }
  return null;
}

Artist? getArtistById(String id) {
  for (final artist in kArtists) {
    if (artist.id == id) return artist;
  }
  return null;
}

Label? getLabelById(String id) {
  for (final label in kLabels) {
    if (label.id == id) return label;
  }
  return null;
}

List<PitchRequest> getPitchesForLabel(String labelId) {
  return kPitchRequests.where((pitch) => pitch.labelId == labelId).toList();
}

List<PitchRequest> getPitchesForArtist(String artistId) {
  return kPitchRequests.where((pitch) => pitch.artistId == artistId).toList();
}
