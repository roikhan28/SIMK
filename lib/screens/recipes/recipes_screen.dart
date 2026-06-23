import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/rbac.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/formatters.dart';
import '../../widgets/common/page_header.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RecipeCategory> _categories = [];
  List<Recipe> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final service = context.read<AuthProvider>().dataService;
    final categories = await service.getRecipeCategories();
    final recipes = await service.getRecipes();
    if (mounted) {
      setState(() {
        _categories = categories;
        _recipes = recipes;
        _loading = false;
      });
    }
  }

  Future<void> _showRecipeDialog(BuildContext context, {Recipe? recipe}) async {
    final isEdit = recipe != null;
    final service = context.read<AuthProvider>().dataService;
    final ingredients = await service.getIngredients();
    RecipeDetail? detail;

    if (isEdit) {
      try {
        detail = await service.getRecipeDetail(recipe!.id);
      } catch (_) {
        detail = RecipeDetail(
          id: recipe!.id,
          name: recipe.name,
          categoryId: recipe.categoryId,
          categoryName: recipe.categoryName,
          price: recipe.price,
          servings: recipe.servings,
          description: recipe.description,
        );
      }
    }

    if (!mounted) return;

    final nameController = TextEditingController(text: detail?.name ?? recipe?.name ?? '');
    final priceController = TextEditingController(
      text: (detail?.price ?? recipe?.price ?? 0).toStringAsFixed(0),
    );
    final servingsController = TextEditingController(
      text: (detail?.servings ?? recipe?.servings ?? 1).toString(),
    );
    final descriptionController = TextEditingController(
      text: detail?.description ?? recipe?.description ?? '',
    );
    final stepsController = TextEditingController(
      text: detail?.steps.map((s) => s.instruction).join('\n') ?? '',
    );

    var selectedCategory = _categories.firstWhere(
      (c) => c.id == (detail?.categoryId ?? recipe?.categoryId),
      orElse: () => _categories.first,
    );
    final ingredientRows = <_IngredientRow>[];
    if (detail != null && detail.ingredients.isNotEmpty) {
      for (final line in detail.ingredients) {
        final matches = ingredients.where((i) => i.id == line.ingredientId);
        ingredientRows.add(_IngredientRow(
          ingredient: matches.isEmpty ? null : matches.first,
          quantityController: TextEditingController(text: line.quantity.toString()),
        ));
      }
    } else {
      ingredientRows.add(_IngredientRow());
    }

    var saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Resep' : 'Tambah Resep'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      enabled: !saving,
                      decoration: const InputDecoration(labelText: 'Nama Resep'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RecipeCategory>(
                      value: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                          .toList(),
                      onChanged: saving ? null : (v) => setDialogState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga', prefixText: 'Rp '),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: servingsController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Porsi'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      enabled: !saving,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Deskripsi'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Bahan', style: Theme.of(context).textTheme.titleSmall),
                    ),
                    const SizedBox(height: 8),
                    ...ingredientRows.map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<Ingredient>(
                                  value: row.ingredient,
                                  decoration: const InputDecoration(labelText: 'Bahan'),
                                  items: ingredients
                                      .map((i) => DropdownMenuItem(value: i, child: Text(i.name)))
                                      .toList(),
                                  onChanged: saving ? null : (v) => setDialogState(() => row.ingredient = v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: row.quantityController,
                                  enabled: !saving,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Qty'),
                                ),
                              ),
                            ],
                          ),
                        )),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: saving
                            ? null
                            : () => setDialogState(() => ingredientRows.add(_IngredientRow())),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah Bahan'),
                      ),
                    ),
                    TextField(
                      controller: stepsController,
                      enabled: !saving,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Langkah memasak',
                        hintText: 'Satu langkah per baris',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final price = double.tryParse(priceController.text.replaceAll(',', '.'));
                        final servings = int.tryParse(servingsController.text);

                        if (name.isEmpty || price == null || price < 0 || servings == null || servings < 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lengkapi nama, harga, dan porsi dengan benar')),
                          );
                          return;
                        }

                        final ingredientPayload = <Map<String, dynamic>>[];
                        for (final row in ingredientRows) {
                          if (row.ingredient == null) continue;
                          final qty = double.tryParse(row.quantityController.text.replaceAll(',', '.'));
                          if (qty == null || qty <= 0) continue;
                          ingredientPayload.add({
                            'ingredient_id': row.ingredient!.id,
                            'quantity': qty,
                          });
                        }

                        final steps = stepsController.text
                            .split('\n')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();

                        setDialogState(() => saving = true);
                        try {
                          final saved = isEdit
                              ? await service.updateRecipe(
                                  recipe!.id,
                                  name: name,
                                  categoryId: selectedCategory.id,
                                  price: price,
                                  servings: servings,
                                  description: descriptionController.text.trim(),
                                  ingredients: ingredientPayload,
                                  steps: steps,
                                )
                              : await service.createRecipe(
                                  name: name,
                                  categoryId: selectedCategory.id,
                                  price: price,
                                  servings: servings,
                                  description: descriptionController.text.trim(),
                                  ingredients: ingredientPayload,
                                  steps: steps,
                                );

                          if (!mounted) return;
                          setState(() {
                            if (isEdit) {
                              final index = _recipes.indexWhere((r) => r.id == saved.id);
                              if (index >= 0) _recipes[index] = saved;
                            } else {
                              _recipes.add(saved);
                            }
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Resep diperbarui' : 'Resep ditambahkan'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    for (final row in ingredientRows) {
      row.quantityController.dispose();
    }
  }

  Future<void> _showCategoryDialog(BuildContext context, {RecipeCategory? category}) async {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');
    var saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    enabled: !saving,
                    decoration: const InputDecoration(labelText: 'Nama Kategori'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    enabled: !saving,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama kategori wajib diisi')),
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          final service = context.read<AuthProvider>().dataService;
                          final saved = isEdit
                              ? await service.updateRecipeCategory(
                                  category!.id,
                                  name: name,
                                  description: descriptionController.text.trim(),
                                )
                              : await service.createRecipeCategory(
                                  name: name,
                                  description: descriptionController.text.trim(),
                                );

                          if (!mounted) return;
                          setState(() {
                            if (isEdit) {
                              final index = _categories.indexWhere((c) => c.id == saved.id);
                              if (index >= 0) _categories[index] = saved;
                            } else {
                              _categories.add(saved);
                            }
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'Kategori diperbarui' : 'Kategori ditambahkan'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showRecipeDetail(BuildContext context, Recipe recipe) async {
    RecipeDetail detail;
    try {
      detail = await context.read<AuthProvider>().dataService.getRecipeDetail(recipe.id);
    } catch (_) {
      detail = RecipeDetail(
        id: recipe.id,
        name: recipe.name,
        categoryId: recipe.categoryId,
        categoryName: recipe.categoryName,
        price: recipe.price,
        servings: recipe.servings,
        description: recipe.description,
      );
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(detail.name),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kategori: ${detail.categoryName}'),
                Text('Harga: ${formatCurrency(detail.price)}'),
                Text('Porsi: ${detail.servings}'),
                if (detail.description.isNotEmpty) Text('Deskripsi: ${detail.description}'),
                if (detail.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Bahan:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...detail.ingredients.map(
                    (i) => Text('• ${i.ingredientName}: ${i.quantity} ${i.unit}'),
                  ),
                ],
                if (detail.steps.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Langkah:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...detail.steps.map(
                    (s) => Text('${s.stepNumber}. ${s.instruction}'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthProvider, UserRole?>((a) => a.user?.role);
    if (role == null) return const SizedBox.shrink();

    final canCreate = Rbac.canCreate(role, AppModule.recipes);
    final canUpdate = Rbac.canUpdate(role, AppModule.recipes);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Resep',
            subtitle: 'Kelola kategori, resep, bahan, dan langkah memasak',
            action: canCreate
                ? ElevatedButton.icon(
                    onPressed: _categories.isEmpty ? null : () => _showRecipeDialog(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Tambah Resep'),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Daftar Resep'),
              Tab(text: 'Kategori'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _RecipeList(
                        recipes: _recipes,
                        canEdit: canUpdate,
                        onEdit: (r) => _showRecipeDialog(context, recipe: r),
                        onTap: (r) => _showRecipeDetail(context, r),
                      ),
                      _CategoryList(
                        categories: _categories,
                        canCreate: canCreate,
                        canEdit: canUpdate,
                        onAdd: () => _showCategoryDialog(context),
                        onEdit: (c) => _showCategoryDialog(context, category: c),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _IngredientRow {
  _IngredientRow({this.ingredient, TextEditingController? quantityController})
      : quantityController = quantityController ?? TextEditingController();

  Ingredient? ingredient;
  final TextEditingController quantityController;
}

class _RecipeList extends StatelessWidget {
  const _RecipeList({
    required this.recipes,
    required this.canEdit,
    required this.onEdit,
    required this.onTap,
  });

  final List<Recipe> recipes;
  final bool canEdit;
  final void Function(Recipe recipe) onEdit;
  final void Function(Recipe recipe) onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        itemCount: recipes.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = recipes[i];
          return ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.menu_book, color: AppTheme.secondary),
            ),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${r.categoryName} • ${r.servings} porsi'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(formatCurrency(r.price), style: const TextStyle(fontWeight: FontWeight.bold)),
                if (canEdit) ...[
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => onEdit(r)),
                ],
              ],
            ),
            onTap: () => onTap(r),
          );
        },
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.canCreate,
    required this.canEdit,
    required this.onAdd,
    required this.onEdit,
  });

  final List<RecipeCategory> categories;
  final bool canCreate;
  final bool canEdit;
  final VoidCallback onAdd;
  final void Function(RecipeCategory category) onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canCreate)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Kategori'),
            ),
          ),
        Expanded(
          child: Card(
            child: ListView.separated(
              itemCount: categories.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final c = categories[i];
                return ListTile(
                  leading: const Icon(Icons.category_outlined, color: AppTheme.primary),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(c.description),
                  trailing: canEdit
                      ? IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => onEdit(c))
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
