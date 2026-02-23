// ========================================
// RATING WIDGETS
// Reusable components untuk tampilan rating
// ========================================

import 'package:flutter/material.dart';

class RatingWidgets {
  // ========================================
  // 1️⃣ STAR RATING DISPLAY (bintang visual)
  // ========================================
  static Widget buildStarRating({
    required double rating,
    double size = 16,
    Color activeColor = Colors.amber,
    Color inactiveColor = Colors.grey,
    bool showLabel = true,
    int? totalReviews,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bintang 1-5
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData iconData;
          Color iconColor;

          if (rating >= starValue) {
            // Full star
            iconData = Icons.star;
            iconColor = activeColor;
          } else if (rating >= starValue - 0.5) {
            // Half star
            iconData = Icons.star_half;
            iconColor = activeColor;
          } else {
            // Empty star
            iconData = Icons.star_border;
            iconColor = inactiveColor;
          }

          return Icon(iconData, color: iconColor, size: size);
        }),

        // Label rating number
        if (showLabel) ...[
          SizedBox(width: size * 0.3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.875,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          // Total reviews
          if (totalReviews != null) ...[
            SizedBox(width: size * 0.2),
            Text(
              '($totalReviews)',
              style: TextStyle(
                fontSize: size * 0.75,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ========================================
  // 2️⃣ RATING BADGE (badge "Driver Baru")
  // ========================================
  static Widget buildRatingBadge({
    required bool isNewDriver,
    required int totalReviews,
  }) {
    if (!isNewDriver) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.new_releases, size: 12, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            'Driver Baru',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 3️⃣ RATING BREAKDOWN (bar chart rating)
  // ========================================
  static Widget buildRatingBreakdown({
    required Map<String, dynamic> breakdown,
    bool isDark = false,
  }) {
    final totalReviews = breakdown['total_reviews'] as int;
    
    if (totalReviews == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Belum ada ulasan',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildBreakdownRow(5, breakdown['star_5'], breakdown['percentage_5'], totalReviews, isDark),
        const SizedBox(height: 8),
        _buildBreakdownRow(4, breakdown['star_4'], breakdown['percentage_4'], totalReviews, isDark),
        const SizedBox(height: 8),
        _buildBreakdownRow(3, breakdown['star_3'], breakdown['percentage_3'], totalReviews, isDark),
        const SizedBox(height: 8),
        _buildBreakdownRow(2, breakdown['star_2'], breakdown['percentage_2'], totalReviews, isDark),
        const SizedBox(height: 8),
        _buildBreakdownRow(1, breakdown['star_1'], breakdown['percentage_1'], totalReviews, isDark),
      ],
    );
  }

  static Widget _buildBreakdownRow(
    int stars,
    int count,
    double percentage,
    int totalReviews,
    bool isDark,
  ) {
    final fillColor = _getStarColor(stars);
    
    return Row(
      children: [
        // Star label
        SizedBox(
          width: 60,
          child: Row(
            children: [
              Text(
                '$stars',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.star, size: 14, color: Colors.amber),
            ],
          ),
        ),

        // Progress bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalReviews > 0 ? percentage / 100 : 0,
              backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              minHeight: 8,
            ),
          ),
        ),

        // Count & percentage
        SizedBox(
          width: 70,
          child: Text(
            '$count (${percentage.toStringAsFixed(0)}%)',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  static Color _getStarColor(int stars) {
    switch (stars) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ========================================
  // 4️⃣ RATING SUMMARY CARD (untuk header)
  // ========================================
  static Widget buildRatingSummaryCard({
    required double averageRating,
    required int totalReviews,
    required bool isNewDriver,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Big rating number
          Text(
            averageRating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Stars
          buildStarRating(
            rating: averageRating,
            size: 20,
            showLabel: false,
          ),
          
          const SizedBox(height: 8),
          
          // Total reviews
          Text(
            totalReviews == 0 
                ? 'Belum ada ulasan'
                : '$totalReviews ulasan',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          
          // Badge driver baru
          if (isNewDriver && totalReviews > 0) ...[
            const SizedBox(height: 8),
            buildRatingBadge(
              isNewDriver: isNewDriver,
              totalReviews: totalReviews,
            ),
          ],
        ],
      ),
    );
  }

  // ========================================
  // 5️⃣ REVIEW CARD (untuk list review)
  // ========================================
  static Widget buildReviewCard({
    required Map<String, dynamic> review,
    bool isDark = false,
  }) {
    final rating = review['rating'] as int;
    final reviewText = review['review_text'] as String?;
    final customerName = review['customer_name'] as String? ?? 'Customer';
    final customerPhoto = review['customer_photo'] as String?;
    final createdAt = DateTime.parse(review['created_at']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (avatar + name + rating)
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundImage: customerPhoto != null
                    ? NetworkImage(customerPhoto)
                    : null,
                child: customerPhoto == null
                    ? Icon(Icons.person, size: 20, color: Colors.grey.shade600)
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Name & date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Rating stars
              buildStarRating(
                rating: rating.toDouble(),
                size: 14,
                showLabel: false,
              ),
            ],
          ),
          
          // Review text
          if (reviewText != null && reviewText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              reviewText,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey.shade300 : Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================================
  // 6️⃣ COMPACT RATING DISPLAY (untuk card kecil)
  // ========================================
  static Widget buildCompactRating({
    required int rating,
    String? reviewText,
    bool isDark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.amber.shade900.withOpacity(0.2)
            : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark 
              ? Colors.amber.shade700.withOpacity(0.5)
              : Colors.amber.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                'Rating Anda: $rating/5',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                ),
              ),
            ],
          ),
          
          if (reviewText != null && reviewText.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"$reviewText"',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ========================================
  // HELPER: Format date
  // ========================================
  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} menit lalu';
      }
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks minggu lalu';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months bulan lalu';
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/${month}/${date.year}';
    }
  }
}
