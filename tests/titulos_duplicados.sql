{{ config(severity='warn') }}
-- devuelve filas si hay títulos repetidos (el dataset trae algunos duplicados)
select titulo_completo, count(*) as veces
from {{ ref('stg_peliculas') }}
group by titulo_completo
having count(*) > 1
