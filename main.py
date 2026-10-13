import concurrent.futures
import time

import nbformat
from nbconvert.preprocessors import ExecutePreprocessor


def run_notebook(notebook_path: str):
    print(f"Démarrage : {notebook_path}")
    start = time.time()

    with open(notebook_path, encoding="utf-8") as f:
        nb = nbformat.read(f, as_version=4)

    ep = ExecutePreprocessor(kernel_name="python3")
    ep.preprocess(nb, {"metadata": {"path": "./"}})

    duration = round(time.time() - start, 2)
    print(f"Terminé : {notebook_path} ({duration}s)")


def run_pipeline():
    print("Début du pipeline ETL")

    run_notebook("delete_all.ipynb")

    dim_notebooks = [
        "populate_dim_magasin.ipynb",
        "populate_dim_product.ipynb",
    ]

    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [
            executor.submit(run_notebook, nb_path) for nb_path in dim_notebooks
        ]
        for future in concurrent.futures.as_completed(futures):
            future.result()

    run_notebook("populate_fait_vente.ipynb")


if __name__ == "__main__":
    run_pipeline()