# Versión 0.6 – Exportación de reportes

## Funciones
- Botones para exportar el período actualmente seleccionado a PDF o Excel (.xlsx).
- PDF con encabezado del negocio, rango de fechas, resumen general, ventas por día, tipos de servicio, métodos de pago, platos más vendidos y gastos por categoría.
- Excel con hojas separadas: Resumen, Ventas por dia, Servicios, Metodos de pago, Platos mas vendidos y Gastos.
- Los importes se escriben como valores numéricos en Excel para permitir operaciones y filtros posteriores.
- Los archivos se guardan temporalmente en el dispositivo y se entregan al menú nativo para compartirlos.
- La exportación utiliza los mismos datos locales del reporte; no requiere internet.

## Consideraciones
- La utilidad continúa identificada como bruta estimada; no descuenta todos los gastos operativos, impuestos ni costos no registrados.
- Se agregaron las dependencias `excel` y `cross_file`; se utilizan las dependencias `pdf`, `path_provider` y `share_plus` ya declaradas.
- No se pudo ejecutar `flutter pub get`, `flutter analyze` ni compilar el APK en este entorno porque Flutter/Dart SDK no están instalados. La integración requiere validación final en un entorno Flutter.
