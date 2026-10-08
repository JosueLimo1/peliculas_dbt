{{ config(materialized='table') }}
with largo as (
    select pelicula_id, anio, genero
    from {{ ref('stg_peliculas') }},
    lateral (values
        ('Acción', g_accion), ('Aventura', g_aventura), ('Animación', g_animacion),
        ('Infantil', g_infantil), ('Comedia', g_comedia), ('Crimen', g_crimen),
        ('Documental', g_documental), ('Drama', g_drama), ('Fantasía', g_fantasia),
        ('Film-Noir', g_film_noir), ('Terror', g_terror), ('Musical', g_musical),
        ('Misterio', g_misterio), ('Romance', g_romance), ('Ciencia ficción', g_ciencia_ficcion),
        ('Thriller', g_thriller), ('Bélica', g_belica), ('Western', g_western)
    ) as v(genero, flag)
    where flag = 1
)
select genero, count(*) as cantidad_peliculas, min(anio) as primer_anio, max(anio) as ultimo_anio
from largo
group by genero
order by cantidad_peliculas desc
