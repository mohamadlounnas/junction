import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import '../services/contacts_service.dart';
import '../services/property_service.dart';

/// Enhanced property recommendation card with intelligent data display
class EnhancedPropertyRecommendationCard extends StatelessWidget {
  final PropertyRecommendation recommendation;
  final VoidCallback? onTap;

  const EnhancedPropertyRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap ?? () {
          context.go('/dashboard/property/${recommendation.property['id']}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property image with overlay
            _buildImageSection(context),
            
            // Property details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and price
                  _buildTitleAndPrice(context),
                  
                  const SizedBox(height: 8),
                  
                  // Location and type
                  _buildLocationAndType(context),
                  
                  const SizedBox(height: 12),
                  
                  // AI Match indicators
                  _buildAIMatchIndicators(context),
                  
                  const SizedBox(height: 12),
                  
                  // Explanation
                  _buildExplanation(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    final imageUrl = recommendation.property['image_url'] ?? 
                    recommendation.property['images']?.firstOrNull;
    
    return Stack(
      children: [
        // Property image
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    imageUrl.startsWith('http') ? imageUrl : 'https://junction.feeef.org$imageUrl',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage(context);
                    },
                  ),
                )
              : _buildPlaceholderImage(context),
        ),
        
        // AI Match badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: recommendation.statusColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  '${recommendation.similarityPercentage}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Price badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              recommendation.propertyPrice,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        
        // Transaction type badge
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getTransactionTypeColor(recommendation.property['transactionType']).withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getTransactionTypeText(recommendation.property['transactionType']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Center(
        child: Icon(
          Iconsax.home,
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTitleAndPrice(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            recommendation.propertyTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            recommendation.propertyPrice,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationAndType(BuildContext context) {
    return Row(
      children: [
        Icon(
          Iconsax.location,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            recommendation.propertyLocation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            recommendation.propertyType,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onTertiaryContainer,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIMatchIndicators(BuildContext context) {
    return Column(
      children: [
        // Match status bar
        Row(
          children: [
            Icon(
              Icons.psychology,
              size: 16,
              color: recommendation.statusColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recommendation.matchStatus,
                style: TextStyle(
                  color: recommendation.statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '${recommendation.similarityPercentage}%',
              style: TextStyle(
                color: recommendation.statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Progress bar
        LinearProgressIndicator(
          value: recommendation.similarity,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(recommendation.statusColor),
          minHeight: 6,
        ),
        
        const SizedBox(height: 8),
        
        // Combined score indicator
        if (recommendation.combinedScore > 0)
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'نقاط إضافية: ${(recommendation.combinedScore * 100).round()}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildExplanation(BuildContext context) {
    if (recommendation.explanation.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: recommendation.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: recommendation.statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation.explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTransactionTypeColor(String? transactionType) {
    switch (transactionType?.toUpperCase()) {
      case 'SALE':
        return Colors.green;
      case 'RENT':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTransactionTypeText(String? transactionType) {
    switch (transactionType?.toUpperCase()) {
      case 'SALE':
        return 'للبيع';
      case 'RENT':
        return 'للإيجار';
      default:
        return 'غير محدد';
    }
  }
}

/// Enhanced contact recommendation card with intelligent data display
class EnhancedContactRecommendationCard extends StatelessWidget {
  final ContactRecommendation recommendation;
  final VoidCallback? onTap;

  const EnhancedContactRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap ?? () {
          context.go('/dashboard/contact/${recommendation.contact.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and match info
              _buildHeader(context),
              
              const SizedBox(height: 12),
              
              // Contact details
              _buildContactDetails(context),
              
              const SizedBox(height: 12),
              
              // AI Match indicators
              _buildAIMatchIndicators(context),
              
              const SizedBox(height: 12),
              
              // Explanation
              _buildExplanation(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            recommendation.contact.name.isNotEmpty 
                ? recommendation.contact.name[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Name and type
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recommendation.contact.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getContactTypeColor(recommendation.contact.type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getContactTypeText(recommendation.contact.type),
                  style: TextStyle(
                    color: _getContactTypeColor(recommendation.contact.type),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Match percentage badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: recommendation.statusColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${recommendation.similarityPercentage}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetails(BuildContext context) {
    return Column(
      children: [
        // Email
        Row(
          children: [
            Icon(
              Icons.email_outlined,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recommendation.contact.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 4),
        
        // Budget range
        if (recommendation.contact.budgetMin != null || recommendation.contact.budgetMax != null)
          Row(
            children: [
              Icon(
                Icons.attach_money,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getBudgetText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 4),
        
        // Location preferences
        if (recommendation.contact.locationWilayas.isNotEmpty)
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.contact.locationWilayas.take(2).join('، '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAIMatchIndicators(BuildContext context) {
    return Column(
      children: [
        // Match status bar
        Row(
          children: [
            Icon(
              Icons.psychology,
              size: 16,
              color: recommendation.statusColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recommendation.matchStatus,
                style: TextStyle(
                  color: recommendation.statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '${recommendation.similarityPercentage}%',
              style: TextStyle(
                color: recommendation.statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Progress bar
        LinearProgressIndicator(
          value: recommendation.similarity,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(recommendation.statusColor),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildExplanation(BuildContext context) {
    if (recommendation.explanation.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: recommendation.statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: recommendation.statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation.explanation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getBudgetText() {
    final min = recommendation.contact.budgetMin;
    final max = recommendation.contact.budgetMax;
    
    if (min != null && max != null) {
      return '${_formatPrice(min)} - ${_formatPrice(max)} دج';
    } else if (min != null) {
      return 'من ${_formatPrice(min)} دج';
    } else if (max != null) {
      return 'إلى ${_formatPrice(max)} دج';
    }
    return 'غير محدد';
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  Color _getContactTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'BUYER':
        return Colors.green;
      case 'TENANT':
        return Colors.blue;
      case 'INVESTOR':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getContactTypeText(String type) {
    switch (type.toUpperCase()) {
      case 'BUYER':
        return 'مشتري';
      case 'TENANT':
        return 'مستأجر';
      case 'INVESTOR':
        return 'مستثمر';
      default:
        return 'غير محدد';
    }
  }
} 