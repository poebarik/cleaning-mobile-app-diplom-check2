// lib/presentation/shared/widgets/draft_order/draft_header.dart
import 'package:flutter/material.dart';

class DraftHeader extends StatelessWidget {
  final VoidCallback onClose;

  const DraftHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        16,
      ),
      child: Row(
        children: [
          // Кнопка закрытия
          Material(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                child: Icon(
                  Icons.close,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Создание заказа',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          // Балансирующий виджет
          const SizedBox(width: 38),
        ],
      ),
    );
  }
}