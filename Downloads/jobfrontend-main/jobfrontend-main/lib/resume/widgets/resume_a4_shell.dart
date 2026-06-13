import 'package:flutter/material.dart';

import '../models/resume_sheet_constants.dart';

/// Fixed-size A4 “sheet” with print-like framing — preview column wraps this in [InteractiveViewer].
class ResumeA4Shell extends StatelessWidget {
  const ResumeA4Shell({
    super.key,
    required this.backgroundColor,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
  });

  final Color backgroundColor;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kResumeA4Width,
      height: kResumeA4Height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
