import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FerosPinInput extends StatefulWidget {
  final void Function(String pin) onCompleted;
  final void Function(String pin)? onChanged;
  final String label;

  const FerosPinInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.label = 'Enter PIN',
  });

  @override
  State<FerosPinInput> createState() => _FerosPinInputState();
}

class _FerosPinInputState extends State<FerosPinInput> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes  = List.generate(4, (_) => FocusNode());
  final _pin = ['', '', '', ''];

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) value = value[value.length - 1];
    _pin[index] = value;
    final full = _pin.join();
    widget.onChanged?.call(full);

    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    if (full.length == 4) {
      _focusNodes[index].unfocus();
      widget.onCompleted(full);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _pin[index].isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _pin[index - 1] = '';
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.label),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(4, (i) => Padding(
            padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (e) => _onKeyEvent(i, e),
              child: SizedBox(
                width: 56,
                height: 56,
                child: TextField(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  obscureText: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTextStyles.heading3,
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.navy, width: 2),
                    ),
                  ),
                  onChanged: (v) => _onChanged(i, v),
                ),
              ),
            ),
          )),
        ),
      ],
    );
  }
}
