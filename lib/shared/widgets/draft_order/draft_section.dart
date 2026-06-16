// lib/presentation/shared/widgets/draft_order/draft_section.dart
import 'package:flutter/material.dart';

class DraftSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const DraftSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}