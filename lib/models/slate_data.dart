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

  String fieldValue(String field) {
    switch (field) {
      case 'title':
        return title;
      case 'scene':
        return scene;
      case 'take':
        return take;
      case 'audioFile':
        return audioFile;
      case 'audioChannelL':
        return audioChannelL;
      case 'audioChannelR':
        return audioChannelR;
      default:
        return '';
    }
  }

  SlateData withField(String field, String value) {
    switch (field) {
      case 'title':
        return copyWith(title: value);
      case 'scene':
        return copyWith(scene: value);
      case 'take':
        return copyWith(take: value);
      case 'audioFile':
        return copyWith(audioFile: value);
      case 'audioChannelL':
        return copyWith(audioChannelL: value);
      case 'audioChannelR':
        return copyWith(audioChannelR: value);
      default:
        return this;
    }
  }

  factory SlateData.fromJson(Map<String, dynamic> j) => SlateData(
        title: j['title'] as String? ?? defaults.title,
        scene: j['scene'] as String? ?? defaults.scene,
        take: j['take'] as String? ?? defaults.take,
        audioFile: j['audioFile'] as String? ?? defaults.audioFile,
        audioChannelL:
            j['audioChannelL'] as String? ?? defaults.audioChannelL,
        audioChannelR:
            j['audioChannelR'] as String? ?? defaults.audioChannelR,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'scene': scene,
        'take': take,
        'audioFile': audioFile,
        'audioChannelL': audioChannelL,
        'audioChannelR': audioChannelR,
      };
}
