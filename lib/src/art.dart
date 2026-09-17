import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.small = false});
  final bool small;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: small ? 36 : 44,
        height: small ? 36 : 44,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          LucideIcons.zap,
          color: AppColors.mint,
          size: small ? 22 : 28,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        'GET IT\nNOW',
        textScaler: TextScaler.noScaling,
        style: headline(small ? 14 : 18)
            .copyWith(letterSpacing: -.7, height: .98),
      ),
    ],
  );
}

class GroceryArt extends StatelessWidget {
  const GroceryArt({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'A mint grocery bag filled with fresh produce, bread, and milk',
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: 1.05,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: GroceryPainter())),
              Positioned(
                left: constraints.maxWidth * .01,
                top: constraints.maxHeight * .23,
                child: Transform.rotate(
                  angle: -.12,
                  child: const _ArtTag(
                    icon: LucideIcons.leaf,
                    text: 'Fresh finds.',
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: constraints.maxHeight * .12,
                child: Transform.rotate(
                  angle: .10,
                  child: const _ArtTag(
                    icon: LucideIcons.zap,
                    text: 'Zero wait vibes.',
                    color: AppColors.mint,
                  ),
                ),
              ),
              Positioned(
                right: constraints.maxWidth * .03,
                top: constraints.maxHeight * .13,
                child: Transform.rotate(
                  angle: .13,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.forest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.sparkles,
                      color: AppColors.mint,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ArtTag extends StatelessWidget {
  const _ArtTag({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.ink.withValues(alpha: .07)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.forest),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class GroceryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 420, size.height / 400);
    final paint = Paint()..isAntiAlias = true;
    void oval(Rect r, Color c) => canvas.drawOval(
      r,
      paint
        ..color = c
        ..style = PaintingStyle.fill,
    );
    void path(Path p, Color c) => canvas.drawPath(
      p,
      paint
        ..color = c
        ..style = PaintingStyle.fill,
    );
    void line(Offset a, Offset b, Color c, double width) => canvas.drawLine(
      a,
      b,
      paint
        ..color = c
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    void rr(Rect r, double radius, Color c) => canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(radius)),
      paint
        ..color = c
        ..style = PaintingStyle.fill,
    );
    oval(const Rect.fromLTWH(49, 33, 324, 324), const Color(0xFFE4DFF5));
    canvas.drawCircle(
      const Offset(211, 194),
      150,
      paint
        ..color = Colors.white.withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    oval(
      const Rect.fromLTWH(96, 341, 231, 24),
      AppColors.ink.withValues(alpha: .07),
    );
    // Baguette, tilted behind the groceries.
    canvas.save();
    canvas.translate(260, 178);
    canvas.rotate(.34);
    rr(const Rect.fromLTWH(-22, -126, 48, 186), 24, const Color(0xFFD59951));
    rr(const Rect.fromLTWH(-17, -123, 35, 174), 20, const Color(0xFFF3C780));
    for (var i = 0; i < 4; i++) {
      line(
        Offset(-8, -98 + i * 29),
        Offset(12, -84 + i * 29),
        const Color(0xFFCB914A),
        5,
      );
    }
    canvas.restore();
    // Leafy greens and stems.
    line(
      const Offset(157, 201),
      const Offset(116, 83),
      const Color(0xFF527A35),
      12,
    );
    for (final leaf in [
      (96.0, 86.0, -.6),
      (127.0, 76.0, .2),
      (146.0, 103.0, .6),
      (105.0, 122.0, -.6),
    ]) {
      canvas.save();
      canvas.translate(leaf.$1, leaf.$2);
      canvas.rotate(leaf.$3);
      oval(const Rect.fromLTWH(-22, -37, 44, 75), const Color(0xFF407A49));
      line(
        const Offset(0, 20),
        const Offset(0, -22),
        const Color(0xFF88B46A),
        2,
      );
      canvas.restore();
    }
    // Milk carton.
    canvas.save();
    canvas.translate(205, 154);
    canvas.rotate(-.10);
    rr(const Rect.fromLTWH(-33, -26, 66, 109), 5, const Color(0xFFFFFEF7));
    path(
      Path()
        ..moveTo(-33, -26)
        ..lineTo(-18, -49)
        ..lineTo(21, -49)
        ..lineTo(33, -26)
        ..close(),
      AppColors.blue,
    );
    rr(const Rect.fromLTWH(-19, -53, 41, 8), 2, const Color(0xFF889CC3));
    rr(const Rect.fromLTWH(-33, 4, 66, 49), 0, AppColors.blue);
    final milk = TextPainter(
      text: TextSpan(
        text: 'MILK',
        style: headline(16).copyWith(letterSpacing: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    milk.paint(canvas, const Offset(-24, 17));
    canvas.restore();
    // Tomato and orange peeking out of the bag.
    oval(const Rect.fromLTWH(112, 163, 80, 70), const Color(0xFFE7745C));
    path(
      Path()
        ..moveTo(147, 176)
        ..lineTo(130, 165)
        ..lineTo(145, 167)
        ..lineTo(149, 154)
        ..lineTo(155, 167)
        ..lineTo(170, 163)
        ..lineTo(161, 174)
        ..close(),
      AppColors.forest,
    );
    oval(const Rect.fromLTWH(247, 172, 60, 63), const Color(0xFFE9B456));
    // Bag silhouette with a darker folded side.
    path(
      Path()
        ..moveTo(99, 211)
        ..quadraticBezierTo(99, 203, 111, 204)
        ..lineTo(311, 204)
        ..lineTo(292, 335)
        ..quadraticBezierTo(290, 350, 274, 350)
        ..lineTo(129, 350)
        ..quadraticBezierTo(113, 350, 112, 334)
        ..close(),
      const Color(0xFF9CD2AC),
    );
    path(
      Path()
        ..moveTo(287, 205)
        ..lineTo(311, 204)
        ..lineTo(292, 335)
        ..quadraticBezierTo(290, 350, 274, 350)
        ..lineTo(264, 350)
        ..close(),
      const Color(0xFF79B98D),
    );
    path(
      Path()
        ..moveTo(111, 218)
        ..lineTo(283, 218)
        ..lineTo(266, 350)
        ..lineTo(129, 350)
        ..quadraticBezierTo(116, 350, 114, 335)
        ..close(),
      AppColors.mint,
    );
    canvas.drawArc(
      const Rect.fromLTWH(151, 182, 81, 99),
      0,
      3.14,
      false,
      paint
        ..color = AppColors.forest
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    final logo = TextPainter(
      text: TextSpan(
        text: 'GET IT\nNOW.',
        style: headline(
          31,
          color: AppColors.forest,
        ).copyWith(height: .97, letterSpacing: -1.4),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    logo.paint(canvas, const Offset(145, 286));
    // Avocado in front; native vector artwork stays sharp on every display.
    canvas.save();
    canvas.translate(80, 301);
    canvas.rotate(-.38);
    path(
      Path()
        ..moveTo(0, -49)
        ..cubicTo(21, -49, 24, -24, 35, -5)
        ..cubicTo(60, 40, -48, 50, -37, 0)
        ..cubicTo(-32, -19, -20, -49, 0, -49)
        ..close(),
      AppColors.forest,
    );
    path(
      Path()
        ..moveTo(0, -40)
        ..cubicTo(15, -40, 18, -18, 28, -2)
        ..cubicTo(47, 32, -40, 40, -29, 0)
        ..cubicTo(-25, -17, -15, -40, 0, -40)
        ..close(),
      const Color(0xFFCCE08E),
    );
    oval(const Rect.fromLTWH(-19, -6, 39, 39), const Color(0xFF997047));
    oval(const Rect.fromLTWH(-13, -3, 22, 23), const Color(0xFFB58B5C));
    canvas.restore();
    // Small hand-drawn motion accents.
    line(const Offset(334, 265), const Offset(352, 258), AppColors.forest, 3);
    line(const Offset(334, 277), const Offset(347, 278), AppColors.forest, 3);
    line(const Offset(69, 183), const Offset(77, 173), AppColors.forest, 3);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GroceryPainter oldDelegate) => false;
}
