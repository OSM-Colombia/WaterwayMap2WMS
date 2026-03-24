# WaterwayMap2WMS

Sincroniza capas GeoJSON publicadas por WaterwayMap hacia PostgreSQL local para
publicarlas como WMS en GeoServer.

## Qué hace este proyecto

Este repositorio incluye 3 scripts Bash:

- `updateWaterwaysMapData-loops.sh`: descarga `planet-loops` y carga en
  `planet_loops`.
- `updateWaterwaysMapData-ends.sh`: descarga `planet-ends` y carga en
  `planet_ends`.
- `updateWaterwaysMapData-river2stream.sh`: descarga
  `planet-waterway-stream-ends` y carga en `planet_rivers2streams`.

Flujo común de cada script:

1. Crea/usa el directorio de trabajo `/home/geoserver/data/waterways`.
2. Descarga un archivo `.geojson.gz` desde `https://data.waterwaymap.org/`.
3. Descomprime el archivo.
4. Elimina la tabla destino en PostgreSQL (`DROP TABLE IF EXISTS`).
5. Importa el GeoJSON con `ogr2ogr` a la base de datos `waterways`.
6. Borra el archivo `.geojson` temporal.
7. Registra la salida en logs locales (`Loops.log`, `Ends.log`,
   `river2stream.log`).

## Requisitos

### Sistema

- Linux con `bash`.
- `cron` para programación periódica.

### Herramientas CLI

Instala como mínimo:

- `wget`
- `gunzip` (paquete `gzip`)
- `psql` (paquete `postgresql-client`)
- `ogr2ogr` (paquete `gdal-bin`)

Ejemplo en Debian/Ubuntu:

```bash
sudo apt update
sudo apt install -y wget gzip postgresql-client gdal-bin cron
```

## Requisitos de base de datos

Los scripts usan actualmente:

- **Nombre de DB**: `waterways`
- **Conexión**: local (sin host explícito), usando socket local de PostgreSQL.
- **Usuario**: el usuario del sistema operativo que ejecuta el script (a menos
  que definas variables como `PGUSER`/`PGPASSWORD`).

Comandos usados por los scripts:

- `psql -d waterways ...`
- `ogr2ogr ... PG:"dbname=waterways" ...`

### Autenticación local `peer` (sin clave)

Si PostgreSQL está configurado con método `peer` para conexiones locales
(`local` en `pg_hba.conf`):

- No necesitas `PGPASSWORD`.
- PostgreSQL toma como usuario el usuario Linux que ejecuta el script (por
  ejemplo, `geoserver`).
- Debe existir un rol con ese mismo nombre en PostgreSQL. Si no existe,
  aparecerá un error como: `FATAL: role "geoserver" does not exist`.

Crear el rol (sin password) para usar `peer`:

```bash
sudo -u postgres createuser geoserver
```

Prueba de conexión con `peer` (ejecutando como usuario Linux `geoserver`):

```bash
psql -d waterways -c "SELECT current_user, current_database();"
```

### Configuración recomendada de PostgreSQL

1. Crear la base de datos:

   ```bash
   createdb waterways
   ```

2. (Recomendado para GeoServer espacial) habilitar PostGIS:

   ```bash
   psql -d waterways -c "CREATE EXTENSION IF NOT EXISTS postgis;"
   ```

3. Verificar autenticación local en `pg_hba.conf` para el usuario que ejecuta
   `cron` (por ejemplo, `geoserver`).

## Configuración rápida

1. Clona este repositorio y entra al directorio.
2. Da permisos de ejecución:

   ```bash
   chmod +x updateWaterwaysMapData-*.sh
   ```

3. Ejecuta manualmente una primera carga:

   ```bash
   ./updateWaterwaysMapData-loops.sh
   ./updateWaterwaysMapData-ends.sh
   ./updateWaterwaysMapData-river2stream.sh
   ```

4. Revisa logs en `/home/geoserver/data/waterways/`.

## Programación con cron

Edita el crontab del usuario que tiene acceso a PostgreSQL y al directorio
`/home/geoserver/data/waterways`:

```bash
crontab -e
```

Ejemplo para ejecutar todos los días a las 02:10, 02:20 y 02:30:

```cron
10 2 * * * /home/geoserver/github/WaterwayMap2WMS/updateWaterwaysMapData-loops.sh
20 2 * * * /home/geoserver/github/WaterwayMap2WMS/updateWaterwaysMapData-ends.sh
30 2 * * * /home/geoserver/github/WaterwayMap2WMS/updateWaterwaysMapData-river2stream.sh
```

Si necesitas credenciales explícitas de PostgreSQL, añade variables al inicio
del crontab, por ejemplo:

```cron
PGHOST=localhost
PGPORT=5432
PGDATABASE=waterways
PGUSER=geoserver
PGPASSWORD=change_me
```

Nota: con autenticación `peer`, normalmente no necesitas estas variables; son
útiles si cambias a autenticación por contraseña (`md5` o `scram-sha-256`).

## Uso desde GeoServer (WMS)

### 1) Crear un Store PostgreSQL/PostGIS

En GeoServer:

1. `Data > Stores > Add new Store`.
2. Selecciona `PostGIS`.
3. Configura conexión a la base `waterways` (host/puerto/usuario/password).
4. Guarda y prueba conexión.

### 2) Publicar las capas

Publica como layers las tablas:

- `planet_loops`
- `planet_ends`
- `planet_rivers2streams`

Configura SRS y bounding boxes al publicar cada capa.

### 3) Consumir por WMS

Una vez publicadas, puedes solicitar mapas vía endpoint WMS de tu workspace:

- `http://<tu-geoserver>/geoserver/<workspace>/wms`

Ejemplo de operación `GetCapabilities`:

- `http://<tu-geoserver>/geoserver/<workspace>/wms?service=WMS&request=GetCapabilities`

## Notas operativas

- Los scripts reemplazan completamente cada tabla en cada ejecución.
- Si falla una ejecución, revisa primero los logs en
  `/home/geoserver/data/waterways/`.
- El directorio de trabajo se limpia de archivos `*.geojson` y `*.geojson.gz`
  en cada corrida.
