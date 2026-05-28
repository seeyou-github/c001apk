import 'dart:math';

import 'package:c001apk_flutter/components/network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../components/nine_grid_view.dart';
import '../constants/constants.dart';
import '../utils/storage_util.dart';
import '../utils/utils.dart';

Widget image(
  double maxWidth,
  List<String> picArr, {
  bool isFeedArticle = false,
  String? articleImg,
}) {
  final limitedPicArr =
      GStorage.limitPostImages && !isFeedArticle && picArr.length > 3
          ? picArr.take(3).toList()
          : picArr;
  double imageWidth = (maxWidth - 2 * 5) / 3;
  double imageHeight = imageWidth;
  if (isFeedArticle || limitedPicArr.length == 1) {
    List<double> imageLp =
        Utils.getImageLp(isFeedArticle ? articleImg! : limitedPicArr[0]);
    double ratioWH = imageLp[0] / imageLp[1];
    double ratioHW = imageLp[1] / imageLp[0];
    double maxRatio = 22 / 9;
    imageWidth = isFeedArticle
        ? maxWidth
        : ratioWH > 1.5
            ? maxWidth
            : (ratioWH >= 1 || (imageLp[1] > imageLp[0] && ratioHW < 1.5))
                ? 2 * imageWidth
                : imageWidth;
    imageHeight = imageWidth * min(ratioHW, maxRatio);
  }
  return NineGridView(
    bigImageWidth: imageWidth,
    bigImageHeight: imageHeight,
    space: 5,
    height: isFeedArticle || limitedPicArr.length == 1 ? imageHeight : null,
    width: isFeedArticle || limitedPicArr.length == 1 ? imageWidth : maxWidth,
    itemCount: isFeedArticle ? 1 : picArr.length,
    itemBuilder: (context, index) => _PostImageTile(
      picArr: picArr,
      index: index,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      isFeedArticle: isFeedArticle,
      articleImg: articleImg,
      fit: isFeedArticle || limitedPicArr.length == 1
          ? BoxFit.fill
          : BoxFit.cover,
    ),
  );
}

class _PostImageTile extends StatefulWidget {
  const _PostImageTile({
    required this.picArr,
    required this.index,
    required this.imageWidth,
    required this.imageHeight,
    required this.isFeedArticle,
    required this.articleImg,
    required this.fit,
  });

  final List<String> picArr;
  final int index;
  final double imageWidth;
  final double imageHeight;
  final bool isFeedArticle;
  final String? articleImg;
  final BoxFit fit;

  @override
  State<_PostImageTile> createState() => _PostImageTileState();
}

class _PostImageTileState extends State<_PostImageTile> {
  bool _showImage = false;

  bool get _isLimitedHidden =>
      !widget.isFeedArticle &&
      GStorage.limitPostImages &&
      widget.picArr.length > 3 &&
      widget.index >= 3 &&
      !_showImage;

  String get _imageUrl =>
      widget.isFeedArticle ? widget.articleImg! : widget.picArr[widget.index];

  void _onTap() {
    if (_isLimitedHidden) {
      setState(() {
        _showImage = true;
      });
      return;
    }
    Map<dynamic, dynamic> arguments = {
      'imgList': widget.picArr,
      'initialPage': widget.isFeedArticle
          ? widget.picArr.indexOf(widget.articleImg!)
          : widget.picArr.indexOf(widget.picArr[widget.index]),
    };
    Get.toNamed('/imageview', arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              if (_isLimitedHidden)
                _showOnClickPlaceholder(
                  context,
                  widget.imageWidth,
                  widget.imageHeight,
                )
              else
                networkImage(
                  '$_imageUrl${Constants.SUFFIX_THUMBNAIL}',
                  width: widget.imageWidth,
                  height: widget.imageHeight,
                  fit: widget.fit,
                ),
              if (!_isLimitedHidden && _imageUrl.endsWith(Constants.SUFFIX_GIF))
                _badge(context, 'GIF'),
              if (!_isLimitedHidden &&
                  !_imageUrl.endsWith(Constants.SUFFIX_GIF) &&
                  _isLongImage(_imageUrl))
                _badge(context, '长图'),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isLongImage(String url) {
  List<double> imageLp = Utils.getImageLp(url);
  return imageLp[1] / imageLp[0] >= 22 / 9;
}

Widget _showOnClickPlaceholder(
  BuildContext context,
  double width,
  double height,
) {
  return Container(
    width: width,
    height: height,
    alignment: Alignment.center,
    color: Theme.of(context).colorScheme.onInverseSurface,
    child: Text(
      '点击显示',
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _badge(BuildContext context, String title) {
  return Container(
    margin: const EdgeInsets.all(5),
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4)),
    child: Text(
      title,
      style: TextStyle(
        height: 1,
        fontSize: 12,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      strutStyle: const StrutStyle(
        height: 1,
        leading: 0,
        fontSize: 12,
      ),
    ),
  );
}
