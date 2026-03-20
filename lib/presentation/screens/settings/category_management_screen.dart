import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/constants/app_theme.dart';
import '../../../data/database/app_database.dart';
import '../../../domain/entities/category_entity.dart';
import '../../providers/category_providers.dart';
import '../../providers/database_provider.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  void _createOrEditCategory(BuildContext context, CategoryEntity? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryEditSheet(existingCategory: existing),
    );
  }

  void _deleteCategory(BuildContext context, WidgetRef ref, int id) async {
    final db = ref.read(databaseProvider);
    final isUsed = await db.categoryDao.isCategoryInUse(id);

    if (isUsed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat dihapus karena kategori ini sedang digunakan oleh transaksi atau anggaran.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await db.categoryDao.deleteCategory(id);
      ref.invalidate(categoriesStreamProvider);
      ref.invalidate(categoriesByTypeProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil dihapus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus kategori: Kesalahan internal.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _parseColor(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Tidak ada kategori.'));
          }

          final incomeCats = categories.where((c) => c.type == 'income').toList();
          final expenseCats = categories.where((c) => c.type == 'expense').toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              _buildCategoryGroup(context, ref, 'Pemasukan', incomeCats),
              const Divider(thickness: 4, color: Color(0xFFF0F0F0)),
              _buildCategoryGroup(context, ref, 'Pengeluaran', expenseCats),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrEditCategory(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryGroup(BuildContext context, WidgetRef ref, String title, List<CategoryEntity> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        ...items.map((cat) {
          final color = _parseColor(cat.color);
          return Dismissible(
            key: ValueKey(cat.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Kategori'),
                  content: const Text('Anda yakin ingin menghapus kategori ini? (Tidak bisa jika sudah digunakan)'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
            onDismissed: (_) => _deleteCategory(context, ref, cat.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(IconData(cat.icon, fontFamily: 'MaterialIcons'), size: 20),
              ),
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
              onTap: () => _createOrEditCategory(context, cat),
            ),
          );
        }),
      ],
    );
  }
}

class _CategoryEditSheet extends ConsumerStatefulWidget {
  final CategoryEntity? existingCategory;

  const _CategoryEditSheet({this.existingCategory});

  @override
  ConsumerState<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<_CategoryEditSheet> {
  late TextEditingController _nameCtrl;
  int _selectedIconCode = 0xe532; // Icons.restaurant.codePoint fallback
  String _type = 'expense';
  String _colorHex = 'FF1B4332'; // Default primary Green

  final List<String> _colorOptions = [
    'FF1B4332', 'FF2D6A4F', 'FF40916C', // Greens
    'FFE53935', 'FFD81B60', 'FF8E24AA', // Red, Pink, Purple
    'FF3949AB', 'FF1E88E5', 'FF00ACC1', // Indigo, Blue, Cyan
    'FF43A047', 'FFFDD835', 'FFFFB300', // Light Green, Yellow, Amber
    'FFFB8C00', 'FFF4511E', 'FF6D4C41', // Orange, DeepOrange, Brown
  ];

  static const List<Map<String, dynamic>> kCategoryIcons = [
    // Food & Daily
    {'icon': Icons.restaurant, 'label': 'Makan'},
    {'icon': Icons.local_cafe, 'label': 'Kafe'},
    {'icon': Icons.local_grocery_store, 'label': 'Belanja'},
    {'icon': Icons.shopping_bag, 'label': 'Shopping'},
    {'icon': Icons.shopping_cart, 'label': 'Keranjang'},

    // Transport
    {'icon': Icons.directions_car, 'label': 'Mobil'},
    {'icon': Icons.directions_bus, 'label': 'Bus'},
    {'icon': Icons.local_gas_station, 'label': 'BBM'},
    {'icon': Icons.flight, 'label': 'Pesawat'},
    {'icon': Icons.train, 'label': 'Kereta'},
    {'icon': Icons.motorcycle, 'label': 'Motor'},

    // Finance & Income
    {'icon': Icons.account_balance_wallet, 'label': 'Dompet'},
    {'icon': Icons.savings, 'label': 'Tabungan'},
    {'icon': Icons.trending_up, 'label': 'Investasi'},
    {'icon': Icons.attach_money, 'label': 'Uang'},
    {'icon': Icons.credit_card, 'label': 'Kartu'},
    {'icon': Icons.receipt_long, 'label': 'Tagihan'},
    {'icon': Icons.payment, 'label': 'Pembayaran'},
    {'icon': Icons.account_balance, 'label': 'Bank'},
    {'icon': Icons.currency_exchange, 'label': 'Kurs'},
    {'icon': Icons.monetization_on, 'label': 'Penghasilan'},
    {'icon': Icons.business_center, 'label': 'Bisnis'},
    {'icon': Icons.work, 'label': 'Kerja'},
    {'icon': Icons.laptop, 'label': 'Freelance'},

    // Lifestyle
    {'icon': Icons.sports_esports, 'label': 'Gaming'},
    {'icon': Icons.movie, 'label': 'Hiburan'},
    {'icon': Icons.music_note, 'label': 'Musik'},
    {'icon': Icons.fitness_center, 'label': 'Gym'},
    {'icon': Icons.local_hospital, 'label': 'Kesehatan'},
    {'icon': Icons.school, 'label': 'Pendidikan'},
    {'icon': Icons.book, 'label': 'Buku'},
    {'icon': Icons.home, 'label': 'Rumah'},
    {'icon': Icons.electrical_services, 'label': 'Listrik'},
    {'icon': Icons.wifi, 'label': 'Internet'},
    {'icon': Icons.phone_android, 'label': 'Pulsa'},
    {'icon': Icons.child_care, 'label': 'Anak'},
    {'icon': Icons.pets, 'label': 'Hewan'},
    {'icon': Icons.celebration, 'label': 'Hiburan'},
    {'icon': Icons.card_giftcard, 'label': 'Hadiah'},
    {'icon': Icons.volunteer_activism, 'label': 'Donasi'},
    {'icon': Icons.more_horiz, 'label': 'Lainnya'},
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existingCategory?.name ?? '');
    _selectedIconCode = widget.existingCategory?.icon ?? Icons.restaurant.codePoint;
    if (widget.existingCategory != null) {
      _type = widget.existingCategory!.type;
      _colorHex = widget.existingCategory!.color.replaceAll('#', '');
      if (_colorHex.length == 6) _colorHex = 'FF$_colorHex';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama Kategori wajib diisi')));
      return;
    }

    final db = ref.read(databaseProvider);
    final comp = CategoriesCompanion(
      id: widget.existingCategory != null ? drift.Value(widget.existingCategory!.id) : const drift.Value.absent(),
      name: drift.Value(name),
      icon: drift.Value(_selectedIconCode),
      color: drift.Value('#$_colorHex'),
      type: drift.Value(_type),
    );

    try {
      if (widget.existingCategory != null) {
        await db.categoryDao.updateCategory(comp);
      } else {
        await db.categoryDao.insertCategory(comp);
      }
      ref.invalidate(categoriesStreamProvider);
      ref.invalidate(categoriesByTypeProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          final currentColor = Color(int.parse(_colorHex, radix: 16));
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Center(
                  child: Container(
                    height: 4, width: 40, margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(widget.existingCategory == null ? 'Kategori Baru' : 'Edit Kategori',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type Segmented Button
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                              ButtonSegment(value: 'income', label: Text('Pemasukan')),
                            ],
                            selected: {_type},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() => _type = newSelection.first);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return _type == 'income' ? AppTheme.accentGreen.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2);
                                }
                                return Colors.transparent;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(labelText: 'Nama Kategori', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 24),

                        const Text('Pilih Ikon', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: kCategoryIcons.length,
                          itemBuilder: (context, index) {
                            final iconData = kCategoryIcons[index]['icon'] as IconData;
                            final label = kCategoryIcons[index]['label'] as String;
                            final isSelected = iconData.codePoint == _selectedIconCode;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedIconCode = iconData.codePoint;
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isSelected ? currentColor.withValues(alpha: 0.2) : Colors.transparent,
                                    child: Icon(
                                      iconData,
                                      color: isSelected ? currentColor : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected ? currentColor : Colors.grey[600],
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        const Text('Pilih Warna', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _colorOptions.map((hex) {
                            final isSelected = hex == _colorHex;
                            final color = Color(int.parse(hex, radix: 16));
                            return GestureDetector(
                              onTap: () => setState(() => _colorHex = hex),
                              child: CircleAvatar(
                                backgroundColor: color,
                                radius: 20,
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Simpan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
