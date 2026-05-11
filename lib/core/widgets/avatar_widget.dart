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

  const AvatarWidget({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = bgColor ?? AppColors.navy;
    final fontSize = size * 0.36;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initials(bg, fontSize),
          errorWidget: (_, __, ___) => _initials(bg, fontSize),
        ),
      );
    }

    return _initials(bg, fontSize);
  }

  Widget _initials(Color bg, double fontSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
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
