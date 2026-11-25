# Versión 0.3 – Pedidos y cocina

## Incluye
- Bandeja de pedidos vigentes (hasta 100 recientes).
- Filtro por estado y servicio: Local, Para llevar y Domicilio.
- Cambio de estado persistente: Pendiente, En preparación, Listo y Entregado.
- Vista de detalle de la comanda con artículos, cantidades y total.

## Consideraciones
- La venta y el consumo de receta ocurren al cobrar en el POS.
- Cambiar el estado de cocina no vuelve a descontar insumos.
- No se implementa cancelación/reintegro automático en esta versión para evitar devolver existencias incorrectamente sin un flujo de autorización y trazabilidad.
- Sigue siendo código fuente Flutter; no es todavía una APK compilada.
