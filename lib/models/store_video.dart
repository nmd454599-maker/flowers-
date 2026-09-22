class StoreVideo {
  final String id, storeId, title, url, extension;
  final int durationMs;
  final String thumbnail;
  final DateTime createdAt;
  const StoreVideo(
      {required this.id,
      required this.storeId,
      required this.title,
      required this.url,
      required this.durationMs,
      required this.createdAt,
      this.extension = 'mp4',
      this.thumbnail = ''});
  Map<String, Object?> toMap() => {
        'storeId': storeId,
        'title': title,
        'url': url,
        'durationMs': durationMs,
        'createdAt': createdAt.toIso8601String(),
        'extension': extension,
        'active': true,
        'thumbnail': thumbnail,
      };
  factory StoreVideo.fromMap(String id, Map<String, dynamic> data) =>
      StoreVideo(
          id: id,
          storeId: data['storeId'] as String,
          title: data['title'] as String,
          url: data['url'] as String,
          durationMs: (data['durationMs'] as num).toInt(),
          extension: data['extension'] as String? ?? 'mp4',
          thumbnail: data['thumbnail'] as String? ?? '',
          createdAt: DateTime.parse(data['createdAt'] as String));
}
