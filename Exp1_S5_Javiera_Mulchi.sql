/**
   Consulta de base de datos
   Sumativa n° 1: Aplicando funciones de agrupación
   Caso: ASOCIADOS Corredora de Propiedades
   Autor: Javiera Mülchi
   Fecha: 2025-11-10
**/

/**
   CASO 1: Listado de clientes segun rango de renta
**/
WITH clientes_formateados AS (
    SELECT 
        -- RUT 
        TO_CHAR(numrun, 'FM999G999G999') || '-' || dvrun AS rut_cliente,
        -- Nombre completo 
        INITCAP(pnombre) || ' ' ||
        NVL(INITCAP(snombre) || ' ', '') ||
        INITCAP(appaterno) || ' ' || INITCAP(apmaterno) AS nombre_completo,
        -- Dirección 
        REPLACE(direccion, ' ', '') AS direccion_compacta,
        renta,
        celular,
        -- Tramos sin gaps
        CASE 
            WHEN renta > 500000 THEN 'TRAMO 1'
            WHEN renta >= 400000 THEN 'TRAMO 2'
            WHEN renta >= 200000 THEN 'TRAMO 3'
            ELSE 'TRAMO 4'
        END AS tramo_renta
    FROM cliente
    WHERE celular IS NOT NULL
      AND renta BETWEEN TO_NUMBER('&RENTA_MINIMA') AND TO_NUMBER('&RENTA_MAXIMA')
)
SELECT 
    rut_cliente            AS "RUT Cliente",
    nombre_completo        AS "Nombre Completo Cliente", 
    direccion_compacta     AS "Direccion Cliente",
    TO_CHAR(renta, 'FM$999G999G999') AS "Renta Cliente",
    celular                AS "Celular Cliente",
    tramo_renta            AS "Tramo Renta Cliente"
FROM clientes_formateados
ORDER BY nombre_completo ASC;

/**
   CASO 2: Sueldo promedio por categoría
**/
SELECT 
    cod_categoria AS "CODIGO_CATEGORIA",
    CASE 
        WHEN cod_categoria = 1 THEN 'Gerente'
        WHEN cod_categoria = 2 THEN 'Supervisor'
        WHEN cod_categoria = 3 THEN 'Ejecutivo de Arriendo'
        WHEN cod_categoria = 4 THEN 'Auxiliar'
        ELSE 'Categoría ' || TO_CHAR(cod_categoria)
    END AS "DESCRIPCION CATEGORIA",

    COUNT(*) AS "CANTIDAD EMPLEADOS",

    CASE 
        WHEN cod_sucursal = 10 THEN 'Sucursal Las Condes'
        WHEN cod_sucursal = 20 THEN 'Sucursal Santiago Centro'
        WHEN cod_sucursal = 30 THEN 'Sucursal Providencia'
        WHEN cod_sucursal = 40 THEN 'Sucursal Vitacura'
        ELSE 'Sucursal ' || TO_CHAR(cod_sucursal)
    END AS "SUCURSAL",

    TO_CHAR(ROUND(AVG(sueldo)), 'FM$999G999G999') AS "SUELDO_PROMEDIO",
    ROUND(AVG(sueldo)) AS sueldo_promedio_num
FROM empleado
GROUP BY cod_categoria, cod_sucursal
HAVING AVG(sueldo) > TO_NUMBER('&SUELDO_PROMEDIO_MINIMO')
ORDER BY sueldo_promedio_num DESC;

/**
   CASO 3: ARRIENDO PROMEDIO POR TIPO DE PROPIEDAD (versión robusta)
**/
WITH propiedades_agrupadas AS (
  SELECT 
      p.cod_tipo_propiedad,
      COUNT(*)                             AS total_propiedades,
      ROUND(AVG(p.valor_arriendo))         AS promedio_arriendo,
      ROUND(AVG(p.superficie_mt2))         AS promedio_superficie,

      -- Promedio del ratio por propiedad
      ROUND( AVG( (p.valor_arriendo * 1.0) / NULLIF(p.superficie_mt2, 0) ) ) AS valor_arriendo_m2
  FROM propiedad p
  WHERE p.superficie_mt2 IS NOT NULL
    AND p.valor_arriendo IS NOT NULL
    AND p.superficie_mt2 > 0
  GROUP BY p.cod_tipo_propiedad
  HAVING AVG( (p.valor_arriendo * 1.0) / NULLIF(p.superficie_mt2, 0) ) > 1000
)
SELECT 
    pa.cod_tipo_propiedad AS "CODIGO_TIPO",
    CASE pa.cod_tipo_propiedad
        WHEN 'A' THEN 'CASA'
        WHEN 'B' THEN 'DEPARTAMENTO' 
        WHEN 'C' THEN 'LOCAL'
        WHEN 'D' THEN 'PARCELA SIN CASA'
        WHEN 'E' THEN 'PARCELA CON CASA'
        ELSE 'Tipo ' || pa.cod_tipo_propiedad
    END                                   AS "DESCRIPCION_TIPO",
    pa.total_propiedades                  AS "TOTAL_PROPIEDADES",
    TO_CHAR(pa.promedio_arriendo,  'FM$999G999G999')  AS "PROMEDIO_ARRIENDO",
    TO_CHAR(pa.promedio_superficie,'FM999G999G999')   AS "PROMEDIO_SUPERFICIE",
    TO_CHAR(pa.valor_arriendo_m2, 'FM$999G999G999')   AS "VALOR_ARRIENDO_M2",
    CASE 
        WHEN pa.valor_arriendo_m2 < 5000 THEN 'Economico'
        WHEN pa.valor_arriendo_m2 BETWEEN 5000 AND 10000 THEN 'Medio'
        ELSE 'Alto'
    END                                   AS "CLASIFICACION"
FROM propiedades_agrupadas pa
ORDER BY pa.valor_arriendo_m2 DESC;
/**
Fin de actividad
**/

-- Formato de salida
SET PAGESIZE 200
SET LINESIZE 200
SET NUMFORMAT 999G999G999
COLUMN "RUT Cliente"            HEADING 'RUT'
COLUMN "Nombre Completo Cliente" HEADING 'NOMBRE COMPLETO'
COLUMN "Direccion Cliente"       HEADING 'DIRECCION (SIN ESPACIOS)'
COLUMN "Renta Cliente"           HEADING 'RENTA ($)'
COLUMN "Celular Cliente"         HEADING 'CELULAR'
COLUMN "Tramo Renta Cliente"     HEADING 'TRAMO'
COLUMN "SUELDO_PROMEDIO"         HEADING 'SUELDO PROM. ($)'
COLUMN "PROMEDIO_ARRIENDO"       HEADING 'ARREND. PROM. ($)'
COLUMN "PROMEDIO_SUPERFICIE"     HEADING 'SUP. PROM. (m2)'
COLUMN "VALOR_ARRIENDO_M2"       HEADING '$/m2 PROM.'

-- Parámetros por defecto 
DEFINE RENTA_MINIMA = 0
DEFINE RENTA_MAXIMA = 10000000
DEFINE SUELDO_PROMEDIO_MINIMO = 0
