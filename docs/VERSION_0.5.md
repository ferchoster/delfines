# Versión 0.5 – Reportes del negocio

## Incluye
- Períodos rápidos: hoy, últimos 7 días y mes actual.
- Rango de fechas personalizado.
- Indicadores de ventas, cantidad de ventas, costo de recetas, utilidad bruta estimada y ticket promedio.
- Desglose diario de ventas.
- Ventas por servicio (local, para llevar y domicilio).
- Ventas por método de pago.
- Top 10 de platos por cantidad vendida.
- Salidas de caja, gastos registrados por categoría y compras de ingredientes.

## Criterio contable mostrado
La utilidad que presenta el reporte es la utilidad bruta almacenada en las ventas (venta menos costo de receta registrado). No debe interpretarse como utilidad neta: no resta gastos operativos, impuestos ni costos no capturados. Las salidas de caja, los gastos y las compras se muestran en indicadores separados para evitar sumarlos dos veces sin una conciliación contable.

## Validación
Se ejecutaron las consultas de reporte contra SQLite con datos de prueba de venta, detalle, pago, salida de caja, gasto y compra. Los resultados esperados se obtuvieron y `PRAGMA integrity_check` devolvió `ok`. No se ejecutó `flutter analyze` ni compilación APK porque Flutter/Dart SDK no está disponible en este entorno.
