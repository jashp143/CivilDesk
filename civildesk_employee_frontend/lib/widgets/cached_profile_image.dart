import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A reusable widget that displays a cached profile image
/// with a fallback to initials if no image is available.
/// 
/// Part of Phase 1 Optimization - Image Caching
class CachedProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackInitials;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CachedProfileImage({
    super.key,
    this.imageUrl,
    required this.fallbackInitials,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;
    final fgColor = foregroundColor ?? Colors.white;
    
    // If no image URL, show initials
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          fallbackInitials.isNotEmpty 
              ? fallbackInitials[0].toUpperCase() 
              : '?',
          style: TextStyle(
            color: fgColor,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Show cached network image
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          fallbackInitials.isNotEmpty 
              ? fallbackInitials[0].toUpperCase() 
              : '?',
          style: TextStyle(
            color: fgColor,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      memCacheWidth: (radius * 4).toInt(),
      memCacheHeight: (radius * 4).toInt(),
      maxWidthDiskCache: 500,
      maxHeightDiskCache: 500,
    );
  }
}

/// A larger profile image widget for detail screens
class CachedProfileImageLarge extends StatelessWidget {
  final String? imageUrl;
  final String fallbackInitials;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CachedProfileImageLarge({
    super.key,
    this.imageUrl,
    required this.fallbackInitials,
    this.radius = 50,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Theme.of(context).primaryColor;
    final fgColor = foregroundColor ?? Colors.white;
    
    // If no image URL, show initials
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          fallbackInitials.isNotEmpty 
              ? fallbackInitials[0].toUpperCase() 
              : '?',
          style: TextStyle(
            color: fgColor,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Show cached network image with higher quality
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: SizedBox(
          width: radius,
          height: radius,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
          ),
        ),
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          fallbackInitials.isNotEmpty 
              ? fallbackInitials[0].toUpperCase() 
              : '?',
          style: TextStyle(
            color: fgColor,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      memCacheWidth: (radius * 4).toInt(),
      memCacheHeight: (radius * 4).toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
  }
}

