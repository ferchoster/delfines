# Arquitectura y migración – Cevichería Los Delfines

## Base de partida
Se reutiliza el archivo SQLite original `ryzen.db` del paquete entregado por el usuario, previa verificación de integridad. Se conserva su estructura base de categorías, productos, ventas, detalles, pagos, compras, proveedores, movimientos, caja y gastos.

## Aislamiento de datos
En el primer inicio se copia el archivo fuente al directorio privado de la aplicación como `los_delfines_erp.db`. Se eliminan los registros operativos de la ferretería y se crean categorías del menú. El archivo de assets queda intacto. No se trasladan saldos, ventas, clientes ni datos del antiguo negocio.

## Extensiones para restaurante
- `insumos`: materias primas y unidades base.
- `recetas`: receta vinculada a un producto del menú.
- `receta_detalle`: cantidad de cada ingrediente por unidad vendida.
- `movimientos_insumos`: entradas/salidas de materia prima.
- `pedidos_servicio`: tipo de servicio, mesa o dirección y estado del pedido.
- Columnas adicionales en `ventas`: `tipo_servicio`, `mesa`, `estado_pedido`.
- Columna adicional en `productos`: `tipo_producto`.

## Regla de cobro
El cobro valida que todos los platos tengan receta y que exista suficiente cantidad de cada ingrediente. Agrupa las necesidades de ingredientes para evitar que dos líneas de una misma venta consuman más stock del disponible. La venta, el detalle, el pago, el pedido y las salidas de ingredientes se guardan en una sola transacción. Ante un error, se revierte todo.

## Pendiente de decisión del negocio
- Menú, tamaños/porciones, recetas y gramajes reales.
- Precios y costos reales.
- Si el costo por ingrediente se manejará promedio ponderado o por lote.
- Datos fiscales y tasa de impuestos aplicable.
- Reglas de propina, servicio a domicilio y cargos adicionales.
