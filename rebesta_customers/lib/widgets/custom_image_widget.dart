import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_export.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    final value = trim();

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return ImageType.network;
    } else if (value.toLowerCase().endsWith('.svg')) {
      return ImageType.svg;
    } else if (value.startsWith('file://')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType {
  svg,
  png,
  network,
  file,
  unknown,
}

// ignore_for_file: must_be_immutable
class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/no-image.jpg',
    this.errorWidget,
    this.semanticLabel,
  });

  /// [imageUrl] is required parameter for showing image
  final String? imageUrl;

  final double? height;
  final double? width;
  final BoxFit? fit;

  final String placeHolder;

  final Color? color;

  final Alignment? alignment;

  final VoidCallback? onTap;

  final BorderRadius? radius;

  final EdgeInsetsGeometry? margin;

  final BoxBorder? border;

  /// Optional widget to show when the image fails to load.
  final Widget? errorWidget;

  /// Semantic label for accessibility
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return alignment != null
        ? Align(
            alignment: alignment!,
            child: _buildWidget(),
          )
        : _buildWidget();
  }

  Widget _buildWidget() {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: _buildCircleImage(),
      ),
    );
  }

  /// Build image with border radius
  Widget _buildCircleImage() {
    if (radius != null) {
      return ClipRRect(
        borderRadius: radius!,
        child: _buildImageWithBorder(),
      );
    }

    return _buildImageWithBorder();
  }

  /// Build image with border
  Widget _buildImageWithBorder() {
    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          border: border,
          borderRadius: radius,
        ),
        child: _buildImageView(),
      );
    }

    return _buildImageView();
  }

  Widget _buildImageView() {
    // ============================================================
    // EMPTY IMAGE
    // ============================================================

    if (imageUrl == null ||
        imageUrl!.trim().isEmpty) {
      return Image.asset(
        placeHolder,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        color: color,
        semanticLabel: semanticLabel,
      );
    }

    final url = imageUrl!.trim();

    // ============================================================
    // IMAGE TYPE
    // ============================================================

    switch (url.imageType) {
      // ==========================================================
      // SVG
      // ==========================================================

      case ImageType.svg:
        return SizedBox(
          height: height,
          width: width,
          child: SvgPicture.asset(
            url,
            height: height,
            width: width,
            fit: fit ?? BoxFit.contain,
            colorFilter: color != null
                ? ColorFilter.mode(
                    color!,
                    BlendMode.srcIn,
                  )
                : null,
            semanticsLabel: semanticLabel,
          ),
        );

      // ==========================================================
      // FILE
      // ==========================================================

      case ImageType.file:
        return Image.file(
          File(
            url.replaceFirst(
              'file://',
              '',
            ),
          ),
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
          semanticLabel: semanticLabel,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            debugPrint(
              '❌ FILE IMAGE FAILED: $url',
            );

            return errorWidget ??
                Image.asset(
                  placeHolder,
                  height: height,
                  width: width,
                  fit: fit ?? BoxFit.cover,
                  color: color,
                  semanticLabel: semanticLabel,
                );
          },
        );

      // ==========================================================
      // NETWORK
      // ==========================================================

      case ImageType.network:
        debugPrint(
          '🌐 IMAGE URL: $url',
        );

        return CachedNetworkImage(
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          imageUrl: url,
          color: color,

          placeholder: (
            context,
            url,
          ) {
            return SizedBox(
              height: 30,
              width: 30,
              child: LinearProgressIndicator(
                color: Colors.grey.shade200,
                backgroundColor:
                    Colors.grey.shade100,
              ),
            );
          },

          errorWidget: (
            context,
            url,
            error,
          ) {
            debugPrint(
              '❌ IMAGE FAILED',
            );

            debugPrint(
              'URL: $url',
            );

            debugPrint(
              'ERROR: $error',
            );

            return errorWidget ??
                Container(
                  height: height,
                  width: width,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                      size: 32,
                    ),
                  ),
                );
          },
        );

      // ==========================================================
      // PNG / JPG / LOCAL ASSET
      // ==========================================================

      case ImageType.png:
      default:
        return Image.asset(
          url,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
          semanticLabel: semanticLabel,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            debugPrint(
              '❌ ASSET IMAGE FAILED: $url',
            );

            return errorWidget ??
                Image.asset(
                  placeHolder,
                  height: height,
                  width: width,
                  fit: fit ?? BoxFit.cover,
                  color: color,
                  semanticLabel: semanticLabel,
                );
          },
        );
    }
  }
}