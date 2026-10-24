class OrganizationModel {
  final String id;
  final String name;
  final String slug;
  final String role;

  OrganizationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.role,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      role: json['role'] as String? ?? 'panitia_anggota',
    );
  }

  String get roleDisplayTitle {
    switch (role) {
      case 'ketua_kegiatan':
        return 'Ketua Kegiatan';
      case 'bendahara':
        return 'Bendahara';
      case 'panitia_anggota':
      default:
        return 'Panitia Pelaksana';
    }
  }

  bool get isBendahara => role == 'bendahara';
  bool get isKetua => role == 'ketua_kegiatan';
}
