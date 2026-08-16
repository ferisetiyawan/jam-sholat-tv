/// An announcement image shown during the home-screen event mode.
///
/// [url] may point to a bundled asset (`assets/...`), a local downloaded file
/// path, or a remote `http(s)` URL. [type] is the media type (`IMAGE` or
/// `SVG`), normalized to uppercase.
class EventImage {
  final String type;
  final String url;

  const EventImage({required this.type, required this.url});

  factory EventImage.fromJson(Map<String, dynamic> json) {
    return EventImage(
      type: json['type']?.toString().toUpperCase() ?? 'IMAGE',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'url': url};
}
