import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../models/catalog.dart';
import '../widgets/banner_ad_slot.dart';
import 'group_screen.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      bottomNavigationBar: BannerAdSlot(ads: scope.ads),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: category.brands.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final brand = category.brands[i];
          return Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(brand.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                  '${brand.groups.length} lists • ${brand.modelCount} models'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BrandScreen(category: category, brand: brand),
              )),
            ),
          );
        },
      ),
    );
  }
}

class BrandScreen extends StatefulWidget {
  const BrandScreen({super.key, required this.category, required this.brand});

  final Category category;
  final Brand brand;

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final q = _query.trim().toLowerCase();
    final groups = q.isEmpty
        ? widget.brand.groups
        : widget.brand.groups
            .where((g) =>
                g.title.toLowerCase().contains(q) ||
                g.code.toLowerCase().contains(q) ||
                g.models.any((m) => m.toLowerCase().contains(q)))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.brand.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Filter inside ${widget.brand.name}',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BannerAdSlot(ads: scope.ads),
      body: groups.isEmpty
          ? const Center(child: Text('No matching list found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => GroupCard(
                group: groups[i],
                query: _query,
                subtitle: widget.category.name,
              ),
            ),
    );
  }
}
