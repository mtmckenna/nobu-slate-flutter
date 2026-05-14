class SlateData {
  final String title;
  final String scene;
  final String take;
  final String audioFile;
  final String audioChannelL;
  final String audioChannelR;

  const SlateData({
    required this.title,
    required this.scene,
    required this.take,
    required this.audioFile,
    required this.audioChannelL,
    required this.audioChannelR,
  });

  static const defaults = SlateData(
    title: 'Title',
    scene: '1',
    take: '1',
    audioFile: '001',
    audioChannelL: 'Lav',
    audioChannelR: 'Boom',
  );

  SlateData copyWith({
    String? title,
    String? scene,
    String? take,
    String? audioFile,
    String? audioChannelL,
    String? audioChannelR,
  }) {
    return SlateData(
      title: title ?? this.title,
      scene: scene ?? this.scene,
      take: take ?? this.take,
      audioFile: audioFile ?? this.audioFile,
      audioChannelL: audioChannelL ?? this.audioChannelL,
      audioChannelR: audioChannelR ?? this.audioChannelR,
    );
  }
}
