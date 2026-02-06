"""
Gold Aggregations Pipeline - Camada Ouro
Agregações de negócio e modelagem Star Schema para MCO.
"""
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def create_gold_aggregates(
    spark: SparkSession,
    silver_table: str,
    gold_table: str,
) -> None:
    """
    Cria agregados de negócio na camada Gold com Star Schema.

    Args:
        spark: SparkSession ativa
        silver_table: Nome completo da tabela Silver
        gold_table: Nome completo da tabela Gold
    """
    print(f"[GOLD] Iniciando agregações: {silver_table} -> {gold_table}")

    # Lê da Silver
    df_silver = spark.table(silver_table)

    # Agregação: Total de passageiros por linha e dia
    df_gold = (
        df_silver.groupBy("linha", "data")
        .agg(
            F.sum("passageiros").alias("total_passageiros"),
            F.count("*").alias("total_viagens"),
            F.avg("passageiros").alias("media_passageiros_viagem"),
            F.min("passageiros").alias("min_passageiros"),
            F.max("passageiros").alias("max_passageiros"),
        )
        .withColumn("_aggregated_at", F.current_timestamp())
    )

    # Salva como Delta Table com otimizações
    (
        df_gold.write.mode("overwrite")
        .format("delta")
        .option("overwriteSchema", "true")
        .partitionBy("data")  # Particiona por data para queries temporais
        .saveAsTable(gold_table)
    )

    # Aplica Z-ORDER para otimizar queries por linha
    spark.sql(f"OPTIMIZE {gold_table} ZORDER BY (linha)")

    print(f"[GOLD] ✓ Agregados salvos em {gold_table}")
    print(f"[GOLD] ✓ Z-ORDER aplicado em 'linha'")


def create_star_schema_dimensions(
    spark: SparkSession,
    silver_table: str,
    catalog_name: str = "sus_lakehouse",
    schema_name: str = "gold",
) -> None:
    """
    Cria dimensões do Star Schema (opcional).

    Args:
        spark: SparkSession ativa
        silver_table: Tabela Silver fonte
        catalog_name: Nome do catálogo
        schema_name: Nome do schema Gold
    """
    df_silver = spark.table(silver_table)

    # Dimensão: dim_linha
    dim_linha = (
        df_silver.select("linha")
        .distinct()
        .withColumn("linha_id", F.monotonically_increasing_id())
    )

    dim_linha.write.mode("overwrite").format("delta").saveAsTable(
        f"{catalog_name}.{schema_name}.dim_linha"
    )

    # Dimensão: dim_data
    dim_data = (
        df_silver.select("data")
        .distinct()
        .withColumn("ano", F.year("data"))
        .withColumn("mes", F.month("data"))
        .withColumn("dia", F.dayofmonth("data"))
        .withColumn("dia_semana", F.dayofweek("data"))
    )

    dim_data.write.mode("overwrite").format("delta").saveAsTable(
        f"{catalog_name}.{schema_name}.dim_data"
    )

    print("[GOLD] ✓ Dimensões Star Schema criadas")


if __name__ == "__main__":
    spark = SparkSession.builder.appName("MCO-Gold-Aggregations").getOrCreate()

    SILVER_TABLE = "sus_lakehouse.silver.mco_clean"
    GOLD_TABLE = "sus_lakehouse.gold.mco_aggregates"

    create_gold_aggregates(spark, SILVER_TABLE, GOLD_TABLE)
    create_star_schema_dimensions(spark, SILVER_TABLE)

    spark.stop()
