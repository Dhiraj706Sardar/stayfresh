import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/app_theme.dart';
import '../models/grocery_item.dart';
import '../services/local_database_service.dart';

/// Premium reminders screen showing items nearing expiry
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<GroceryItem> _expiringItems = [];
  List<GroceryItem> _expiredItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _expiringItems = LocalDatabaseService.getExpiringItems();
      _expiredItems = LocalDatabaseService.getExpiredItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppTheme.pureWhite,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadItems();
        },
        color: AppTheme.primaryGreen,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_expiringItems.isEmpty && _expiredItems.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              // Summary Card
              _buildSummaryCard(),
              
              const SizedBox(height: AppTheme.spacingL),
              
              // Expired Items
              if (_expiredItems.isNotEmpty) ...[
                _buildSectionHeader(
                  'Expired Items',
                  _expiredItems.length,
                  AppTheme.errorRed,
                  Icons.warning,
                ),
                const SizedBox(height: AppTheme.spacingM),
                ..._expiredItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: _buildReminderCard(item, isExpired: true),
                )),
                const SizedBox(height: AppTheme.spacingL),
              ],
              
              // Expiring Soon Items
              if (_expiringItems.isNotEmpty) ...[
                _buildSectionHeader(
                  'Expiring Soon',
                  _expiringItems.length,
                  AppTheme.warningOrange,
                  Icons.schedule,
                ),
                const SizedBox(height: AppTheme.spacingM),
                ..._expiringItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: _buildReminderCard(item, isExpired: false),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 60,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'All Fresh! 🎉',
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              'No items are expiring soon.\nKeep up the great work!',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalReminders = _expiringItems.length + _expiredItems.length;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.warningOrange.withValues(alpha: 0.1),
            AppTheme.errorRed.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: AppTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attention Needed',
                      style: AppTheme.headingSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                    Text(
                      '$totalReminders items need your attention',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Expired',
                  _expiredItems.length.toString(),
                  AppTheme.errorRed,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildSummaryItem(
                  'Expiring Soon',
                  _expiringItems.length.toString(),
                  AppTheme.warningOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Text(
          title,
          style: AppTheme.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingS,
            vertical: AppTheme.spacingXS,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Text(
            count.toString(),
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderCard(GroceryItem item, {required bool isExpired}) {
    final color = isExpired ? AppTheme.errorRed : AppTheme.warningOrange;
    final daysText = isExpired 
        ? 'Expired ${item.daysUntilExpiry.abs()} days ago'
        : 'Expires in ${item.daysUntilExpiry} days';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            // Status Indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(width: AppTheme.spacingM),
            
            // Item Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            child: Image.asset(
                              'assets/images/image.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.shopping_basket,
                                  color: AppTheme.primaryGreen,
                                  size: 24,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      child: Image.asset(
                        'assets/images/image.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.shopping_basket,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          );
                        },
                      ),
                    ),
            ),

            const SizedBox(width: AppTheme.spacingM),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTheme.headingSmall.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    '${item.category} • Qty: ${item.quantity}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      daysText,
                      style: AppTheme.bodySmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppTheme.textLight,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'consumed':
                    _markAsConsumed(item);
                    break;
                  case 'extend':
                    _extendExpiry(item);
                    break;
                  case 'delete':
                    _deleteItem(item);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'consumed',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 20, color: AppTheme.successGreen),
                      SizedBox(width: 8),
                      Text('Mark as consumed'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'extend',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: AppTheme.infoBlue),
                      SizedBox(width: 8),
                      Text('Extend expiry'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: AppTheme.errorRed),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _markAsConsumed(GroceryItem item) async {
    final updatedItem = GroceryItem(
      id: item.id,
      name: item.name,
      quantity: item.quantity,
      category: item.category,
      barcode: item.barcode,
      addedDate: item.addedDate,
      expiryDate: item.expiryDate,
      imageUrl: item.imageUrl,
      notes: item.notes,
      isConsumed: true,
    );

    await LocalDatabaseService.updateGroceryItem(updatedItem);
    _loadItems();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} marked as consumed'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  void _extendExpiry(GroceryItem item) async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: item.expiryDate.add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null) {
      final updatedItem = GroceryItem(
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        category: item.category,
        barcode: item.barcode,
        addedDate: item.addedDate,
        expiryDate: newDate,
        imageUrl: item.imageUrl,
        notes: item.notes,
        isConsumed: item.isConsumed,
      );

      await LocalDatabaseService.updateGroceryItem(updatedItem);
      _loadItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} expiry date updated'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    }
  }

  void _deleteItem(GroceryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalDatabaseService.deleteGroceryItem(item.id);
      _loadItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} deleted'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}