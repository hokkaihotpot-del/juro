class AllergyItem {
  final String id;
  final String ingredientName;
  final bool isPreset;

  const AllergyItem({
    required this.id,
    required this.ingredientName,
    required this.isPreset,
  });

  factory AllergyItem.fromJson(Map<String, dynamic> json) => AllergyItem(
        id: json['id'] as String,
        ingredientName: json['ingredient_name'] as String,
        isPreset: json['is_preset'] as bool,
      );
}

class AllergyListResponse {
  final List<AllergyItem> items;
  final int total;

  const AllergyListResponse({required this.items, required this.total});

  factory AllergyListResponse.fromJson(Map<String, dynamic> json) =>
      AllergyListResponse(
        items: (json['items'] as List)
            .map((i) => AllergyItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        total: json['total'] as int,
      );
}
