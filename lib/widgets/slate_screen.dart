import 'package:flutter/material.dart';
import '../models/slate_colors.dart';
import '../models/slate_data.dart';
import 'audio_channels_box.dart';
import 'date_time_box.dart';
import 'double_box.dart';
import 'title_bar.dart';
import 'value_box.dart';

class SlateScreen extends StatelessWidget {
  final SlateData data;
  final SlateColors colors;

  const SlateScreen({
    super.key,
    required this.data,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.background,
      padding: const EdgeInsets.only(right: 5, bottom: 5),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitleBar(title: data.title, colors: colors),
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DoubleBox(children: [
                    ValueBox(label: 'Scene', value: data.scene, colors: colors),
                    ValueBox(label: 'Take', value: data.take, colors: colors),
                  ]),
                  DateTimeBox(colors: colors),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DoubleBox(children: [
                    ValueBox(
                      label: 'Audio File',
                      value: data.audioFile,
                      colors: colors,
                    ),
                  ]),
                  AudioChannelsBox(
                    left: data.audioChannelL,
                    right: data.audioChannelR,
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
