class NormalUser {
  final String id;
  final String username;
  final String fullName;
  final String avatarAsset;
  final List<String> likedTrackIds;

  const NormalUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarAsset,
    required this.likedTrackIds,
  });
}
