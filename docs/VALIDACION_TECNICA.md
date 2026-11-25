# Validación técnica de la primera entrega

- Base SQLite derivada del archivo de origen: `PRAGMA integrity_check = ok`.
- Base distribuida en assets sanitizada: 0 productos, 0 ventas, 0 proveedores/clientes operativos y 6 categorías iniciales.
- Extensiones de restaurante presentes: insumos, recetas, receta_detalle, movimientos_insumos y pedidos_servicio.
- Prueba SQL aislada del flujo de venta: se insertó un plato de prueba, se calculó y descontó su receta, se guardó venta/detalle/pago/pedido y movimiento de ingrediente en una transacción; la integridad final fue `ok`.
- Prueba de existencia insuficiente: se rechazó el consumo y no se creó una segunda venta.
- No se ejecutó `flutter analyze`, pruebas de widgets ni compilación Android porque Flutter/Dart/Android SDK no están instalados en este entorno.

## Validación adicional v0.2
Se probó con SQLite una compra de 1,000 g de camarón, creación del lote, actualización de existencias y consumo de 150 g desde el lote. El stock y el saldo del lote quedaron en 850 g y `PRAGMA integrity_check` devolvió `ok`. La validación de interfaz/compilación Flutter sigue pendiente por no disponer del SDK Flutter/Android en este entorno.


## Versión 0.4 – Caja
- Se agregaron flujos para abrir y cerrar sesiones de caja, registrar entradas/salidas y consultar resumen por método de pago.
- El punto de venta requiere una sesión abierta y asigna la venta a su caja.
- El efectivo esperado se calcula con fondo inicial + pagos en efectivo + entradas manuales − salidas manuales.
- El cierre conserva efectivo esperado, contado y diferencia en observaciones.
- Pendiente de `flutter analyze` y pruebas en Android: Flutter/Dart SDK no está disponible en el entorno de generación.

## Reportes v0.5
- Consultas SQL de reportes verificadas con datos de prueba para ventas, detalles, pagos, salidas de caja, gastos y compras de ingredientes.
- `PRAGMA integrity_check` devolvió `ok` en la base de prueba.
- No se pudo ejecutar `flutter analyze` ni compilar APK: Flutter/Dart SDK no está instalado en el entorno.


## Versión 0.6
- Se agregó la generación local de archivos PDF y Excel para los reportes.
- La revisión estática confirmó que los botones reciben el reporte ya calculado y exportan el rango activo.
- Pendiente ejecutar `flutter pub get`, `flutter analyze` y pruebas reales de compartir PDF/XLSX en Android al disponer de Flutter SDK.
