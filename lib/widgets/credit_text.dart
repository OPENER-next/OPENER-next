import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class CreditText extends StatefulWidget {
  final List<CreditTextPart> children;

  final InlineSpan? Function(BuildContext context, int i)? separatorBuilder;

  final TextAlign alignment;

  final EdgeInsets padding;

  static InlineSpan _defaultSeparatorBuilder (BuildContext context, int i) => const TextSpan(text: ', ');

  const CreditText({
    required this.children,
    this.separatorBuilder = _defaultSeparatorBuilder,
    this.alignment = TextAlign.center,
    this.padding = EdgeInsets.zero,
    Key? key
  }) : super(key: key);

  @override
  State<CreditText> createState() => _CreditTextState();
}


class _CreditTextState extends State<CreditText> {
  final List<TapGestureRecognizer?> _list = [];

  @override
  void initState() {
    super.initState();
    _setupGestureRecognizers();
  }


  @override
  void didUpdateWidget(covariant CreditText oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateGestureRecognizers();
  }


  void _updateGestureRecognizers() {
    _cleanupGestureRecognizers();
    _setupGestureRecognizers();
  }


  void _setupGestureRecognizers() {
    _list.addAll(
      widget.children.map(
        (creditTextLink) {
          return creditTextLink.url != null
          ? (TapGestureRecognizer()..onTap = () => openUrl(creditTextLink.url!))
          : null;
        }
      )
    );
  }


  void _cleanupGestureRecognizers() {
    for (var i = _list.length - 1; i >= 0; i--) {
      _list.removeAt(i)?.dispose();
    }
  }


  @override
  Widget build(BuildContext context) {
    final creditTextParts = _buildParts(context);

    return Padding(
      padding: widget.padding,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Stroked text as border.
          RichText(
            textAlign: widget.alignment,
            text: TextSpan(
              style: TextStyle(
                fontSize: 10,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 4
                  ..strokeJoin = StrokeJoin.round
                  ..color = Colors.white,
              ),
              children: creditTextParts
            ),
          ),
          // Solid text as fill.
          RichText(
            textAlign: widget.alignment,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black,
              ),
              children: creditTextParts
            ),
          ),
        ],
      )
    );
  }


  List<InlineSpan> _buildParts(BuildContext context) {
    final creditTextParts = <InlineSpan>[
      if (widget.children.isNotEmpty) _buildPart(0)
    ];
    for (var i = 1; i < widget.children.length; i++) {
      final separator = widget.separatorBuilder?.call(context, i);
      if (separator != null) {
        creditTextParts.add(separator);
      }
      creditTextParts.add(_buildPart(i));
    }
    return creditTextParts;
  }


  TextSpan _buildPart(int index) {
    return TextSpan(
      text: widget.children[index].text,
      recognizer: _list[index]
    );
  }


  /// Open the given credits URL in the default browser.

  void openUrl(String url) async {
    if (!await launch(url)) throw '$url kann nicht aufgerufen werden';
  }


  @override
  void dispose() {
    _cleanupGestureRecognizers();
    super.dispose();
  }
}


class CreditTextPart {
  final String text;
  final String? url;

  const CreditTextPart(this.text, {
    this.url,
  });
}
