class VideoModel {
  final String title;
  final String path;
  final DateTime dateAdded;
  final String? thumbnailPath;

  VideoModel({
    required this.title,
    required this.path,
    required this.dateAdded,
    this.thumbnailPath,
  });

  // Copy method for updating video with thumbnail
  VideoModel copyWith({String? thumbnailPath}) {
    return VideoModel(
      title: title,
      path: path,
      dateAdded: dateAdded,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      title: map['title'],
      path: map['path'],
      dateAdded: DateTime.parse(map['dateAdded']),
    );
  }
}
