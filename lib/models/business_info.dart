class BusinessInfo {
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String website;
  final double ivaPercent; // 0-100, e.g. 16 = 16%

  const BusinessInfo({
    this.companyName = 'Ionos Hub',
    this.email = 'info@ionoshub.com',
    this.phone = '',
    this.address = 'Ibarra - Ecuador',
    this.website = 'https://www.ionoshub.net',
    this.ivaPercent = 15,
  });

  BusinessInfo copyWith({
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? website,
    double? ivaPercent,
  }) {
    return BusinessInfo(
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      website: website ?? this.website,
      ivaPercent: ivaPercent ?? this.ivaPercent,
    );
  }
}
