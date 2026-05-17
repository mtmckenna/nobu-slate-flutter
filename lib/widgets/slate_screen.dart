import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import '../models/slate_data.dart';
import 'audio_channels_box.dart';
import 'box_with_swipe.dart';
import 'date_time_box.dart';
import 'double_box.dart';
import 'title_bar.dart';

class SlateScreen extends StatelessWidget {
  final SlateData data;
  final SlateColors colors;
  final void Function(SlateData) onUpdate;
  final void Function(String field) onEdit;
  final VoidCallback onMark;

  const SlateScreen({
    super.key,
    required this.data,
    required this.colors,
    required this.onUpdate,
    required this.onEdit,
    required this.onMark,
  });

  void _handleHorizontalDrag(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < 1) return;
    onMark();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: _handleHorizontalDrag,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: colors.background,
        padding: const EdgeInsets.only(right: 5, bottom: 5),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  key: const ValueKey('title'),
                  onTap: () => onEdit('title'),
                  behavior: HitTestBehavior.opaque,
                  child: TitleBar(title: data.title, colors: colors),
                ),
              ),
              Expanded(
                flex: 5,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DoubleBox(children: [
                      Expanded(
                        child: BoxWithSwipe(
                          key: const ValueKey('scene'),
                          label: 'Scene',
                          value: data.scene,
                          colors: colors,
                          onChange: (v) => onUpdate(data.copyWith(scene: v)),
                          onTap: () => onEdit('scene'),
                        ),
                      ),
                      Expanded(
                        child: BoxWithSwipe(
                          key: const ValueKey('take'),
                          label: 'Take',
                          value: data.take,
                          colors: colors,
                          onChange: (v) => onUpdate(data.copyWith(take: v)),
                          onTap: () => onEdit('take'),
                        ),
                      ),
                    ]),
                    Expanded(
                      child: DateTimeBox(colors: colors),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DoubleBox(children: [
                      Expanded(
                        child: BoxWithSwipe(
                          key: const ValueKey('audioFile'),
                          label: 'Audio File',
                          value: data.audioFile,
                          colors: colors,
                          onChange: (v) =>
                              onUpdate(data.copyWith(audioFile: v)),
                          onTap: () => onEdit('audioFile'),
                        ),
                      ),
                    ]),
                    Expanded(
                      child: AudioChannelsBox(
                        left: data.audioChannelL,
                        right: data.audioChannelR,
                        colors: colors,
                        onEditLeft: () => onEdit('audioChannelL'),
                        onEditRight: () => onEdit('audioChannelR'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
