/// Comprehensive metadata information for audio files
class AudioMetadata {
  /// Title of the audio track
  final String? title;

  /// Artist name
  final String? artist;

  /// Album name
  final String? album;

  /// Album artist
  final String? albumArtist;

  /// Genre
  final String? genre;

  /// Year/date of release
  final String? year;

  /// Track number
  final int? trackNumber;

  /// Total tracks in album
  final int? totalTracks;

  /// Disc number
  final int? discNumber;

  /// Total discs
  final int? totalDiscs;

  /// Duration in milliseconds
  final int? durationMs;

  /// Bitrate in kbps
  final int? bitrate;

  /// Sample rate in Hz
  final int? sampleRate;

  /// Number of channels
  final int? channels;

  /// Audio format/codec
  final String? format;

  /// File size in bytes
  final int? fileSizeBytes;

  /// Composer
  final String? composer;

  /// Comment/description
  final String? comment;

  /// Copyright information
  final String? copyright;

  /// Encoder information
  final String? encoder;

  /// Original artist
  final String? originalArtist;

  /// Original album
  final String? originalAlbum;

  /// Original year
  final String? originalYear;

  /// BPM (beats per minute)
  final int? bpm;

  /// Key signature
  final String? key;

  /// Mood
  final String? mood;

  /// Language
  final String? language;

  /// Publisher/label
  final String? publisher;

  /// ISRC (International Standard Recording Code)
  final String? isrc;

  /// UPC/EAN barcode
  final String? barcode;

  /// Catalog number
  final String? catalogNumber;

  /// Recording date
  final DateTime? recordingDate;

  /// Release date
  final DateTime? releaseDate;

  /// Cover art data (base64 encoded)
  final String? coverArtData;

  /// Cover art MIME type
  final String? coverArtMimeType;

  /// Additional custom metadata
  final Map<String, dynamic>? customMetadata;

  /// Creates audio metadata
  const AudioMetadata({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.totalTracks,
    this.discNumber,
    this.totalDiscs,
    this.durationMs,
    this.bitrate,
    this.sampleRate,
    this.channels,
    this.format,
    this.fileSizeBytes,
    this.composer,
    this.comment,
    this.copyright,
    this.encoder,
    this.originalArtist,
    this.originalAlbum,
    this.originalYear,
    this.bpm,
    this.key,
    this.mood,
    this.language,
    this.publisher,
    this.isrc,
    this.barcode,
    this.catalogNumber,
    this.recordingDate,
    this.releaseDate,
    this.coverArtData,
    this.coverArtMimeType,
    this.customMetadata,
  });

  /// Creates metadata from a map (typically from platform channel)
  factory AudioMetadata.fromMap(Map<String, dynamic> map) {
    return AudioMetadata(
      title: map['title'] as String?,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      albumArtist: map['albumArtist'] as String?,
      genre: map['genre'] as String?,
      year: map['year'] as String?,
      trackNumber: map['trackNumber'] as int?,
      totalTracks: map['totalTracks'] as int?,
      discNumber: map['discNumber'] as int?,
      totalDiscs: map['totalDiscs'] as int?,
      durationMs: map['durationMs'] as int?,
      bitrate: map['bitrate'] as int?,
      sampleRate: map['sampleRate'] as int?,
      channels: map['channels'] as int?,
      format: map['format'] as String?,
      fileSizeBytes: map['fileSizeBytes'] as int?,
      composer: map['composer'] as String?,
      comment: map['comment'] as String?,
      copyright: map['copyright'] as String?,
      encoder: map['encoder'] as String?,
      originalArtist: map['originalArtist'] as String?,
      originalAlbum: map['originalAlbum'] as String?,
      originalYear: map['originalYear'] as String?,
      bpm: map['bpm'] as int?,
      key: map['key'] as String?,
      mood: map['mood'] as String?,
      language: map['language'] as String?,
      publisher: map['publisher'] as String?,
      isrc: map['isrc'] as String?,
      barcode: map['barcode'] as String?,
      catalogNumber: map['catalogNumber'] as String?,
      recordingDate:
          map['recordingDate'] != null
              ? DateTime.tryParse(map['recordingDate'] as String)
              : null,
      releaseDate:
          map['releaseDate'] != null
              ? DateTime.tryParse(map['releaseDate'] as String)
              : null,
      coverArtData: map['coverArtData'] as String?,
      coverArtMimeType: map['coverArtMimeType'] as String?,
      customMetadata: map['customMetadata'] as Map<String, dynamic>?,
    );
  }

