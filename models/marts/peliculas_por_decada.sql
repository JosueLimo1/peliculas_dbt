{{ config(materialized='table') }}
select decada, count(*) as cantidad_peliculas
from {{ ref('stg_peliculas') }}
where decada is not null
group by decada
order by decada
