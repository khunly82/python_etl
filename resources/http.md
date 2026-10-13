# Prerequis

Le package «requests» permet de se connecter à une api web,

L'inconvénient est que ce package ne gère pas les connections asynchrones

La solution -> utiliser le package httpx

- avec requests

```python
import requests 

url = "https://pokeapi.co/api/v2/pokemon/25"
response = requests.get(url)
data = response.json()
print(data)
```


- avec httpx

```python
from httpx import AsyncClient 

url = "https://pokeapi.co/api/v2/pokemon/25"
async with AsyncClient as client:
    response = await client.get(url)
    data = response.json()
    print(data)
```

- avec httpx (multi requetes)

```python
from httpx import AsyncClient
import asyncio

async with AsyncClient as client:
    responses = await asyncio.gather(
        client.get("https://pokeapi.co/api/v2/pokemon/25"),
        client.get("https://pokeapi.co/api/v2/pokemon/1"),
        client.get("https://pokeapi.co/api/v2/pokemon/100"),
    )
    for response in responses:
        data = response.json()
        print(data)
```