  /// Converts metadata to a map for platform channel communication
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'albumArtist': albumArtist,
      'genre': genre,
      'year': year,
      'trackNumber': trackNumber,
      'totalTracks': totalTracks,
      'discNumber': discNumber,
      'totalDiscs': totalDiscs,
      'durationMs': durationMs,
      'bitrate': bitrate,
      'sampleRate': sampleRate,
      'channels': channels,
      'format': format,
      'fileSizeBytes': fileSizeBytes,
      'composer': composer,
      'comment': comment,
      'copyright': copyright,
      'encoder': encoder,
      'originalArtist': originalArtist,
      'originalAlbum': originalAlbum,
      'originalYear': originalYear,
      'bpm': bpm,
      'key': key,
      'mood': mood,
      'language': language,
      'publisher': publisher,
      'isrc': isrc,
      'barcode': barcode,
      'catalogNumber': catalogNumber,
      'recordingDate': recordingDate?.toIso8601String(),
      'releaseDate': releaseDate?.toIso8601String(),
      'coverArtData': coverArtData,
      'coverArtMimeType': coverArtMimeType,
      'customMetadata': customMetadata,
    };
  }

  /// Gets the duration in seconds
  double? get durationSeconds =>
      durationMs != null ? durationMs! / 1000.0 : null;

  /// Gets the file size in a human-readable format
  String? get fileSizeFormatted {
    if (fileSizeBytes == null) return null;

    final bytes = fileSizeBytes!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Gets a formatted duration string (MM:SS or HH:MM:SS)
  String? get durationFormatted {
    if (durationMs == null) return null;

    final totalSeconds = (durationMs! / 1000).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Gets channel configuration as a string
  String? get channelConfiguration {
    if (channels == null) return null;

    switch (channels!) {
      case 1:
        return 'Mono';
      case 2:
        return 'Stereo';
      case 3:
        return '2.1';
      case 4:
        return 'Quadraphonic';
      case 5:
        return '4.1';
      case 6:
        return '5.1';
      case 7:
        return '6.1';
      case 8:
        return '7.1';
      default:
        return '$channels channels';
    }
  }

  /// Checks if the metadata has cover art
  bool get hasCoverArt => coverArtData != null && coverArtData!.isNotEmpty;

  /// Creates a copy with updated values
  AudioMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    String? year,
    int? trackNumber,
    int? totalTracks,
    int? discNumber,
    int? totalDiscs,
    int? durationMs,
    int? bitrate,
    int? sampleRate,
    int? channels,
    String? format,
    int? fileSizeBytes,
    String? composer,
    String? comment,
    String? copyright,
    String? encoder,
    String? originalArtist,
    String? originalAlbum,
    String? originalYear,
    int? bpm,
    String? key,
    String? mood,
    String? language,
    String? publisher,
    String? isrc,
    String? barcode,
    String? catalogNumber,
    DateTime? recordingDate,
    DateTime? releaseDate,
    String? coverArtData,
    String? coverArtMimeType,
    Map<String, dynamic>? customMetadata,
  }) {
    return AudioMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      totalTracks: totalTracks ?? this.totalTracks,
      discNumber: discNumber ?? this.discNumber,
      totalDiscs: totalDiscs ?? this.totalDiscs,
      durationMs: durationMs ?? this.durationMs,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      format: format ?? this.format,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      composer: composer ?? this.composer,
      comment: comment ?? this.comment,
      copyright: copyright ?? this.copyright,
      encoder: encoder ?? this.encoder,
      originalArtist: originalArtist ?? this.originalArtist,
      originalAlbum: originalAlbum ?? this.originalAlbum,
      originalYear: originalYear ?? this.originalYear,
      bpm: bpm ?? this.bpm,
      key: key ?? this.key,
      mood: mood ?? this.mood,
      language: language ?? this.language,
      publisher: publisher ?? this.publisher,
      isrc: isrc ?? this.isrc,
      barcode: barcode ?? this.barcode,
      catalogNumber: catalogNumber ?? this.catalogNumber,
      recordingDate: recordingDate ?? this.recordingDate,
      releaseDate: releaseDate ?? this.releaseDate,
      coverArtData: coverArtData ?? this.coverArtData,
      coverArtMimeType: coverArtMimeType ?? this.coverArtMimeType,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  @override
  String toString() {
    return 'AudioMetadata(title: $title, artist: $artist, album: $album, '
        'duration: $durationFormatted, format: $format, '
        'sampleRate: $sampleRate, channels: $channelConfiguration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioMetadata &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.durationMs == durationMs &&
        other.bitrate == bitrate &&
        other.sampleRate == sampleRate &&
        other.channels == channels &&
        other.format == format;
  }

  @override
  int get hashCode {
    return Object.hash(
      title,
      artist,
      album,
      durationMs,
      bitrate,
      sampleRate,
      channels,
      format,
    );
  }
}
