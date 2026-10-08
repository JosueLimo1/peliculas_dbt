# peliculas_dbt

Proyecto dbt sobre el dataset de películas (MovieLens, 1344 películas, 19 géneros).

## Levantar en una máquina nueva
```bash
docker compose up -d
python3 -m venv .venv && source .venv/bin/activate
pip install dbt-core dbt-postgres
dbt debug      # verifica la conexión
dbt seed       # carga seeds/peliculas.csv
dbt run        # crea stg_peliculas y los marts
dbt test
```

## Modelos
- stg_peliculas: nombres limpios, año y década
- peliculas_por_genero, peliculas_por_decada
