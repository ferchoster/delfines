import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Base local derivada del esquema RyzenERP original, inicializada limpia para Los Delfines.
class LocalDatabase {
  LocalDatabase._();
  static final instance = LocalDatabase._();
  Database? _db;
  Database get db => _db!;

  Future<void> initialize() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final target = p.join(dir.path, 'los_delfines_erp.db');
    if (!await File(target).exists()) {
      final bytes = await rootBundle.load('assets/legacy/los_delfines_base.db');
      final tmp = File('$target.importing');
      await tmp.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      final check = await openDatabase(tmp.path, readOnly: true);
      final integrity = await check.rawQuery('PRAGMA integrity_check');
      await check.close();
      if (integrity.isEmpty || integrity.first.values.first != 'ok') {
        await tmp.delete();
        throw StateError('La base de origen no superó la verificación SQLite.');
      }
      await tmp.rename(target);
    }
    _db = await openDatabase(target, version: 2, onOpen: (database) async {
      await database.execute('PRAGMA foreign_keys = OFF');
      final initialized = await database.rawQuery("SELECT valor FROM configuracion WHERE clave='delfines_initialized'");
      if (initialized.isEmpty) await _initializeCleanBusiness(database);
      await _ensureSchema(database);
      await database.execute('PRAGMA foreign_keys = ON');
      await database.execute('PRAGMA journal_mode = WAL');
      await database.execute('PRAGMA busy_timeout = 5000');
    });
  }

  Future<void> _initializeCleanBusiness(Database d) async {
    // Conserva la estructura de tablas del ERP original, pero no los datos de la ferretería.
    const tables = ['compras_insumos_detalle','compras_insumos','lotes_insumos','pedidos_servicio','movimientos_insumos','receta_detalle','recetas','insumos','ventas_pagos','ventas_detalle','ventas','compras_detalle','compras','movimientos','existencias','productos','categorias','marcas','clientes','proveedores','gastos','pagos','notas_credito','orden_repuestos','ordenes','caja_movimientos','caja_sesiones','bitacora','usuarios'];
    for (final table in tables) { try { await d.execute('DELETE FROM "$table"'); } catch (_) {} }
    await d.execute('DELETE FROM configuracion');
    final cats = ['Ceviches','Cócteles','Tostadas','Bebidas','Extras','Combos'];
    for (final c in cats) { await d.insert('categorias', {'nombre': c, 'descripcion': 'Menú Cevichería Los Delfines'}); }
    final config = <String,String>{
      'negocio_nombre':'Cevichería Los Delfines',
      'direccion':'', 'telefono':'', 'nit':'', 'iva':'0',
      'moneda':'GTQ', 'modo_operacion':'local_para_llevar_domicilio',
      'delfines_initialized':'1', 'version_esquema_delfines':'2'
    };
    for (final e in config.entries) { await d.insert('configuracion', {'clave':e.key,'valor':e.value}); }
  }

  Future<void> _ensureSchema(Database d) async {
    await d.execute('''CREATE TABLE IF NOT EXISTS insumos(
      id INTEGER PRIMARY KEY AUTOINCREMENT, codigo TEXT, nombre TEXT NOT NULL,
      unidad_base TEXT NOT NULL, stock REAL NOT NULL DEFAULT 0,
      stock_minimo REAL NOT NULL DEFAULT 0, costo_unidad REAL NOT NULL DEFAULT 0,
      proveedor_id INTEGER, activo INTEGER NOT NULL DEFAULT 1,
      fecha_creacion TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS recetas(
      id INTEGER PRIMARY KEY AUTOINCREMENT, producto_id INTEGER NOT NULL UNIQUE,
      porciones REAL NOT NULL DEFAULT 1, instrucciones TEXT,
      FOREIGN KEY(producto_id) REFERENCES productos(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS receta_detalle(
      id INTEGER PRIMARY KEY AUTOINCREMENT, receta_id INTEGER NOT NULL,
      insumo_id INTEGER NOT NULL, cantidad REAL NOT NULL,
      UNIQUE(receta_id,insumo_id),
      FOREIGN KEY(receta_id) REFERENCES recetas(id) ON DELETE CASCADE,
      FOREIGN KEY(insumo_id) REFERENCES insumos(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS movimientos_insumos(
      id INTEGER PRIMARY KEY AUTOINCREMENT, insumo_id INTEGER NOT NULL,
      tipo TEXT NOT NULL, cantidad REAL NOT NULL, costo_unidad REAL NOT NULL DEFAULT 0,
      motivo TEXT, referencia TEXT, fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(insumo_id) REFERENCES insumos(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS pedidos_servicio(
      id INTEGER PRIMARY KEY AUTOINCREMENT, venta_id INTEGER NOT NULL,
      tipo_servicio TEXT NOT NULL, mesa TEXT, direccion TEXT, estado TEXT NOT NULL DEFAULT 'Pendiente',
      FOREIGN KEY(venta_id) REFERENCES ventas(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS compras_insumos(
      id INTEGER PRIMARY KEY AUTOINCREMENT, numero TEXT NOT NULL UNIQUE,
      proveedor_id INTEGER, factura TEXT, fecha TEXT NOT NULL,
      subtotal REAL NOT NULL DEFAULT 0, total REAL NOT NULL DEFAULT 0,
      observaciones TEXT, estado TEXT NOT NULL DEFAULT 'Registrada',
      FOREIGN KEY(proveedor_id) REFERENCES proveedores(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS compras_insumos_detalle(
      id INTEGER PRIMARY KEY AUTOINCREMENT, compra_id INTEGER NOT NULL,
      insumo_id INTEGER NOT NULL, cantidad REAL NOT NULL,
      costo_unidad REAL NOT NULL, subtotal REAL NOT NULL,
      lote TEXT, fecha_vencimiento TEXT,
      FOREIGN KEY(compra_id) REFERENCES compras_insumos(id),
      FOREIGN KEY(insumo_id) REFERENCES insumos(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS lotes_insumos(
      id INTEGER PRIMARY KEY AUTOINCREMENT, insumo_id INTEGER NOT NULL,
      compra_detalle_id INTEGER, lote TEXT, fecha_ingreso TEXT NOT NULL,
      fecha_vencimiento TEXT, cantidad_inicial REAL NOT NULL,
      cantidad_disponible REAL NOT NULL, costo_unidad REAL NOT NULL,
      estado TEXT NOT NULL DEFAULT 'Disponible',
      FOREIGN KEY(insumo_id) REFERENCES insumos(id),
      FOREIGN KEY(compra_detalle_id) REFERENCES compras_insumos_detalle(id))''');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_lotes_insumo_vencimiento ON lotes_insumos(insumo_id,fecha_vencimiento)');
    await _addColumn(d,'ventas','tipo_servicio TEXT DEFAULT \'Local\'');
    await _addColumn(d,'ventas','mesa TEXT');
    await _addColumn(d,'ventas','estado_pedido TEXT DEFAULT \'Entregado\'');
    await _addColumn(d,'productos','tipo_producto TEXT DEFAULT \'Menu\'');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_insumos_nombre ON insumos(nombre)');
    await d.execute('CREATE INDEX IF NOT EXISTS idx_receta_detalle_receta ON receta_detalle(receta_id)');
  }

  Future<void> _addColumn(Database d, String table, String declaration) async {
    final name = declaration.split(' ').first;
    final cols = await d.rawQuery('PRAGMA table_info("$table")');
    if (!cols.any((c) => c['name'] == name)) await d.execute('ALTER TABLE "$table" ADD COLUMN $declaration');
  }

  Future<List<Map<String,Object?>>> menu({String query = ''}) => db.query('productos', where:'estado=? AND (nombre LIKE ? OR codigo LIKE ?)', whereArgs:['Activo','%$query%','%$query%'], orderBy:'nombre');
  Future<List<Map<String,Object?>>> ingredients({String query = ''}) => db.query('insumos', where:'activo=1 AND nombre LIKE ?', whereArgs:['%$query%'], orderBy:'nombre');
  Future<List<Map<String,Object?>>> categories() => db.query('categorias', orderBy:'nombre');
  Future<List<Map<String,Object?>>> recipeFor(int productId) => db.rawQuery('''SELECT r.id receta_id,r.porciones,r.instrucciones,rd.insumo_id,rd.cantidad,i.nombre,i.unidad_base,i.costo_unidad FROM recetas r JOIN receta_detalle rd ON rd.receta_id=r.id JOIN insumos i ON i.id=rd.insumo_id WHERE r.producto_id=? ORDER BY i.nombre''',[productId]);

  Future<int> saveMenuItem({int? id, required String name, required double price, required double cost, int? categoryId, String? description}) async {
    final values={'nombre':name,'precio_venta':price,'costo':cost,'categoria_id':categoryId,'descripcion':description,'estado':'Activo','tipo_producto':'Menu','fecha_modificacion':DateTime.now().toIso8601String()};
    if (id == null) return db.insert('productos', {...values,'codigo':'DL-${DateTime.now().millisecondsSinceEpoch}','stock':0,'stock_minimo':0,'fecha_creacion':DateTime.now().toIso8601String()});
    return db.update('productos',values,where:'id=?',whereArgs:[id]);
  }
  Future<int> saveIngredient({int? id, required String name, required String unit, required double stock, required double minStock, required double unitCost}) async {
    final values={'nombre':name,'unidad_base':unit,'stock':stock,'stock_minimo':minStock,'costo_unidad':unitCost,'activo':1};
    if (id==null) return db.insert('insumos',values);
    return db.update('insumos',values,where:'id=?',whereArgs:[id]);
  }
  Future<void> saveRecipe({required int productId, required double portions, required Map<int,double> ingredients}) async {
    await db.transaction((txn) async {
      final existing=await txn.query('recetas',where:'producto_id=?',whereArgs:[productId]);
      int recipeId;
      if(existing.isEmpty) recipeId=await txn.insert('recetas',{'producto_id':productId,'porciones':portions});
      else { recipeId=existing.first['id'] as int; await txn.update('recetas',{'porciones':portions},where:'id=?',whereArgs:[recipeId]); await txn.delete('receta_detalle',where:'receta_id=?',whereArgs:[recipeId]); }
      for(final e in ingredients.entries){ if(e.value<=0) throw StateError('Las cantidades de receta deben ser mayores que cero.'); await txn.insert('receta_detalle',{'receta_id':recipeId,'insumo_id':e.key,'cantidad':e.value}); }
    });
  }

  Future<String> checkout({required List<Map<String,Object?>> lines, required String serviceType, String? table, String? address, required String paymentMethod, required double paid}) async {
    if(lines.isEmpty) throw StateError('Agrega al menos un plato al pedido.');
    final now=DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      final openCash = await txn.query('caja_sesiones', where:"estado='Abierta'", orderBy:'id DESC', limit:1);
      if (openCash.isEmpty) throw StateError('Primero debes abrir la caja para registrar ventas.');
      final cashId = openCash.first['id'] as int;
      double total=0,cost=0;
      final prepared=<Map<String,Object?>>[];
      final demand=<int,double>{};
      final ingredientRows=<int,Map<String,Object?>>{};
      for(final line in lines){
        final pid=line['product_id'] as int; final qty=(line['quantity'] as num).toDouble();
        if(qty<=0) throw StateError('Cantidad inválida.');
        final p=(await txn.query('productos',where:'id=?',whereArgs:[pid])).first;
        final price=(line['price'] as num).toDouble();
        final recipe=await txn.rawQuery('SELECT rd.insumo_id,rd.cantidad,i.nombre,i.stock,i.costo_unidad FROM recetas r JOIN receta_detalle rd ON rd.receta_id=r.id JOIN insumos i ON i.id=rd.insumo_id WHERE r.producto_id=?',[pid]);
        if(recipe.isEmpty) throw StateError('El plato ${p['nombre']} no tiene receta configurada.');
        double lineCost=0;
        for(final ing in recipe){ final needed=(ing['cantidad'] as num).toDouble()*qty; final iid=ing['insumo_id'] as int; demand[iid]=(demand[iid]??0)+needed; ingredientRows[iid]=ing; lineCost+=needed*(ing['costo_unidad'] as num).toDouble(); }
        total+=price*qty; cost+=lineCost; prepared.add({'product':p,'qty':qty,'price':price,'cost':lineCost,'recipe':recipe});
      }
      for(final entry in demand.entries){ final ing=ingredientRows[entry.key]!; final stock=(ing['stock'] as num).toDouble(); if(stock+0.000001<entry.value) throw StateError('Existencia insuficiente de ${ing['nombre']}. Necesitas ${entry.value}, disponible: $stock'); }
      if(paid+0.001<total) throw StateError('El pago recibido es menor al total.');
      final number='DL-${DateTime.now().millisecondsSinceEpoch}';
      final saleId=await txn.insert('ventas',{'numero':number,'fecha':now,'usuario':'Administrador','subtotal':total,'descuento':0,'iva':0,'total':total,'costo_total':cost,'utilidad':total-cost,'metodo':paymentMethod,'estado':'Vigente','observaciones':'','tipo_servicio':serviceType,'mesa':table,'estado_pedido':'Pendiente','caja_id':cashId});
      for(final l in prepared){
        final p=l['product'] as Map<String,Object?>; final qty=l['qty'] as double; final price=l['price'] as double;
        await txn.insert('ventas_detalle',{'venta_id':saleId,'producto_id':p['id'],'descripcion':p['nombre'],'cantidad':qty,'precio':price,'descuento':0,'costo':(l['cost'] as double)/qty,'subtotal':price*qty});
        for(final ing in (l['recipe'] as List<Map<String,Object?>>)){
          final used=(ing['cantidad'] as num).toDouble()*qty;
          await txn.rawUpdate('UPDATE insumos SET stock=stock-? WHERE id=?',[used,ing['insumo_id']]);
          var remaining=used;
          final lots=await txn.query('lotes_insumos',where:'insumo_id=? AND cantidad_disponible>0',whereArgs:[ing['insumo_id']],orderBy:'CASE WHEN fecha_vencimiento IS NULL THEN 1 ELSE 0 END, fecha_vencimiento ASC, id ASC');
          for(final lot in lots){
            if(remaining<=0) break;
            final available=(lot['cantidad_disponible'] as num).toDouble();
            final take=available<remaining?available:remaining;
            await txn.rawUpdate("UPDATE lotes_insumos SET cantidad_disponible=cantidad_disponible-?, estado=CASE WHEN cantidad_disponible-?<=0 THEN 'Agotado' ELSE estado END WHERE id=?",[take,take,lot['id']]);
            remaining-=take;
          }
          await txn.insert('movimientos_insumos',{'insumo_id':ing['insumo_id'],'tipo':'Salida','cantidad':used,'costo_unidad':ing['costo_unidad'],'motivo':'Consumo por venta','referencia':number,'fecha':now});
        }
      }
      await txn.insert('ventas_pagos',{'venta_id':saleId,'metodo':paymentMethod,'monto':total,'referencia':paymentMethod=='Efectivo' && paid>total ? 'Cambio entregado: Q${(paid-total).toStringAsFixed(2)}' : '', 'fecha':now});
      await txn.insert('pedidos_servicio',{'venta_id':saleId,'tipo_servicio':serviceType,'mesa':table,'direccion':address,'estado':'Pendiente'});
      return number;
    });
  }

  Future<List<Map<String,Object?>>> suppliers() => db.query('proveedores', orderBy:'nombre');
  Future<int> saveSupplier({required String name, String? phone, String? nit, String? address}) => db.insert('proveedores', {'nombre':name,'telefono':phone,'nit':nit,'direccion':address,'fecha':DateTime.now().toIso8601String()});

  Future<String> registerIngredientPurchase({required int? supplierId, required String? invoice, required List<Map<String,Object?>> lines, String? notes}) async {
    if (lines.isEmpty) throw StateError('Agrega al menos un ingrediente a la compra.');
    final now=DateTime.now().toIso8601String();
    return db.transaction((txn) async {
      double total=0;
      for (final line in lines) {
        final qty=(line['quantity'] as num).toDouble();
        final cost=(line['unit_cost'] as num).toDouble();
        final expiry=line['expiry'] as String?;
        if(qty<=0 || cost<0) throw StateError('Revisa las cantidades y costos de la compra.');
        if(expiry!=null && expiry.isNotEmpty && DateTime.tryParse(expiry)==null) throw StateError('La fecha de vencimiento debe usar YYYY-MM-DD.');
        final row=await txn.query('insumos',where:'id=? AND activo=1',whereArgs:[line['ingredient_id']]);
        if(row.isEmpty) throw StateError('Uno de los ingredientes ya no está disponible.');
        total += qty*cost;
      }
      final number='CP-${DateTime.now().millisecondsSinceEpoch}';
      final purchaseId=await txn.insert('compras_insumos',{'numero':number,'proveedor_id':supplierId,'factura':invoice,'fecha':now,'subtotal':total,'total':total,'observaciones':notes,'estado':'Registrada'});
      for(final line in lines){
        final id=line['ingredient_id'] as int;
        final qty=(line['quantity'] as num).toDouble();
        final cost=(line['unit_cost'] as num).toDouble();
        final ingredient=(await txn.query('insumos',where:'id=?',whereArgs:[id])).first;
        final oldStock=(ingredient['stock'] as num).toDouble();
        final oldCost=(ingredient['costo_unidad'] as num).toDouble();
        final newStock=oldStock+qty;
        final avgCost=newStock<=0?cost:((oldStock*oldCost)+(qty*cost))/newStock;
        final detailId=await txn.insert('compras_insumos_detalle',{'compra_id':purchaseId,'insumo_id':id,'cantidad':qty,'costo_unidad':cost,'subtotal':qty*cost,'lote':line['lot'],'fecha_vencimiento':line['expiry']});
        await txn.update('insumos',{'stock':newStock,'costo_unidad':avgCost},where:'id=?',whereArgs:[id]);
        await txn.insert('lotes_insumos',{'insumo_id':id,'compra_detalle_id':detailId,'lote':line['lot'],'fecha_ingreso':now,'fecha_vencimiento':line['expiry'],'cantidad_inicial':qty,'cantidad_disponible':qty,'costo_unidad':cost,'estado':'Disponible'});
        await txn.insert('movimientos_insumos',{'insumo_id':id,'tipo':'Entrada','cantidad':qty,'costo_unidad':cost,'motivo':'Compra de insumos','referencia':number,'fecha':now});
      }
      return number;
    });
  }

  Future<List<Map<String,Object?>>> recentIngredientPurchases() => db.rawQuery('''SELECT c.id,c.numero,c.fecha,c.total,c.factura,p.nombre proveedor FROM compras_insumos c LEFT JOIN proveedores p ON p.id=c.proveedor_id ORDER BY c.id DESC LIMIT 50''');
  Future<List<Map<String,Object?>>> expiringIngredients({int days=7}) => db.rawQuery('''SELECT l.id,l.lote,l.fecha_vencimiento,l.cantidad_disponible,i.nombre,i.unidad_base FROM lotes_insumos l JOIN insumos i ON i.id=l.insumo_id WHERE l.cantidad_disponible>0 AND l.fecha_vencimiento IS NOT NULL AND date(l.fecha_vencimiento)<=date('now',?) ORDER BY date(l.fecha_vencimiento)''',['+$days days']);

  Future<Map<String,Object?>?> activeCashSession() async {
    final rows=await db.query('caja_sesiones',where:"estado='Abierta'",orderBy:'id DESC',limit:1);
    return rows.isEmpty?null:rows.first;
  }

  Future<int> openCashSession({required double openingAmount, String? notes}) async {
    if(openingAmount<0) throw StateError('El fondo inicial no puede ser negativo.');
    return db.transaction((txn) async {
      final active=await txn.query('caja_sesiones',where:"estado='Abierta'",limit:1);
      if(active.isNotEmpty) throw StateError('Ya existe una caja abierta.');
      return txn.insert('caja_sesiones',{'fecha_apertura':DateTime.now().toIso8601String(),'monto_inicial':openingAmount,'monto_final':0,'usuario_apertura':'Administrador','estado':'Abierta','observaciones':notes});
    });
  }

  Future<Map<String,Object?>> cashSummary(int cashId) async {
    final sessions=await db.query('caja_sesiones',where:'id=?',whereArgs:[cashId],limit:1);
    if(sessions.isEmpty) throw StateError('No se encontró la sesión de caja.');
    final session=sessions.first;
    final sales=await db.rawQuery("SELECT COALESCE(SUM(v.total),0) total,COUNT(v.id) cantidad FROM ventas v WHERE v.caja_id=? AND v.estado='Vigente'",[cashId]);
    final payments=await db.rawQuery("SELECT vp.metodo,COALESCE(SUM(vp.monto),0) monto FROM ventas_pagos vp JOIN ventas v ON v.id=vp.venta_id WHERE v.caja_id=? AND v.estado='Vigente' GROUP BY vp.metodo",[cashId]);
    final movements=await db.rawQuery('SELECT tipo,COALESCE(SUM(monto),0) monto,COUNT(*) cantidad FROM caja_movimientos WHERE caja_id=? GROUP BY tipo',[cashId]);
    double cashSales=0,cardSales=0,transferSales=0,otherSales=0,incomes=0,expenses=0;
    for(final row in payments){final method='${row['metodo']}'.toLowerCase();final amount=(row['monto'] as num).toDouble();if(method.contains('efectivo'))cashSales+=amount;else if(method.contains('tarjeta'))cardSales+=amount;else if(method.contains('transfer'))transferSales+=amount;else otherSales+=amount;}
    for(final row in movements){final amount=(row['monto'] as num).toDouble();if(row['tipo']=='Entrada')incomes+=amount;else if(row['tipo']=='Salida')expenses+=amount;}
    final opening=(session['monto_inicial'] as num? ?? 0).toDouble();
    final expected=opening+cashSales+incomes-expenses;
    return {'session':session,'sales_total':(sales.first['total'] as num).toDouble(),'sales_count':sales.first['cantidad'],'cash_sales':cashSales,'card_sales':cardSales,'transfer_sales':transferSales,'other_sales':otherSales,'incomes':incomes,'expenses':expenses,'opening':opening,'expected_cash':expected,'movements':movements};
  }

  Future<int> addCashMovement({required int cashId, required String type, required String concept, required double amount, String? reference}) async {
    if(!['Entrada','Salida'].contains(type)) throw StateError('Tipo de movimiento inválido.');
    if(concept.trim().isEmpty||amount<=0) throw StateError('Ingresa concepto y monto mayor que cero.');
    final session=await db.query('caja_sesiones',columns:['id'],where:"id=? AND estado='Abierta'",whereArgs:[cashId]);
    if(session.isEmpty) throw StateError('La caja no está abierta.');
    return db.insert('caja_movimientos',{'caja_id':cashId,'tipo':type,'concepto':concept.trim(),'monto':amount,'referencia':reference,'usuario':'Administrador','fecha':DateTime.now().toIso8601String()});
  }

  Future<void> closeCashSession({required int cashId, required double countedCash, String? notes}) async {
    if(countedCash<0) throw StateError('El efectivo contado no puede ser negativo.');
    final summary=await cashSummary(cashId);
    final expected=(summary['expected_cash'] as num).toDouble();
    final difference=countedCash-expected;
    final rows=await db.query('caja_sesiones',where:"id=? AND estado='Abierta'",whereArgs:[cashId]);
    if(rows.isEmpty) throw StateError('La caja ya está cerrada o no existe.');
    final original=rows.first['observaciones']?.toString()??'';
    final closeNote='Efectivo esperado Q${expected.toStringAsFixed(2)}; contado Q${countedCash.toStringAsFixed(2)}; diferencia Q${difference.toStringAsFixed(2)}';
    final combined=[original,closeNote,notes].where((x)=>x!=null&&x.trim().isNotEmpty).join('\n');
    await db.update('caja_sesiones',{'fecha_cierre':DateTime.now().toIso8601String(),'monto_final':countedCash,'usuario_cierre':'Administrador','estado':'Cerrada','observaciones':combined.isEmpty?null:combined},where:'id=?',whereArgs:[cashId]);
  }

  Future<List<Map<String,Object?>>> recentCashSessions() => db.query('caja_sesiones',orderBy:'id DESC',limit:20);
  Future<List<Map<String,Object?>>> cashMovements(int cashId) => db.query('caja_movimientos',where:'caja_id=?',whereArgs:[cashId],orderBy:'id DESC',limit:100);

  Future<Map<String,Object?>> salesReport({required DateTime start, required DateTime end}) async {
    final from=start.toIso8601String().substring(0,10);
    final to=end.toIso8601String().substring(0,10);
    final where="substr(fecha,1,10) BETWEEN ? AND ? AND estado='Vigente'";
    final totals=await db.rawQuery('''SELECT COUNT(*) sales_count,
      COALESCE(SUM(total),0) revenue, COALESCE(SUM(costo_total),0) cost,
      COALESCE(SUM(utilidad),0) gross_profit,
      COALESCE(AVG(total),0) average_ticket
      FROM ventas WHERE $where''',[from,to]);
    final daily=await db.rawQuery('''SELECT substr(fecha,1,10) day,COUNT(*) count,
      COALESCE(SUM(total),0) total FROM ventas WHERE $where
      GROUP BY substr(fecha,1,10) ORDER BY day''',[from,to]);
    final services=await db.rawQuery('''SELECT COALESCE(tipo_servicio,'Sin especificar') service,
      COUNT(*) count,COALESCE(SUM(total),0) total FROM ventas WHERE $where
      GROUP BY tipo_servicio ORDER BY total DESC''',[from,to]);
    final payments=await db.rawQuery('''SELECT vp.metodo method,COUNT(DISTINCT v.id) count,
      COALESCE(SUM(vp.monto),0) total FROM ventas_pagos vp JOIN ventas v ON v.id=vp.venta_id
      WHERE substr(v.fecha,1,10) BETWEEN ? AND ? AND v.estado='Vigente'
      GROUP BY vp.metodo ORDER BY total DESC''',[from,to]);
    final topItems=await db.rawQuery('''SELECT vd.descripcion name,COALESCE(SUM(vd.cantidad),0) quantity,
      COALESCE(SUM(vd.subtotal),0) total FROM ventas_detalle vd JOIN ventas v ON v.id=vd.venta_id
      WHERE substr(v.fecha,1,10) BETWEEN ? AND ? AND v.estado='Vigente'
      GROUP BY vd.descripcion ORDER BY quantity DESC,total DESC LIMIT 10''',[from,to]);
    final cashOut=await db.rawQuery('''SELECT COALESCE(SUM(cm.monto),0) total FROM caja_movimientos cm
      JOIN caja_sesiones cs ON cs.id=cm.caja_id WHERE cm.tipo='Salida'
      AND substr(cm.fecha,1,10) BETWEEN ? AND ?''',[from,to]);
    final registeredExpenses=await db.rawQuery('''SELECT COALESCE(SUM(monto),0) total FROM gastos
      WHERE substr(fecha,1,10) BETWEEN ? AND ?''',[from,to]);
    final purchases=await db.rawQuery('''SELECT COUNT(*) count,COALESCE(SUM(total),0) total
      FROM compras_insumos WHERE substr(fecha,1,10) BETWEEN ? AND ? AND estado='Registrada' ''',[from,to]);
    final expenseCategories=await db.rawQuery('''SELECT categoria,COALESCE(SUM(monto),0) total
      FROM gastos WHERE substr(fecha,1,10) BETWEEN ? AND ? GROUP BY categoria ORDER BY total DESC''',[from,to]);
    return {
      'from':from,'to':to,'totals':totals.first,'daily':daily,'services':services,
      'payments':payments,'top_items':topItems,
      'cash_outflows':(cashOut.first['total'] as num).toDouble(),
      'registered_expenses':(registeredExpenses.first['total'] as num).toDouble(),
      'purchases':purchases.first,'expense_categories':expenseCategories,
    };
  }

  Future<Map<String,Object?>> dashboard() async {
    final today=DateTime.now().toIso8601String().substring(0,10);
    final sales=await db.rawQuery("SELECT COUNT(*) n,COALESCE(SUM(total),0) total FROM ventas WHERE substr(fecha,1,10)=? AND estado='Vigente'",[today]);
    final items=await db.rawQuery('SELECT COUNT(*) n FROM productos WHERE estado=\'Activo\'');
    final ingredients=await db.rawQuery('SELECT COUNT(*) n FROM insumos WHERE activo=1');
    final low=await db.rawQuery('SELECT COUNT(*) n FROM insumos WHERE activo=1 AND stock<=stock_minimo');
    return {'sales_count':sales.first['n'],'sales_total':sales.first['total'],'menu_count':items.first['n'],'ingredient_count':ingredients.first['n'],'low_stock':low.first['n']};
  }
  Future<List<Map<String,Object?>>> recentOrders({String? status, String? serviceType}) async {
    final where=<String>['v.estado=\'Vigente\''];
    final args=<Object?>[];
    if(status!=null && status!='Todos'){where.add('COALESCE(ps.estado,v.estado_pedido)=?');args.add(status);}
    if(serviceType!=null && serviceType!='Todos'){where.add('v.tipo_servicio=?');args.add(serviceType);}
    return db.rawQuery('''SELECT v.id,v.numero,v.fecha,v.total,v.tipo_servicio,v.mesa,v.estado_pedido,COALESCE(ps.estado,v.estado_pedido) estado_actual,ps.direccion
      FROM ventas v LEFT JOIN pedidos_servicio ps ON ps.venta_id=v.id
      WHERE ${where.join(' AND ')} ORDER BY v.id DESC LIMIT 100''',args);
  }
  Future<List<Map<String,Object?>>> orderDetails(int saleId) => db.rawQuery('''SELECT descripcion,cantidad,precio,subtotal FROM ventas_detalle WHERE venta_id=? ORDER BY id''',[saleId]);
  Future<void> updateOrderStatus({required int saleId, required String status}) async {
    const allowed=['Pendiente','En preparación','Listo','Entregado'];
    if(!allowed.contains(status)) throw StateError('Estado de pedido no válido.');
    await db.transaction((txn) async {
      final rows=await txn.query('ventas',columns:['id'],where:'id=? AND estado=\'Vigente\'',whereArgs:[saleId]);
      if(rows.isEmpty) throw StateError('El pedido ya no está disponible.');
      await txn.update('ventas',{'estado_pedido':status},where:'id=?',whereArgs:[saleId]);
      final service=await txn.query('pedidos_servicio',columns:['id'],where:'venta_id=?',whereArgs:[saleId]);
      if(service.isEmpty){
        final sale=(await txn.query('ventas',where:'id=?',whereArgs:[saleId])).first;
        await txn.insert('pedidos_servicio',{'venta_id':saleId,'tipo_servicio':sale['tipo_servicio']??'Local','mesa':sale['mesa'],'estado':status});
      } else {
        await txn.update('pedidos_servicio',{'estado':status},where:'venta_id=?',whereArgs:[saleId]);
      }
    });
  }
  Future<void> close() async { await _db?.close(); _db=null; }
}
