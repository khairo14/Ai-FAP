import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../income_provider.dart';

/// Minimal Income List Screen for debugging
class IncomeListScreenMinimal extends StatelessWidget {
  const IncomeListScreenMinimal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income (Debug)'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Income Screen Loaded!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                try {
                  final provider = Provider.of<IncomeProvider>(context, listen: false);
                  
                  if (!provider.isInitialized) {
                    provider.initialize();
                  }
                } catch (e, stack) {
                  debugPrint('Error accessing provider: $e');
                  debugPrint('Stack: $stack');
                }
              },
              child: const Text('Test Provider'),
            ),
            const SizedBox(height: 16),
            Consumer<IncomeProvider>(
              builder: (context, provider, child) {
                return Text(
                  'Loading: ${provider.isLoading}\n'
                  'Categories: ${provider.categories.length}\n'
                  'Income: ${provider.incomeList.length}',
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
