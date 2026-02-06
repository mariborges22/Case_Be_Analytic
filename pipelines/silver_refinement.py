"""
Silver Refinement Pipeline - Camada Prata
Limpeza, deduplicação e validação de dados do MCO.
"""

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import DateType, IntegerType, StringType, TimestampType


def refine_to_silver(
    spark: SparkSession,
    bronze_table: str,
    silver_table: str,
) -> None:
    """
    Refina dados da Bronze para Silver com limpeza e validação.

    Args:
        spark: SparkSession ativa
        bronze_table: Nome completo da tabela Bronze (catalog.schema.table)
        silver_table: Nome completo da tabela Silver
    """
    print(f"[SILVER] Iniciando refinamento: {bronze_table} -> {silver_table}")

    # Lê da Bronze
    df_bronze = spark.table(bronze_table)

    # Limpeza de dados
    df_clean = (
        df_bronze
        # Remove duplicatas por chave primária (ajustar conforme schema real)
        .dropDuplicates(["linha", "data", "hora"])
        # Remove registros com campos críticos nulos
        .filter(F.col("linha").isNotNull())
        .filter(F.col("data").isNotNull())
        # Cast de tipos (ajustar conforme schema real do MCO)
        .withColumn("data", F.to_date(F.col("data"), "yyyy-MM-dd"))
        .withColumn("passageiros", F.col("passageiros").cast(IntegerType()))
        # Normaliza strings
        .withColumn("linha", F.trim(F.upper(F.col("linha"))))
        # Adiciona timestamp de processamento
        .withColumn("_processed_at", F.current_timestamp())
    )

    # Validações de qualidade
    total_records = df_bronze.count()
    clean_records = df_clean.count()
    dropped_records = total_records - clean_records

    print(f"[SILVER] Registros originais: {total_records}")
    print(f"[SILVER] Registros limpos: {clean_records}")
    print(f"[SILVER] Registros descartados: {dropped_records}")

    # Salva como Delta Table
    df_clean.write.mode("overwrite").format("delta").option(
        "overwriteSchema", "true"
    ).saveAsTable(silver_table)

    print(f"[SILVER] ✓ Dados refinados salvos em {silver_table}")


if __name__ == "__main__":
    spark = SparkSession.builder.appName("MCO-Silver-Refinement").getOrCreate()

    BRONZE_TABLE = "sus_lakehouse.bronze.mco_raw"
    SILVER_TABLE = "sus_lakehouse.silver.mco_clean"

    refine_to_silver(spark, BRONZE_TABLE, SILVER_TABLE)
    spark.stop()
