
-- ============================================================
-- DATA WAREHOUSE: SISTEMA DE ANALISIS DE VENTAS
-- Motor: SQLite 3
-- Base transaccional fuente: sistema_ventas.db
--
-- IMPORTANTE:
-- Este paquete es reproducible con los registros visibles en
-- el PDF "Carga.pdf". Si ya tienes la base real, conserva una
-- copia y verifica que sus tablas/columnas coincidan antes de
-- ejecutar este script sobre ella.
-- ============================================================

PRAGMA foreign_keys = ON;

-- Tablas transaccionales de demostración basadas en el PDF.
-- CREATE TABLE IF NOT EXISTS no elimina tablas preexistentes.
CREATE TABLE IF NOT EXISTS Clientes (
    cliente_id INTEGER PRIMARY KEY,
    nombre TEXT NOT NULL,
    correo TEXT NOT NULL UNIQUE,
    fecha_registro TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS Productos (
    producto_id INTEGER PRIMARY KEY,
    nombre_producto TEXT NOT NULL,
    precio REAL NOT NULL CHECK (precio >= 0),
    stock INTEGER NOT NULL CHECK (stock >= 0)
);

CREATE TABLE IF NOT EXISTS Ventas (
    venta_id INTEGER PRIMARY KEY,
    cliente_id INTEGER NOT NULL,
    producto_id INTEGER NOT NULL,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario REAL NOT NULL CHECK (precio_unitario >= 0),
    total REAL NOT NULL CHECK (total >= 0),
    fecha_venta TEXT NOT NULL,
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id),
    FOREIGN KEY (producto_id) REFERENCES Productos(producto_id)
);

-- Datos transaccionales transcritos de las tablas visibles
-- en la página 3 del PDF entregado.
INSERT OR IGNORE INTO Clientes(cliente_id,nombre,correo,fecha_registro) VALUES
(101,'Juan Perez','juan.perez@email.com','2026-01-15'),
(102,'Maria Gomez','maria.gomez@email.com','2026-02-20'),
(103,'Carlos Rodriguez','carlos.rodriguez@email.com','2026-03-10');

INSERT OR IGNORE INTO Productos(producto_id,nombre_producto,precio,stock) VALUES
(201,'Laptop Pro 15',1200.00,15),
(202,'Mouse Inalambrico',25.50,50),
(203,'Teclado Mecanico',85.00,30);

INSERT OR IGNORE INTO Ventas(venta_id,cliente_id,producto_id,cantidad,precio_unitario,total,fecha_venta) VALUES
(301,101,201,1,1200.00,1200.00,'2026-10-01'),
(302,102,202,2,25.50,51.00,'2026-10-02'),
(303,103,203,1,85.00,85.00,'2026-10-03');

