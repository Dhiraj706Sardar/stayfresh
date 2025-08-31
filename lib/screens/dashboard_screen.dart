import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/app_theme.dart';
import '../models/grocery_item.dart';
import '../services/local_database_service.dart';
import 'add_item_screen.dart';
import 'barcode_scanner_screen.dart';

/// Premium dashboard screen with grocery list and quick actions
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<GroceryItem> _groceryItems = [];
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Fruits',
    'Vegetables',
    'Dairy',
    'Meat',
    'Bakery',
    'Beverages',
    'Snacks',
    'Frozen',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadGroceryItems();
  }

  void _loadGroceryItems() {
    setState(() {
      _groceryItems = LocalDatabaseService.getAllGroceryItems();
    });
  }

  List<GroceryItem> get _filteredItems {
    if (_selectedCategory == 'All') {
      return _groceryItems.where((item) => !item.isConsumed).toList();
    }
    return _groceryItems
        .where((item) => !item.isConsumed && item.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadGroceryItems();
          },
          color: AppTheme.primaryGreen,
          child: CustomScrollView(
            slivers: [
              // App Bar
              _buildSliverAppBar(),

              // Quick Actions
              SliverToBoxAdapter(child: _buildQuickActions()),

              // Statistics Cards
              SliverToBoxAdapter(child: _buildStatisticsCards()),

              // Category Filter
              SliverToBoxAdapter(child: _buildCategoryFilter()),

              // Grocery List
              _buildGroceryList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.pureWhite,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppTheme.pureWhite,
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingL,
            AppTheme.spacingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Dashboard',
                          style: AppTheme.headingLarge.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage your groceries',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Profile Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/default_profile.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: AppTheme.pureWhite,
                            size: 20,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: AnimationConfiguration.staggeredList(
        position: 0,
        duration: const Duration(milliseconds: 600),
        child: SlideAnimation(
          verticalOffset: 30.0,
          child: FadeInAnimation(
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.add_circle_outline,
                    title: 'Add Item',
                    subtitle: 'Manually add grocery',
                    color: AppTheme.primaryGreen,
                    onTap: () => _navigateToAddItem(),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan Barcode',
                    subtitle: 'Quick add with camera',
                    color: AppTheme.accentGreen,
                    onTap: () => _navigateToScanner(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: AppTheme.headingSmall.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    final totalItems = _groceryItems.where((item) => !item.isConsumed).length;
    final expiringItems = LocalDatabaseService.getExpiringItems().length;
    final expiredItems = LocalDatabaseService.getExpiredItems().length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: AnimationConfiguration.staggeredList(
        position: 1,
        duration: const Duration(milliseconds: 600),
        child: SlideAnimation(
          verticalOffset: 30.0,
          child: FadeInAnimation(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Items',
                    value: totalItems.toString(),
                    color: AppTheme.infoBlue,
                    icon: Icons.inventory_2,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: _buildStatCard(
                    title: 'Expiring Soon',
                    value: expiringItems.toString(),
                    color: AppTheme.warningOrange,
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: _buildStatCard(
                    title: 'Expired',
                    value: expiredItems.toString(),
                    color: AppTheme.errorRed,
                    icon: Icons.warning,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.headingMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: AnimationConfiguration.staggeredList(
        position: 2,
        duration: const Duration(milliseconds: 600),
        child: SlideAnimation(
          verticalOffset: 30.0,
          child: FadeInAnimation(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: AppTheme.headingSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;

                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppTheme.spacingS,
                        ),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: AppTheme.lightGray,
                          selectedColor: AppTheme.primaryGreen,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppTheme.pureWhite
                                : AppTheme.textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroceryList() {
    final filteredItems = _filteredItems;

    if (filteredItems.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: AppTheme.textLight.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'No items found',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                'Add your first grocery item to get started',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = filteredItems[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: _buildGroceryItemCard(item),
                ),
              ),
            ),
          );
        }, childCount: filteredItems.length),
      ),
    );
  }

  Widget _buildGroceryItemCard(GroceryItem item) {
    final daysUntilExpiry = item.daysUntilExpiry;
    Color statusColor = AppTheme.successGreen;
    String statusText = 'Fresh';

    if (item.isExpired) {
      statusColor = AppTheme.errorRed;
      statusText = 'Expired';
    } else if (item.isExpiringSoon) {
      statusColor = AppTheme.warningOrange;
      statusText = 'Expires soon';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Row(
          children: [
            // Item Image
            Container(
              width: 60,
              height: 60,
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusS,
                            ),
                            child: Image.asset(
                              'assets/images/image.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.shopping_basket,
                                  color: AppTheme.primaryGreen,
                                  size: 30,
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
                            size: 30,
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
                  Row(
                    children: [
                      Text(
                        '${item.category} • Qty: ${item.quantity}',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingS,
                      vertical: AppTheme.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Text(
                      statusText,
                      style: AppTheme.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Column(
              children: [
                Text(
                  '${daysUntilExpiry}d',
                  style: AppTheme.bodyMedium.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppTheme.textLight),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        // TODO: Navigate to edit screen
                        break;
                      case 'consumed':
                        _markAsConsumed(item);
                        break;
                      case 'delete':
                        _deleteItem(item);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'consumed',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text('Mark as consumed'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 20,
                            color: AppTheme.errorRed,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddItem() {
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AddItemScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        )
        .then((_) => _loadGroceryItems());
  }

  void _navigateToScanner() {
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const BarcodeScannerScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        )
        .then((_) => _loadGroceryItems());
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
    _loadGroceryItems();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} marked as consumed'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
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
      _loadGroceryItems();

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
