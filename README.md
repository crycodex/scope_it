# Scope IT

Aplicación móvil para generar cotizaciones profesionales de servicios de desarrollo de software y marketing digital. Produce PDFs de "Nota de Venta" listos para entregar al cliente.

## Características

- **Cotizaciones multi-servicio:** Web, App Móvil, Backend/API, Automatización IA, Marketing Digital y Personalizado
- **Configurador por pasos:** Plataforma, funcionalidades, usuarios, extras, soporte y marketing
- **Módulo de marketing:** Redes sociales, eventos, anuncios digitales, contenido y email marketing
- **Gestión de proyectos:** Lista de proyectos con búsqueda, estados y historial
- **Generación de PDF:** Nota de Venta con desglose de costos, IVA y recurrentes
- **Personalización:** Temas claro/oscuro, información del negocio, multiplicadores por tamaño de empresa

## Requisitos

- Flutter SDK `^3.10.1`
- Dart `^3.10.1`
- Android Studio / Xcode (según plataforma target)

## Instalación

```bash
flutter pub get
flutter run
```

## Build

```bash
# Android release (requiere key.properties con credenciales de firma)
flutter build apk --release

# iOS release
flutter build ios --release
```

Para configurar el firmado de Android, crea `android/key.properties`:
```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=...
```

## Iconos y Splash

```bash
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create
```
