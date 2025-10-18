import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sakank/core/widgets/text/general_text.dart';

class SeeMoreText extends StatefulWidget {
  final String text;
  final double? size;
  final Color? color;
  final FontWeight? fontWeight;
  final int maxLines;

  const SeeMoreText({
    super.key,
    required this.text,
    required this.maxLines,
    this.size,
    this.color,
    this.fontWeight,
  });

  @override
  State<SeeMoreText> createState() => _SeeMoreTextState();
}

class _SeeMoreTextState extends State<SeeMoreText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isRtl = context.locale.languageCode == 'ar';
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextSpan textSpan = TextSpan(text: widget.text);

        final TextPainter textPainter = TextPainter(
          text: textSpan,
          maxLines: 3,
          textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final bool isTextLong = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            GeneralText(
              text: widget.text,
              fontSize: widget.size ?? 14,
              fontWeight: widget.fontWeight ?? FontWeight.normal,
              color: widget.color ?? theme.secondaryHeaderColor,
              maxLines: _isExpanded ? null : widget.maxLines,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (isTextLong)
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: GeneralText(
                  text: (_isExpanded ? 'See Less' : 'See More').tr(),
                  color: theme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        );
      },
    );
  }
}
