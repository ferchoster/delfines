# Cevichería Los Delfines ERP (Android)

Primera entrega de desarrollo sobre Flutter + SQLite, diseñada para operar sin conexión a internet.

## Configuración confirmada
- Servicio: consumo en local, para llevar y domicilio.
- Plataforma: Android (teléfono y tablet; interfaz adaptable a vertical/horizontal).
- Inventario: recetas con descuento automático de ingredientes al cobrar.
- Moneda de trabajo: GTQ (Q). La tasa de impuestos se deja en 0 hasta que el negocio la defina.

## Funcionalidad implementada hasta la versión 0.6
- Base SQLite local derivada del esquema del ERP Ryzen original.
- Inicialización limpia: no importa productos, ventas, proveedores, clientes ni configuración de la ferretería.
- Categorías iniciales del menú.
- Alta de platos/productos con precio de venta y costo estimado.
- Alta de ingredientes con unidad base (g, ml o unidad), existencias, mínimo y costo por unidad base.
- Configuración de receta por plato.
- Punto de venta inicial: carrito, tipo de servicio, mesa/dirección, método de pago y cobro.
- Venta y descuento de ingredientes dentro de una sola transacción SQLite; si falta un ingrediente, no se registra la venta.
- Validación de consumo agregado cuando un ingrediente aparece en más de un plato del mismo pedido.
- Panel con resumen de ventas del día, menú, ingredientes y alertas de mínimo.

## Cómo preparar el proyecto
Requiere Flutter SDK instalado y Android SDK configurado.

```bash
flutter pub get
flutter analyze
flutter build apk --release
```

## Importante
Este es un prototipo funcional de primera etapa, no una APK final certificada. En el entorno de generación no está instalado Flutter, por lo que no fue posible ejecutar `flutter analyze`, pruebas en emulador ni compilar el APK.

La impresión Bluetooth/USB, respaldos/restauración, usuarios/permisos y ajustes de configuración están reservados para próximas etapas. La impresión y escáner tienen dependencias declaradas, pero aún no están conectados a flujos funcionales.

## Reglas de inventario
- Las cantidades de las recetas se expresan en la unidad base de cada ingrediente.
- Ejemplos: camarón en gramos, jugo de limón en mililitros, tostadas en unidades.
- Registrar el stock en esa misma unidad. No mezclar kg con g ni litros con ml sin convertir antes.
- No se incluyen precios ni recetas comerciales inventadas. El negocio debe registrar sus valores reales.

## Versión 0.4 – Caja y cierre de turno
- Apertura de caja con fondo inicial y observaciones.
- Ventas vinculadas automáticamente a la sesión de caja abierta; no se permite cobrar si no hay un turno abierto.
- Resumen de ventas y cobros por efectivo, tarjeta y transferencia.
- Registro manual de entradas y salidas de efectivo.
- Cálculo de efectivo esperado, captura del efectivo contado y diferencia de caja guardada en el cierre.
- El cambio entregado en ventas en efectivo queda como referencia; el cobro contabilizado en caja corresponde al total de la venta.
- Historial de turnos anteriores.

## Versión 0.3 – Pedidos y cocina
- Bandeja de comandas con filtros por estado y tipo de servicio.
- Flujo de estados: Pendiente, En preparación, Listo y Entregado.
- Consulta del detalle de cada pedido, con cantidades, platos y total.
- Persistencia del estado en las tablas de ventas y pedidos de servicio.
- La actualización de estado no vuelve a descontar inventario: el consumo se registra una sola vez al cobrar.

## Versión 0.2 – Compras y recepción de ingredientes
- Registro de proveedores.
- Registro de compras de ingredientes con factura, cantidad, costo, lote y fecha de vencimiento.
- Actualización automática del stock y costo promedio ponderado del ingrediente.
- Trazabilidad de lotes y aviso visual de lotes que vencen en los próximos 7 días.
- Consumo de lotes por FEFO (primero vence, primero sale) al cobrar recetas.
- Unidades disponibles: g, kg, lb, ml y unidad. Mantener la misma unidad base entre ingrediente y receta.


## Versión 0.5 – Reportes
- Filtro de reportes por hoy, últimos 7 días, mes actual o rango personalizado.
- Ventas totales, cantidad de ventas, costo estimado de recetas, utilidad bruta estimada y ticket promedio.
- Resumen de ventas por día, tipo de servicio y método de pago.
- Ranking de platos más vendidos.
- Salidas registradas en caja, gastos registrados por categoría y compras de ingredientes.
- La utilidad se identifica como bruta estimada: no descuenta gastos operativos, impuestos ni costos que no estén registrados.
- Los reportes consultan SQLite local y funcionan sin conexión.
- Exportación de reportes a PDF y Excel (.xlsx), compartibles desde Android.


## Versión 0.6 – Exportación de reportes
- Exportación del período seleccionado a PDF con resumen, ventas diarias, servicios, pagos, platos más vendidos y gastos por categoría.
- Exportación a Excel (.xlsx) con hojas separadas para resumen, ventas por día, servicios, métodos de pago, platos y gastos.
- Los archivos se generan localmente y se comparten mediante el menú nativo de Android.
- Se conserva la advertencia de que la utilidad es bruta estimada y no equivale a utilidad neta.
