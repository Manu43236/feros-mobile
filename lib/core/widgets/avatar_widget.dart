import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/string_utils.dart' show FerosStringUtils;

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color? bgColor;
  final Color? borderColor;

  const AvatarWidget({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.bgColor,
    this.borderColor,
  });

  static const double _borderWidth = 2.5;
  static const double _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? AppColors.navy;
    final innerSize = borderColor != null ? size - (_borderWidth + _gap) * 2 : size;
    final fontSize = innerSize * 0.36;

    Widget avatar;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: innerSize,
          height: innerSize,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initials(bg, fontSize, innerSize),
          errorWidget: (_, __, ___) => _initials(bg, fontSize, innerSize),
        ),
      );
    } else {
      avatar = _initials(bg, fontSize, innerSize);
    }

    if (borderColor == null) return avatar;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor!, width: _borderWidth),
      ),
      padding: const EdgeInsets.all(_gap),
      child: avatar,
    );
  }

  Widget _initials(Color bg, double fontSize, double sz) {
    return Container(
      width: sz,
      height: sz,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        FerosStringUtils.initials(name),
        style: AppTextStyles.bodySemiBold.copyWith(
          color: Colors.white,
          fontSize: fontSize,
        ),
      ),
    );
  }
}
