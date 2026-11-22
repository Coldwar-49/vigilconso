// Immutable value object for user subscription state.
// Used as AsyncNotifier<Subscriptions> state in subscriptionProvider.

class Subscriptions {
  final List<String> brands;
  final List<String> categories;

  const Subscriptions({
    required this.brands,
    required this.categories,
  });

  Subscriptions copyWith({List<String>? brands, List<String>? categories}) {
    return Subscriptions(
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
    );
  }

  bool get isEmpty => brands.isEmpty && categories.isEmpty;
}
