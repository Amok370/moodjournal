import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/coping_strategy.dart';
import '../providers/coping_provider.dart';
import '../widgets/coping_tile.dart';

class CopingScreen extends StatelessWidget {
  const CopingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);


    return Consumer<CopingProvider>(
      builder: (context, provider, _) {
        final defaults = provider.defaultStrategies;
        final userAdded = provider.userStrategies;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Başa Çıkma\nStratejileri', style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 8),
                  Text('Zorlandığında dene 💙', style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 24),

                  // Hazır stratejiler
                  Text('Önerilen Stratejiler', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...defaults.map((s) => CopingTile(strategy: s)),

                  // Kullanıcı stratejileri
                  if (userAdded.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Senin Stratejilerin', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...userAdded.map((s) => CopingTile(
                          strategy: s,
                          onDelete: () => _confirmDelete(context, provider, s),
                        )),
                  ],

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDialog(context, provider),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Yeni Strateji'),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, CopingProvider provider) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Strateji Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Strateji adı', prefixIcon: Icon(Icons.spa_rounded))),
            const SizedBox(height: 12),
            TextField(controller: descController, decoration: const InputDecoration(hintText: 'Açıklama (opsiyonel)', prefixIcon: Icon(Icons.description_rounded)), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                provider.addStrategy(CopingStrategy(name: nameController.text.trim(), description: descController.text.trim().isEmpty ? null : descController.text.trim()));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CopingProvider provider, CopingStrategy strategy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stratejiyi Sil'),
        content: Text('"${strategy.name}" silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(onPressed: () { provider.deleteStrategy(strategy.id!); Navigator.pop(ctx); }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Sil')),
        ],
      ),
    );
  }
}
