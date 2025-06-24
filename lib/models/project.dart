class Project {
  final String name;
  final String description;
  String htmlContent;

  Project({
    required this.name,
    required this.description,
    this.htmlContent = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'htmlContent': htmlContent,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    name: json['name'],
    description: json['description'],
    htmlContent: json['htmlContent'] ?? '',
  );
}
