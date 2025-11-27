class Activity {
  final String id;
  final String name;
  final String? description;
  final String siteId;

  Activity({
    required this.id,
    required this.name,
    this.description,
    required this.siteId,
  });
}