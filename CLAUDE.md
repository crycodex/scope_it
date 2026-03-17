# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app
flutter run

# Build release APK (uses key.properties for signing)
flutter build apk --release

# Build release iOS
flutter build ios --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Generate native splash screens
flutter pub run flutter_native_splash:create
```

## Architecture

**Scope IT** is a quotation/estimate generator for software development and marketing services. It produces professional PDF sales notes ("Nota de Venta") for clients.

### State Management

Uses **Provider v6** (`ChangeNotifier`). Only two app-level providers exist:
- `ThemeProvider` — light/dark mode, persisted to SQLite
- `SettingsProvider` — company size multiplier and business info (name, email, IVA, etc.)

Most state is local to views or passed via constructor. Pricing state is held in singleton services.

### Navigation

**GoRouter v14** with named routes and slide-right transitions (320ms):
- `/` → `MainShell` (bottom nav shell with Home and Settings tabs)
- `/quotation` → `NewQuotationView` (create/edit quotation)
- `/project/:id` → `ProjectDetailView` (view/manage a saved project)
- `/settings` → `SettingsView`

### Data Layer

**SQLite via sqflite** — single `DatabaseHelper` singleton at `lib/database/database_helper.dart`. Schema version 5 with migrations. Tables: `settings`, `categories`, `services`, `projects`, `project_lines`, `marketing_config`.

### Key Models

- `QuotationConfig` (`lib/models/quotation_config.dart`) — core pricing logic, JSON-serializable, contains all multipliers, selected services, and cost calculations for dev/mobile/backend/automation
- `MarketingConfig` (`lib/models/marketing_config.dart`) — marketing service selections and pricing
- `Project` / `ProjectLine` — persisted project with associated service line items

### Services

- `PricingService` (`lib/services/pricing_service.dart`) — singleton, caches editable prices for stepper items
- `MarketingPricingService` (`lib/services/marketing_pricing_service.dart`) — marketing-specific cost calculations
- `PdfService` (`lib/services/pdf_service.dart`) — generates PDF "Nota de Venta" including development costs, marketing, recurring fees, and IVA; uses `printing` + `url_launcher` for share/print

### UI Design

Neobrutalism design system via `neubrutalism_ui` package — bold borders (2.5px), shadow offsets, Space Grotesk font. Custom theme in `lib/app/theme.dart`.
