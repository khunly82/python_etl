import asyncio
import json
import os
from datetime import date

import pandas as pd
from dotenv import load_dotenv
from httpx import AsyncClient

load_dotenv()

NOMINATIM_API_URL = "https://nominatim.openstreetmap.org/search"

async def get_address_infos(address: str, city: str):
    async with AsyncClient() as client:
        response = await client.get(NOMINATIM_API_URL, params={
            "street": address,
            "city": city,
            "country": "Belgium",
            "format": "jsonv2",
            "addressdetails": 1,
            "limit": 1
        }, headers={
            "User-Agent": "Khun"
        })
        if response.status_code != 200:
            print(
                f"Erreur API ({response.status_code}): {response.text[:200]}"
            )
            return None
        return next(iter(response.json()), None)


OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

OPENAI_MODEL = "gpt-4o-mini"

PRE_PROMPT = [{
    "role": "system",
    "content": """
        Tu es un assistant spécialiste de l'alimentation. 
        Tu ne sais d'ailleurs répondre qu'à ça!
        L'utilisateur va te donner le nom d'un produit.
        Tu devras lui donner 
        sa catégorie, 
        les allergènes 
        et s'il est vegan ou non (si tu n'es pas sûr répond faux)
    """
}]

# permet de s'assurer que la réponse soit bien formatée
JSON_SCHEMA = {
    "type": "object",
    "required": ["categorie", "allergenes", "est_vegan"],
    "properties": {
        "categorie": { "enum": ["Glaces", "Sorbets", "Gaufres & crêpes", "Boissons chaudes", "Boissons fraîches", "Milkshakes"] },
        "allergenes": { "type": "string" },
        "est_vegan": { "type": "boolean" }
    }
}

async def get_product_infos(product_name: str):
    async with AsyncClient() as client:
        response = await client.post(OPENAI_API_URL, json={
            "model": OPENAI_MODEL,
            "messages": [
                *PRE_PROMPT,
                { "role": "user", "content": product_name }
            ],
            "response_format": {
            "type": "json_schema",
            "json_schema": {
                "name": "product_extra_fields",
                "schema": JSON_SCHEMA
            }
        }
        }, headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {OPENAI_API_KEY}"
        })

        if response.status_code != 200:
            print(
                f"Erreur API ({response.status_code}): {response.text[:200]}"
            )
            return None
        
        choice = next(iter(response.json().get('choices')))
        data = json.loads(choice.get('message').get('content'))
        return data


METEO_API = "https://archive-api.open-meteo.com/v1/archive"


async def get_meteo_magasin(
    client: AsyncClient,
    magasin_key: int,
    lat: float,
    lon: float,
    start_date: date,
    end_date: date,
):
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date.isoformat(),
        "end_date": end_date.isoformat(),
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_sum",
        "timezone": "Europe/Brussels",
    }
    response = await client.get(METEO_API, params=params)

    if response.status_code != 200:
        print(f"Erreur API ({response.status_code}): {response.text[:200]}")
        return None

    data = response.json()
    daily = data.get("daily", {})

    times = daily.get("time", [])
    temp_maxs = daily.get("temperature_2m_max", [])
    temp_mins = daily.get("temperature_2m_min", [])
    precipitations = daily.get("precipitation_sum", [])

    records = []
    for t, t_max, t_min, prec in zip(
        times, temp_maxs, temp_mins, precipitations
    ):
        records.append({
            "magasin_key": magasin_key,
            "date_complete": date.fromisoformat(t),
            "temp_max": t_max,
            "temp_min": t_min,
            "precipitation_mm": prec,
        })

    return records


async def get_all_meteo(
    df_magasins: pd.DataFrame, start_date: date, end_date: date
):
    flat_results = []
    async with AsyncClient() as client:
        for row in df_magasins.itertuples():
            # Vérification de la présence des coordonnées
            if pd.isna(row.latitude) or pd.isna(row.longitude):
                continue

            res = await get_meteo_magasin(
                client,
                row.magasin_key,
                row.latitude,
                row.longitude,
                start_date,
                end_date,
            )

            if res:
                flat_results.extend(res)

            await asyncio.sleep(0.2)
    return flat_results