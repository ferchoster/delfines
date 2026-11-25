# Versión 0.4 – Caja y cierre de turno

## Alcance
- Apertura de turno con fondo inicial.
- Una sola caja abierta a la vez.
- Asociación automática de ventas a la sesión abierta.
- Bloqueo de cobros si no se abrió caja.
- Resumen de cobros por método de pago.
- Entradas y salidas manuales de efectivo.
- Arqueo y cierre con diferencia documentada.
- Historial local de sesiones.

## Fórmula de efectivo esperado
Fondo inicial + ventas cobradas en efectivo + entradas manuales - salidas manuales. Los cobros con tarjeta y transferencia se muestran por separado y no se suman al efectivo físico.

## Consideraciones
- El punto de venta registra el total de la venta como cobro. Si el monto recibido en efectivo supera el total, la referencia registra el cambio entregado.
- No hay soporte todavía para pagos divididos entre varios métodos.
- Usuario fijo actual: Administrador; falta módulo de usuarios y permisos.
- No se ejecutó compilación Flutter ni prueba en dispositivo por ausencia del SDK en este entorno.
