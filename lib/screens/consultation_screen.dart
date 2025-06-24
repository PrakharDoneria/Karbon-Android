import 'package:flutter/material.dart';
import '../services/subscription_service.dart';

class SubscriptionConsultScreen extends StatelessWidget {
  const SubscriptionConsultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unlimited Access', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('₹199/month · Billed monthly'),
            const SizedBox(height: 12),
            const Text('• Unlimited HTML generations\n'
                '• Priority response time\n'
                '• Free users a maximum of 3 requests per minute'),
            const SizedBox(height: 24),
            const Text(
              'You can cancel anytime through your Google Play subscriptions.',
              style: TextStyle(fontSize: 12),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await SubscriptionService.instance.purchase();
                if (SubscriptionService.instance.isSubscribed && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Subscribe for ₹199/month'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
  }
}
