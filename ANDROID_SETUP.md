# Preparación Android

El entorno donde se preparó este código no tiene Flutter SDK ni Android SDK, por eso no se pudo generar el directorio nativo `android/` ni compilar una APK.

En una computadora con Flutter instalado, abre una terminal dentro de esta carpeta y ejecuta:

```bash
flutter create --platforms=android --org com.losdelfines .
flutter pub get
flutter analyze
flutter build apk --release
```

Después de generar la plataforma Android, revisa el nombre visible de la aplicación y el `applicationId` antes de distribuirla. La base SQLite se copia al almacenamiento privado de la app al primer inicio.
