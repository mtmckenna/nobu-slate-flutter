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
}