-- Dimensiones
CREATE TABLE IF NOT EXISTS DimCliente (
    cliente_key INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id_origen INTEGER NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    correo TEXT NOT NULL,
    fecha_registro TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS DimProducto (
    producto_key INTEGER PRIMARY KEY AUTOINCREMENT,
    producto_id_origen INTEGER NOT NULL UNIQUE,
    nombre_producto TEXT NOT NULL,
    precio REAL NOT NULL,
    stock_actual INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS DimFecha (
    fecha_key INTEGER PRIMARY KEY,
    fecha_completa TEXT NOT NULL UNIQUE,
    anio INTEGER NOT NULL,
    mes INTEGER NOT NULL,
    dia INTEGER NOT NULL,
    trimestre INTEGER NOT NULL
);

-- Tabla de hechos: una fila por venta transaccional.
CREATE TABLE IF NOT EXISTS FactVentas (
    venta_key INTEGER PRIMARY KEY AUTOINCREMENT,
    venta_id_origen INTEGER NOT NULL UNIQUE,
    cliente_key INTEGER NOT NULL,
    producto_key INTEGER NOT NULL,
    fecha_key INTEGER NOT NULL,
    cantidad INTEGER NOT NULL,
    precio_unitario REAL NOT NULL,
    total REAL NOT NULL,
    FOREIGN KEY (cliente_key) REFERENCES DimCliente(cliente_key),
    FOREIGN KEY (producto_key) REFERENCES DimProducto(producto_key),
    FOREIGN KEY (fecha_key) REFERENCES DimFecha(fecha_key)
);

-- Carga de dimensiones. OR IGNORE permite ejecutar nuevamente
-- el script sin duplicar las claves de origen.
INSERT OR IGNORE INTO DimCliente(cliente_id_origen,nombre,correo,fecha_registro)
SELECT cliente_id,nombre,correo,fecha_registro
FROM Clientes;

INSERT OR IGNORE INTO DimProducto(producto_id_origen,nombre_producto,precio,stock_actual)
SELECT producto_id,nombre_producto,precio,stock
FROM Productos;

INSERT OR IGNORE INTO DimFecha(fecha_key,fecha_completa,anio,mes,dia,trimestre)
SELECT DISTINCT
    CAST(strftime('%Y%m%d', fecha_venta) AS INTEGER),
    fecha_venta,
    CAST(strftime('%Y', fecha_venta) AS INTEGER),
    CAST(strftime('%m', fecha_venta) AS INTEGER),
    CAST(strftime('%d', fecha_venta) AS INTEGER),
    ((CAST(strftime('%m', fecha_venta) AS INTEGER)-1)/3)+1
FROM Ventas
WHERE fecha_venta IS NOT NULL;

-- Carga de la tabla de hechos después de cargar las dimensiones.
INSERT OR IGNORE INTO FactVentas
(venta_id_origen,cliente_key,producto_key,fecha_key,cantidad,precio_unitario,total)
SELECT
    v.venta_id,
    dc.cliente_key,
    dp.producto_key,
    CAST(strftime('%Y%m%d',v.fecha_venta) AS INTEGER),
    v.cantidad,
    v.precio_unitario,
    v.total
FROM Ventas v
JOIN DimCliente dc ON dc.cliente_id_origen = v.cliente_id
JOIN DimProducto dp ON dp.producto_id_origen = v.producto_id
JOIN DimFecha df ON df.fecha_completa = v.fecha_venta;

-- CONSULTAS DE VALIDACION
SELECT 'DimCliente' AS tabla, COUNT(*) AS registros FROM DimCliente
UNION ALL SELECT 'DimProducto', COUNT(*) FROM DimProducto
UNION ALL SELECT 'DimFecha', COUNT(*) FROM DimFecha
UNION ALL SELECT 'FactVentas', COUNT(*) FROM FactVentas;

-- Vista analítica de ventas.
CREATE VIEW IF NOT EXISTS VistaDW_Ventas AS
SELECT
    f.venta_id_origen AS venta_id,
    c.nombre AS cliente,
    p.nombre_producto AS producto,
    d.fecha_completa AS fecha_venta,
    f.cantidad,
    f.precio_unitario,
    f.total
FROM FactVentas f
JOIN DimCliente c ON c.cliente_key = f.cliente_key
JOIN DimProducto p ON p.producto_key = f.producto_key
JOIN DimFecha d ON d.fecha_key = f.fecha_key;

SELECT * FROM VistaDW_Ventas ORDER BY venta_id;

-- Registros huérfanos: el resultado esperado es cero.
SELECT COUNT(*) AS hechos_sin_cliente
FROM FactVentas f LEFT JOIN DimCliente d ON d.cliente_key=f.cliente_key
WHERE d.cliente_key IS NULL;

SELECT COUNT(*) AS hechos_sin_producto
FROM FactVentas f LEFT JOIN DimProducto d ON d.producto_key=f.producto_key
WHERE d.producto_key IS NULL;

SELECT COUNT(*) AS hechos_sin_fecha
FROM FactVentas f LEFT JOIN DimFecha d ON d.fecha_key=f.fecha_key
WHERE d.fecha_key IS NULL;
