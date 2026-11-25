# Data Warehouse – Sistema de Análisis de Ventas

## Archivos
- `Carga_DataWarehouse_Ventas.pdf`: informe con proceso, resultados y evidencias generadas por consultas reales.
- `carga_datawarehouse_ventas.sql`: script completo de creación/carga/validación.
- `DataWarehouse_Ventas.sqlite`: base SQLite ejecutada y poblada.
- `evidencias/`: imágenes de los resultados obtenidos al ejecutar las consultas.

## Modelo dimensional
- `DimCliente`: una fila por cliente.
- `DimProducto`: una fila por producto.
- `DimFecha`: una fila por fecha de venta, con año, mes, día y trimestre.
- `FactVentas`: una fila por venta, con cantidad, precio unitario y total.

## Ejecución
Abrir `DataWarehouse_Ventas.sqlite` con DB Browser for SQLite, o ejecutar `carga_datawarehouse_ventas.sql` con SQLite 3. El script contiene datos de ejemplo transcritos de las tres tablas visibles en la página 3 del PDF fuente.

## Alcance de los datos
El archivo fuente muestra tres filas de Clientes, tres de Productos y tres de Ventas. El informe utiliza esas filas visibles y no afirma que representen la totalidad de la base transaccional original. La evidencia de la página 2 del PDF fuente corresponde a una ejecución ETL transaccional anterior, no a la carga dimensional de este paquete.

## Publicar en GitHub
1. Inicia sesión en GitHub y crea un repositorio público llamado `DataWarehouse-Sistema-Ventas`.
2. Sube todos los archivos de esta carpeta, incluida la carpeta `evidencias`.
3. Copia la URL del repositorio.
4. Reemplaza en el PDF la indicación `PENDIENTE DE PUBLICAR` por la URL real.

No se ha inventado un enlace de GitHub: la publicación requiere acceso autenticado a la cuenta del propietario.
