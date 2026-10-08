-- una fila por (película, género): formato largo para consultas por género
select s.pelicula_id, s.titulo, s.anio, s.decada, v.genero
from {{ ref('stg_peliculas') }} s,
lateral (values
    ('Acción', s.g_accion), ('Aventura', s.g_aventura), ('Animación', s.g_animacion),
    ('Infantil', s.g_infantil), ('Comedia', s.g_comedia), ('Crimen', s.g_crimen),
    ('Documental', s.g_documental), ('Drama', s.g_drama), ('Fantasía', s.g_fantasia),
    ('Film-Noir', s.g_film_noir), ('Terror', s.g_terror), ('Musical', s.g_musical),
    ('Misterio', s.g_misterio), ('Romance', s.g_romance), ('Ciencia ficción', s.g_ciencia_ficcion),
    ('Thriller', s.g_thriller), ('Bélica', s.g_belica), ('Western', s.g_western)
) as v(genero, flag)
where v.flag = 1
