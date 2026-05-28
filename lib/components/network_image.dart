import 'package:cached_network_image/cached_network_image.dart';
import 'package:gif_view/gif_view.dart';
import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../utils/storage_util.dart';

Color _avatarColor(BuildContext context, String text) {
  final colors = Theme.of(context).brightness == Brightness.dark
      ? const [
          Color(0xFF374151),
          Color(0xFF4B5563),
          Color(0xFF475569),
          Color(0xFF3F3F46),
          Color(0xFF365314),
          Color(0xFF164E63),
        ]
      : const [
          Color(0xFFE0F2FE),
          Color(0xFFDCFCE7),
          Color(0xFFFEF3C7),
          Color(0xFFFCE7F3),
          Color(0xFFEDE9FE),
          Color(0xFFE5E7EB),
        ];
  final seed = text.runes.fold<int>(0, (value, rune) => value + rune);
  return colors[seed % colors.length];
}

Widget _avatarTextImage(
  String text, {
  double? width,
  double? height,
}) {
  return Builder(
    builder: (context) {
      final size = width ?? height ?? 40;
      final label =
          text.trim().isEmpty ? '?' : String.fromCharCode(text.runes.first);
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _avatarColor(context, text),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          style: TextStyle(
            fontSize: size * 0.48,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      );
    },
  );
}

Widget networkImage(
  String imageUrl, {
  BoxFit? fit,
  double? width,
  double? height,
  bool isAvatar = false,
  String? avatarText,
  ImageWidgetBuilder? imageBuilder,
  BorderRadiusGeometry? borderRadius =
      const BorderRadius.all(Radius.circular(12)),
}) {
  if (isAvatar && GStorage.hideUserAvatar) {
    return _avatarTextImage(avatarText ?? '', width: width, height: height);
  }

  Widget placeHolder(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
        borderRadius: borderRadius,
      ),
      child: Icon(
        isAvatar ? Icons.person : Icons.all_inclusive,
        color: Theme.of(context).colorScheme.outline,
        size: width != null && width < 35
            ? width - 5
            : width != null && width < 70
                ? width - 10
                : 45,
      ),
    );
  }

  return imageUrl.endsWith(Constants.SUFFIX_GIF)
      ? GifView.network(
          imageUrl,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, url, error) => placeHolder(context),
          fadeDuration: const Duration(milliseconds: 200),
          loop: false,
        )
      : CachedNetworkImage(
          fit: fit,
          width: width,
          height: height,
          imageUrl: imageUrl,
          imageBuilder: imageBuilder,
          placeholder: (context, url) => placeHolder(context),
          errorWidget: (context, url, error) => placeHolder(context),
          fadeOutDuration: const Duration(milliseconds: 200),
          fadeInDuration: const Duration(milliseconds: 200),
        );
}

Widget clipNetworkImage(
  String imageUrl, {
  BoxFit? fit,
  double? radius,
  double? width,
  double? height,
  bool isAvatar = false,
  String? avatarText,
  ImageWidgetBuilder? imageBuilder,
  BorderRadiusGeometry? clipBorderRadius,
}) {
  return ClipRRect(
    borderRadius:
        clipBorderRadius ?? BorderRadius.circular(isAvatar ? 50 : radius ?? 12),
    child: networkImage(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      isAvatar: isAvatar,
      avatarText: avatarText,
      imageBuilder: imageBuilder,
      borderRadius: null,
    ),
  );
}
