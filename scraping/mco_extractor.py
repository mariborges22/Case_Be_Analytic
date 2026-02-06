"""
MCO Extractor - Bronze Layer
Extrai dados do MCO (Mobilidade e Cidadania Operacional) de Belo Horizonte.
"""
from datetime import datetime
from pathlib import Path

import requests
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def extract_mco_data(
    spark: SparkSession,
    source_url: str,
    output_path: str,
    catalog_name: str = "sus_lakehouse",
    schema_name: str = "bronze",
) -> None:
    """
    Extrai dados do MCO via HTTP e salva como Parquet na camada Bronze.

    Args:
        spark: SparkSession ativa
        source_url: URL do CSV no portal da PBH
        output_path: Caminho de saída para Parquet
        catalog_name: Nome do catálogo Unity Catalog
        schema_name: Nome do schema Bronze
    """
    print(f"[BRONZE] Iniciando extração de {source_url}")

    # Download do CSV
    response = requests.get(source_url, timeout=60)
    response.raise_for_status()

    # Salva temporariamente
    temp_csv = Path("/tmp/mco_raw.csv")
    temp_csv.write_bytes(response.content)

    # Lê CSV com Spark
    df = spark.read.option("header", "true").option("inferSchema", "true").csv(
        str(temp_csv)
    )

    # Adiciona metadados de ingestão
    df_bronze = df.withColumn(
        "_ingestion_timestamp", F.lit(datetime.now().isoformat())
    ).withColumn("_source_url", F.lit(source_url))

    # Salva como Parquet
    df_bronze.write.mode("overwrite").parquet(output_path)

    # Registra como tabela Delta (opcional)
    table_name = f"{catalog_name}.{schema_name}.mco_raw"
    df_bronze.write.mode("overwrite").format("delta").saveAsTable(table_name)

    print(f"[BRONZE] ✓ {df_bronze.count()} registros salvos em {table_name}")


if __name__ == "__main__":
    # Configuração local para testes
    spark = SparkSession.builder.appName("MCO-Bronze-Extractor").getOrCreate()

    MCO_URL = "https://dados.pbh.gov.br/dataset/mco/resource/mco.csv"
    OUTPUT_PATH = "/dbfs/mnt/bronze/mco/"

    extract_mco_data(spark, MCO_URL, OUTPUT_PATH)
    spark.stop()
