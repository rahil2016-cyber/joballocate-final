import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

class OtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onCompleted;
  final int length;

  const OtpInputField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = 6,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());

    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() {
        if (_controllers[i].text.length == 1 && i < widget.length - 1) {
          _focusNodes[i + 1].requestFocus();
        }

        String otp = _controllers.map((c) => c.text).join();
        widget.controller.text = otp;

        if (otp.length == widget.length) {
          widget.onCompleted(otp);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // Avoid horizontal overflow on narrow devices (padding + 6 boxes).
    final boxW = w < 360 ? 40.0 : 46.0;
    final gap = w < 360 ? 3.0 : 5.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Container(
          width: boxW,
          height: 52,
          margin: EdgeInsets.symmetric(horizontal: gap),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              filled: true,
              fillColor: _controllers[index].text.isNotEmpty
                  ? AppColors.primaryLight
                  : AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _controllers[index].text.isNotEmpty
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: _controllers[index].text.isNotEmpty
                      ? AppColors.primary
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}