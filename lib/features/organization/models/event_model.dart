class EventModel {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final int participantCount;
  final String availableFunds;
  final String status;

  EventModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    required this.participantCount,
    required this.availableFunds,
    required this.status,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      participantCount: json['participantCount'] is int
          ? json['participantCount'] as int
          : int.tryParse(json['participantCount']?.toString() ?? '0') ?? 0,
      availableFunds: json['availableFunds']?.toString() ?? '0',
      status: json['status'] as String? ?? 'active',
    );
  }
}
