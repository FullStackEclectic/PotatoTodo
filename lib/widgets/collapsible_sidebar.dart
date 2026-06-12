import 'package:flutter/material.dart';
import 'package:potato_todo/screens/settings_screen.dart';
import 'package:potato_todo/screens/achievements_screen.dart';
import 'category_panel.dart';

class CollapsibleSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationRailDestination> destinations;

  const CollapsibleSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  }) : super(key: key);

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      width: _isCollapsed ? 80 : 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.05)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNavigationDestinations(),
                Divider(height: 1, indent: 16, endIndent: 16, color: theme.dividerColor.withOpacity(0.05)),
                Expanded(child: CategoryPanel(isCollapsed: _isCollapsed)),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.05)),
          _buildTrailingActions(context),
        ],
      ),
    );
  }

  Widget _buildNavigationDestinations() {
    return Column(
      children: List.generate(widget.destinations.length, (index) {
        final dest = widget.destinations[index];
        final isSelected = widget.selectedIndex == index;
        return _buildNavItem(
          context,
          isSelected: isSelected,
          icon: (dest.icon as Icon).icon!,
          label: (dest.label as Text).data!,
          onTap: () => widget.onDestinationSelected(index),
        );
      }),
    );
  }
  
  Widget _buildTrailingActions(BuildContext context) {
    return Column(
      children: [
         _buildNavItem(
          context,
          isSelected: false,
          icon: Icons.settings_outlined,
          label: '设置',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
        ),
         _buildNavItem(
          context,
          isSelected: false,
          icon: Icons.emoji_events_outlined,
          label: '成就',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AchievementsScreen())),
        ),
         _buildNavItem(
          context,
          isSelected: false,
          icon: Icons.info_outline,
          label: '关于',
          onTap: () => showAboutDialog(
            context: context,
            applicationName: '土豆 Todo',
            applicationVersion: '1.0.0',
          ),
        ),
        IconButton(
          icon: Icon(
            _isCollapsed ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
            size: 16,
          ),
          onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required bool isSelected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    // Modern Pill Style
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.7);
    final bgColor = isSelected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Increased spacing
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16), // Softer roundness
          hoverColor: theme.colorScheme.primary.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // More breathing room
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith( // Larger cleaner text
                        color: color,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected) // Optional: Right indicator for selected state
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    // User Profile / Branding Section
    if (_isCollapsed) {
      return Container(
        height: 90,
        alignment: Alignment.center,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'P', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
        ),
      );
    }
    
    return Container(
      height: 120, // Taller header for better aesthetic
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16), // Squircle for modern look
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
             child: const Center(
              child: Text(
                'P', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Potato Todo',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '专业版',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
