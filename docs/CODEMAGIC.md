# Compilación en Codemagic

El workflow usa `mac_mini_m2`, que está disponible para cuentas personales en el plan gratuito de Codemagic (500 minutos de compilación al mes). Linux X2 requiere facturación habilitada. La compilación de APK no necesita ejecutar el emulador Android.

## Pasos
1. Reemplazar el archivo `codemagic.yaml` de la raíz del repositorio GitHub por el archivo actualizado.
2. Hacer commit del cambio en la rama `main`.
3. En Codemagic, volver a la aplicación y pulsar `Check for configuration files` o actualizar el workflow.
4. Seleccionar `Cevichería Los Delfines - APK Android` y pulsar `Start new build`.
5. Al finalizar correctamente, descargar `app-release.apk` desde Artifacts.

Este workflow genera la estructura Android que falta en el proyecto, descarga dependencias y compila una APK release para instalación directa. No configura firma de publicación en Google Play.
