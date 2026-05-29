class Label {
  final String id;
  final String name;
  final String city;
  final String bio;
  final String logoAsset;
  final String size;

  const Label({
    required this.id,
    required this.name,
    required this.city,
    required this.bio,
    required this.logoAsset,
    this.size = 'medium', // Default a medium, tag (small, medium, big)
  });
}
