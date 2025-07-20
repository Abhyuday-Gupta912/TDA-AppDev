import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final bool showBookmark;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onBookmark,
    this.showBookmark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            _buildEventImage(),

            // Event Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Status
                  _buildCategoryAndStatus(),

                  const SizedBox(height: 8),

                  // Event Title
                  _buildEventTitle(context),

                  const SizedBox(height: 8),

                  // Date and Time
                  _buildDateTime(context),

                  const SizedBox(height: 8),

                  // Location
                  _buildLocation(context),

                  const SizedBox(height: 12),

                  // Price and Attendees
                  _buildPriceAndAttendees(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    return Stack(
      children: [
        // Main Image
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.grey100,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: event.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.grey100,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.grey100,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: AppTheme.grey400,
                    ),
                  ),
                )
              : const Icon(
                  Icons.event,
                  size: 48,
                  color: AppTheme.grey400,
                ),
        ),

        // Bookmark Button
        if (showBookmark)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: onBookmark,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  event.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                  color: event.isBookmarked
                      ? AppTheme.primaryColor
                      : AppTheme.grey600,
                ),
              ),
            ),
          ),

        // Live Badge
        if (event.isLive)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryAndStatus() {
    return Row(
      children: [
        // Category
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getCategoryColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            event.category.toUpperCase(),
            style: TextStyle(
              color: _getCategoryColor(),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),

        const Spacer(),

        // Registration Status
        if (event.registrationStatus != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              event.registrationStatus!.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEventTitle(BuildContext context) {
    return Text(
      event.title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.grey900,
            height: 1.2,
          ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );
  }

  Widget _buildDateTime(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.access_time,
          size: 16,
          color: AppTheme.grey500,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            AppDateUtils.formatEventDateRange(event.startDate, event.endDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey600,
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLocation(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: AppTheme.grey500,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            event.location,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.grey600,
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceAndAttendees(BuildContext context) {
    return Row(
      children: [
        // Price
        Flexible(
          child: event.price > 0
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '₹${event.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'FREE',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
        ),

        const Spacer(),

        // Attendees Count
        Row(
          children: [
            const Icon(
              Icons.group_outlined,
              size: 16,
              color: AppTheme.grey500,
            ),
            const SizedBox(width: 4),
            Text(
              '${event.attendeesCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.grey600,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (event.category.toLowerCase()) {
      case 'workshop':
        return AppTheme.primaryColor;
      case 'competition':
        return AppTheme.warningColor;
      case 'social':
        return AppTheme.successColor;
      case 'conference':
        return const Color(0xFF8B5CF6); // Purple
      case 'seminar':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return AppTheme.grey500;
    }
  }

  Color _getStatusColor() {
    switch (event.registrationStatus?.toLowerCase()) {
      case 'open':
        return AppTheme.successColor;
      case 'closing soon':
        return AppTheme.warningColor;
      case 'closed':
        return AppTheme.errorColor;
      case 'full':
        return AppTheme.grey500;
      default:
        return AppTheme.grey500;
    }
  }
}
