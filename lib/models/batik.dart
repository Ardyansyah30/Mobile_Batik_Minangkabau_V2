class Batik {
  final int id;
  final String batikName;
  final String description;
  final String origin;
  final String imageUrl;
  final DateTime createdAt;

  Batik({
    required this.id,
    required this.batikName,
    required this.description,
    required this.origin,
    required this.imageUrl,
    required this.createdAt,
  });

  // Factory constructor untuk membuat objek Batik dari data JSON
  factory Batik.fromJson(Map<String, dynamic> json) {
    return Batik(
      id: json['id'],
      batikName: json['batik_name'],
      description: json['description'] ?? 'Tidak ada deskripsi.',
      origin: json['origin'] ?? 'Tidak diketahui',
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}