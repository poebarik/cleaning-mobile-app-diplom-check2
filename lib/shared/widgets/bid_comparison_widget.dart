import 'package:flutter/material.dart';
import '../../data/models/order/order_response.dart';

class BidComparisonWidget extends StatelessWidget {
  final List<OrderResponse> bids;
  final Function(OrderResponse) onSelect;

  const BidComparisonWidget({
    super.key,
    required this.bids,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Предложения клинеров',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...bids.map((bid) => _buildBidCard(bid)),
      ],
    );
  }

  Widget _buildBidCard(OrderResponse bid) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bid.cleanerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (bid.cleanerRating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(bid.cleanerRating!.toStringAsFixed(1)),
                          ],
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${bid.priceOffer} ₽',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => onSelect(bid),
                      child: const Text('Выбрать'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(bid.message),
          ],
        ),
      ),
    );
  }
}