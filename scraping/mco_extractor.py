"""
MCO Extractor - Bronze Layer.

Extrai dados do MCO (Mobilidade e Cidadania Operacional) de Belo Horizonte
e salva na camada Bronze como Delta Table com metadados de ingestão.
"""

from datetime import datetime
from pathlib import Path

import requests
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def extract_mco_data(
    spark: SparkSession,
    source_url: str,
    catalog_name: str = "mco_catalog",
    schema_name: str = "bronze",
    table_name: str = "mco_raw",
) -> None:
    """
    Extrai dados do MCO via HTTP e salva como Delta Table na camada Bronze.

    Args:
        spark: SparkSession ativa do Databricks
        source_url: URL do CSV no portal CKAN da PBH
        catalog_name: Nome do catálogo Unity Catalog (default: mco_catalog)
        schema_name: Nome do schema Bronze (default: bronze)
        table_name: Nome da tabela de destino (default: mco_raw)

    Raises:
        requests.HTTPError: Se o download do CSV falhar
        ValueError: Se o CSV estiver vazio ou inválido
    """
    print(f"[BRONZE] Iniciando extração de {source_url}")

    try:
        # Download do CSV com timeout e retry
        response = requests.get(source_url, timeout=120)
        response.raise_for_status()

        if len(response.content) == 0:
            raise ValueError("CSV baixado está vazio")

        # Salva temporariamente no DBFS
        temp_csv = Path("/tmp/mco_raw.csv")
        temp_csv.write_bytes(response.content)
        print(f"[BRONZE] CSV baixado: {len(response.content)} bytes")

    except requests.exceptions.RequestException as e:
        print(f"[BRONZE] ✗ Erro ao baixar CSV: {e}")
        raise

    # Lê CSV com Spark (inferSchema para detectar tipos automaticamente)
    df = (
        spark.read.option("header", "true")
        .option("inferSchema", "true")
        .option("encoding", "UTF-8")
        .option("sep", ",")
        .csv(str(temp_csv))
    )

    # Valida que o DataFrame não está vazio
    if df.count() == 0:
        raise ValueError("CSV não contém dados após leitura")

    print(f"[BRONZE] Registros lidos: {df.count()}")
    print(f"[BRONZE] Colunas: {', '.join(df.columns)}")

    # Adiciona metadados de ingestão
    df_bronze = (
        df.withColumn("_ingestion_timestamp", F.current_timestamp())
        .withColumn("_source_url", F.lit(source_url))
        .withColumn("_ingestion_date", F.current_date())
    )

    # Salva como Delta Table (formato nativo do Databricks)
    full_table_name = f"{catalog_name}.{schema_name}.{table_name}"

    df_bronze.write.mode("overwrite").format("delta").option(
        "overwriteSchema", "true"
    ).option("delta.enableChangeDataFeed", "true").saveAsTable(full_table_name)

    record_count = df_bronze.count()
    print(f"[BRONZE] ✓ {record_count} registros salvos em {full_table_name}")
    print(f"[BRONZE] ✓ Delta Table criada com CDC habilitado")


if __name__ == "__main__":
    # Configuração local para testes
    spark = SparkSession.builder.appName("MCO-Bronze-Extractor").getOrCreate()

    # URL oficial do MCO - Setembro 2025
    MCO_URL = (
        "https://ckan.pbh.gov.br/dataset/"
        "7ae4d4b4-6b52-4042-b021-0935a1db3814/resource/"
        "123b7a8a-ceb1-4f8c-9ec6-9ce76cdf9aab/download/mco-09-2025.csv"
    )

    extract_mco_data(spark, MCO_URL)
    spark.stop()

