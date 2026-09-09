import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../intelligence/intelligence_screen.dart';
import '../topics/topics_screen.dart';

/// Unified screen presenting Document Intelligence and Topics Discovery
/// with seamless segment switching.
class IntelligenceTopicsScreen extends StatefulWidget {
  final int initialSubIndex;

  const IntelligenceTopicsScreen({
    super.key,
    this.initialSubIndex = 0,
  });

  @override
  State<IntelligenceTopicsScreen> createState() =>
      _IntelligenceTopicsScreenState();
}

class _IntelligenceTopicsScreenState extends State<IntelligenceTopicsScreen> {
  late int _selectedModule;

  @override
  void initState() {
    super.initState();
    _selectedModule = widget.initialSubIndex;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 600;

    return Column(
      children: [
        // Navigation Switcher Header Strip
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Module View:',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment<int>(
                      value: 0,
                      icon: const Icon(Icons.psychology_outlined, size: 16),
                      label: Text(
                        isCompact ? 'Intelligence' : 'Document Intelligence & Cross-Reasoning',
                      ),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      icon: const Icon(Icons.hub_outlined, size: 16),
                      label: Text(
                        isCompact ? 'Topics' : 'Topics Modeling & Taxonomy',
                      ),
                    ),
                  ],
                  selected: {_selectedModule},
                  onSelectionChanged: (selected) {
                    setState(() => _selectedModule = selected.first);
                  },
                ),
              ],
            ),
          ),
        ),

        // Screen Body
        Expanded(
          child: _selectedModule == 0
              ? const IntelligenceScreen()
              : const TopicsScreen(),
        ),
      ],
    );
  }
}
