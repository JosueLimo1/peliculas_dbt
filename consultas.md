# Consultas posibles sobre el dataset de películas

Dataset: 1344 películas (MovieLens). Columnas: título, fecha de estreno, URL de IMDb y 19 flags de género (0/1).
No tiene ratings, directores ni actores, por lo que las consultas giran alrededor de **géneros, fechas y títulos**.

Todas las consultas corren sobre los modelos dbt:

- `stg_peliculas`: una fila por película, con `titulo`, `anio`, `decada`, `n_generos` y un flag `g_*` por género.
- `peliculas_genero`: una fila por (película, género).
- `peliculas_por_genero` y `peliculas_por_decada`: agregaciones ya calculadas.

## 1. Conteos y agrupaciones

**1. Cantidad de películas por género**
```sql
select * from peliculas_por_genero;
```

**2. Cantidad de películas por década**
```sql
select * from peliculas_por_decada;
```

**3. Cantidad de películas por año**
```sql
select anio, count(*) as peliculas
from stg_peliculas
where anio is not null
group by anio
order by anio;
```

**4. Año con más estrenos**
```sql
select anio, count(*) as peliculas
from stg_peliculas
where anio is not null
group by anio
order by peliculas desc
limit 1;
```

**5. Mes del año con más estrenos**
```sql
select extract(month from fecha_estreno)::int as mes, count(*) as peliculas
from stg_peliculas
where fecha_estreno is not null
group by mes
order by peliculas desc;
```

**6. Películas de una década puntual (los 80)**
```sql
select titulo, fecha_estreno
from stg_peliculas
where decada = 1980
order by fecha_estreno;
```

## 2. Combinaciones de géneros

**7. Películas con más géneros**
```sql
select titulo, anio, n_generos
from stg_peliculas
order by n_generos desc, titulo
limit 10;
```

**8. Películas de Acción y Ciencia ficción a la vez**
```sql
select titulo, anio
from stg_peliculas
where g_accion = 1 and g_ciencia_ficcion = 1
order by anio;
```

**9. Pares de géneros que más se combinan**
```sql
select a.genero as genero_1, b.genero as genero_2, count(*) as peliculas
from peliculas_genero a
join peliculas_genero b
  on a.pelicula_id = b.pelicula_id and a.genero < b.genero
group by a.genero, b.genero
order by peliculas desc
limit 10;
```

**10. Promedio de géneros por película, según género (cuáles se mezclan más)**
```sql
select g.genero, round(avg(s.n_generos), 2) as generos_promedio
from peliculas_genero g
join stg_peliculas s using (pelicula_id)
group by g.genero
order by generos_promedio desc;
```

**11. Películas de un solo género contra multi-género**
```sql
select case when n_generos = 1 then 'un género' else 'varios géneros' end as tipo,
       count(*) as peliculas
from stg_peliculas
group by tipo;
```

## 3. Evolución temporal (funciones de ventana)

**12. Género más frecuente de cada década (`RANK`)**
```sql
with conteo as (
    select decada, genero, count(*) as peliculas
    from peliculas_genero
    where decada is not null
    group by decada, genero
)
select decada, genero, peliculas
from (
    select *, rank() over (partition by decada order by peliculas desc) as pos
    from conteo
) t
where pos = 1
order by decada;
```

**13. Variación de estrenos año contra año (`LAG`)**
```sql
select anio,
       count(*) as peliculas,
       count(*) - lag(count(*)) over (order by anio) as variacion
from stg_peliculas
where anio is not null
group by anio
order by anio;
```

**14. Porcentaje de cada género dentro de cada década**
```sql
select decada, genero, count(*) as peliculas,
       round(100.0 * count(*) / sum(count(*)) over (partition by decada), 1) as porcentaje
from peliculas_genero
where decada is not null
group by decada, genero
order by decada, porcentaje desc;
```

**15. Primer y último año en que aparece cada género**
```sql
select genero, min(anio) as primer_anio, max(anio) as ultimo_anio
from peliculas_genero
group by genero
order by primer_anio;
```

**16. Acumulado de películas por año (`SUM OVER`)**
```sql
select anio,
       count(*) as peliculas,
       sum(count(*)) over (order by anio) as acumulado
from stg_peliculas
where anio is not null
group by anio
order by anio;
```

## 4. Texto y URLs

**17. Películas cuyo título contiene una palabra**
```sql
select titulo, anio
from stg_peliculas
where titulo ilike '%war%'
order by anio;
```

**18. Títulos más largos**
```sql
select titulo, length(titulo) as caracteres
from stg_peliculas
order by caracteres desc
limit 5;
```

**19. Posibles secuelas o títulos con subtítulo**
```sql
select titulo, anio
from stg_peliculas
where titulo ~ '( II| III| IV| 2| 3|:)'
order by titulo;
```

**20. Títulos que empiezan con "The"** (en el dataset figuran como `"..., The"`)
```sql
select titulo
from stg_peliculas
where titulo ilike '%, The'
order by titulo
limit 20;
```

## 5. Calidad de datos

**21. Títulos duplicados**
```sql
select titulo_completo, count(*) as veces
from stg_peliculas
group by titulo_completo
having count(*) > 1
order by veces desc, titulo_completo;
```

**22. Películas sin fecha de estreno**
```sql
select pelicula_id, titulo_completo
from stg_peliculas
where fecha_estreno is null;
```

**23. Películas con género "unknown"**
```sql
select pelicula_id, titulo_completo
from stg_peliculas
where g_desconocido = 1;
```

**24. Películas sin ningún género asignado**
```sql
select pelicula_id, titulo_completo
from stg_peliculas
where n_generos = 0;
```

**25. Fechas fuera de rango**
```sql
select pelicula_id, titulo_completo, fecha_estreno
from stg_peliculas
where fecha_estreno < date '1900-01-01' or fecha_estreno > current_date;
```

## 6. Qué aporta dbt

**26. Capas del proyecto:** `seeds/peliculas.csv` → `stg_peliculas` (limpieza y renombrado) → `marts` (agregaciones).

**27. Tests declarativos** en `models/schema.yml`: `unique` y `not_null` sobre `pelicula_id` y `titulo`.

**28. Test propio** `tests/titulos_duplicados.sql`: con `severity: warn`, avisa de los 10 títulos duplicados sin romper el pipeline.

**29. Documentación y linaje:**
```bash
dbt docs generate && dbt docs serve
```
