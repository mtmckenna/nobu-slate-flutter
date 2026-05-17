import 'package:flutter/material.dart';

class EditScreen extends StatefulWidget {
  final String field;
  final String initialValue;
  final ValueChanged<String> onDone;

  const EditScreen({
    super.key,
    required this.field,
    required this.initialValue,
    required this.onDone,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            autofocus: true,
            cursorColor: const Color(0xFFFFFFFF),
            textInputAction: TextInputAction.done,
            onSubmitted: (text) => widget.onDone(text.trim()),
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontFamily: 'Helvetica Neue',
              fontSize: 50,
            ),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ),
    );
  }
}
