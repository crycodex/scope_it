import 'package:flutter/material.dart';
import '../database/database_helper.dart';

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
  SettingsProvider({CompanySize initial = CompanySize.small})
      : _companySize = initial;

  CompanySize _companySize;

  CompanySize get companySize => _companySize;

  double get multiplier => _companySize.multiplier;

  void setCompanySize(CompanySize size) {
    _companySize = size;
    DatabaseHelper.instance.setSetting('company_size', size.index.toString());
    notifyListeners();
  }
}
