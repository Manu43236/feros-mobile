class TutorialVideo {
  final int id;
  final String featureTitle;
  final String youtubeUrl;

  const TutorialVideo({required this.id, required this.featureTitle, required this.youtubeUrl});

  factory TutorialVideo.fromJson(Map<String, dynamic> j) => TutorialVideo(
        id: j['id'],
        featureTitle: j['featureTitle'],
        youtubeUrl: j['youtubeUrl'],
      );
}
