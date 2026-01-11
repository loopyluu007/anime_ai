class CharacterSheet {
  final String id;
  final String screenplayId;
  final String name;
  final String? description;
  final String? combinedViewUrl;
  final String? frontViewUrl;
  final String? sideViewUrl;
  final String? backViewUrl;
  final DateTime createdAt;
  
  CharacterSheet({
    required this.id,
    required this.screenplayId,
    required this.name,
    this.description,
    this.combinedViewUrl,
    this.frontViewUrl,
    this.sideViewUrl,
    this.backViewUrl,
    required this.createdAt,
  });
  
  factory CharacterSheet.fromJson(Map<String, dynamic> json) {
    return CharacterSheet(
      id: json['id']?.toString() ?? '',
      screenplayId: json['screenplayId']?.toString() ?? json['screenplay_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      combinedViewUrl: json['combinedViewUrl'] ?? json['combined_view_url'],
      frontViewUrl: json['frontViewUrl'] ?? json['front_view_url'],
      sideViewUrl: json['sideViewUrl'] ?? json['side_view_url'],
      backViewUrl: json['backViewUrl'] ?? json['back_view_url'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'screenplayId': screenplayId,
      'name': name,
      'description': description,
      'combinedViewUrl': combinedViewUrl,
      'frontViewUrl': frontViewUrl,
      'sideViewUrl': sideViewUrl,
      'backViewUrl': backViewUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
