import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/business_info.dart';

enum CompanySize {
  startup,
  small,
  medium,
  large,
  enterprise,
}

extension CompanySizeExt on CompanySize {
  String get label {
    switch (this) {
      case CompanySize.startup:
        return 'Startup';
      case CompanySize.small:
        return 'Pequeña';
      case CompanySize.medium:
        return 'Mediana';
      case CompanySize.large:
        return 'Grande';
      case CompanySize.enterprise:
        return 'Corporativo';
    }
  }

  double get multiplier {
    switch (this) {
      case CompanySize.startup:
        return 0.8;
      case CompanySize.small:
        return 1.0;
      case CompanySize.medium:
        return 1.3;
      case CompanySize.large:
        return 1.6;
      case CompanySize.enterprise:
        return 2.0;
    }
  }
}

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({
    CompanySize initial = CompanySize.small,
    BusinessInfo initialBusinessInfo = const BusinessInfo(),
  })  : _companySize = initial,
        _businessInfo = initialBusinessInfo;

  CompanySize _companySize;
  BusinessInfo _businessInfo;

  CompanySize get companySize => _companySize;

  double get multiplier => _companySize.multiplier;

  BusinessInfo get businessInfo => _businessInfo;

  double get ivaPercent => _businessInfo.ivaPercent;

  void setCompanySize(CompanySize size) {
    _companySize = size;
    DatabaseHelper.instance.setSetting('company_size', size.index.toString());
    notifyListeners();
  }

  Future<void> saveBusinessInfo(BusinessInfo info) async {
    final db = DatabaseHelper.instance;
    await db.setSetting('biz_name', info.companyName);
    await db.setSetting('biz_email', info.email);
    await db.setSetting('biz_phone', info.phone);
    await db.setSetting('biz_address', info.address);
    await db.setSetting('biz_website', info.website);
    await db.setSetting('biz_iva', info.ivaPercent.toString());
    _businessInfo = info;
    notifyListeners();
  }
}
