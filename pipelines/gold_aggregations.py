"""
Gold Aggregations Pipeline - Camada Ouro.

Agregações de negócio e modelagem Star Schema para MCO.
Implementa fact tables, dimension tables, e otimizações de performance.
"""

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def create_gold_aggregates(
    spark: SparkSession,
    silver_table: str = "mco_catalog.silver.mco_clean",
    gold_table: str = "mco_catalog.gold.fact_passageiros",
) -> None:
    """
    Cria agregados de negócio na camada Gold com Star Schema.

    Fact Table: fact_passageiros
    - Agregação: Total de passageiros por linha e dia
    - Métricas: total_passageiros, total_viagens, média, min, max
    - Otimizações: Particionamento por DATA, ZORDER BY LINHA

    Args:
        spark: SparkSession ativa do Databricks
        silver_table: Nome completo da tabela Silver (catalog.schema.table)
        gold_table: Nome completo da tabela Gold (catalog.schema.table)
    """
    print(f"[GOLD] Iniciando agregações: {silver_table} -> {gold_table}")

    # Lê da Silver
    df_silver = spark.table(silver_table)

    print(f"[GOLD] Registros Silver: {df_silver.count()}")

    # Agregação: Total de passageiros por linha e dia
    df_gold = (
        df_silver.groupBy("LINHA", "DATA")
        .agg(
            F.sum("QTDE_PASSAGEIROS").alias("total_passageiros"),
            F.count("*").alias("total_viagens"),
            F.avg("QTDE_PASSAGEIROS").alias("media_passageiros_viagem"),
            F.min("QTDE_PASSAGEIROS").alias("min_passageiros"),
            F.max("QTDE_PASSAGEIROS").alias("max_passageiros"),
        )
        .withColumn("_aggregated_at", F.current_timestamp())
    )

    print(f"[GOLD] Registros agregados: {df_gold.count()}")

    # Salva como Delta Table com otimizações
    (
        df_gold.write.mode("overwrite")
        .format("delta")
        .option("overwriteSchema", "true")
        .option("delta.enableChangeDataFeed", "true")
        .partitionBy("DATA")  # Particiona por data para queries temporais
        .saveAsTable(gold_table)
    )

    print(f"[GOLD] ✓ Fact table salva em {gold_table}")
    print(f"[GOLD] ✓ Particionamento aplicado: DATA")

    # Aplica Z-ORDER para otimizar queries por linha
    print("[GOLD] Aplicando ZORDER BY LINHA...")
    spark.sql(f"OPTIMIZE {gold_table} ZORDER BY (LINHA)")

    print(f"[GOLD] ✓ ZORDER aplicado em 'LINHA'")


def create_star_schema_dimensions(
    spark: SparkSession,
    silver_table: str = "mco_catalog.silver.mco_clean",
    catalog_name: str = "mco_catalog",
    schema_name: str = "gold",
) -> None:
    """
    Cria dimensões do Star Schema para análise dimensional.

    Dimensões criadas:
    - dim_linha: Informações sobre linhas de transporte
    - dim_data: Calendário com hierarquias temporais (ano, mês, dia, dia_semana)

    Args:
        spark: SparkSession ativa do Databricks
        silver_table: Tabela Silver fonte (catalog.schema.table)
        catalog_name: Nome do catálogo Unity Catalog
        schema_name: Nome do schema Gold
    """
    print("[GOLD] Criando dimensões do Star Schema...")

    df_silver = spark.table(silver_table)

    # Dimensão: dim_linha
    print("[GOLD] Criando dim_linha...")
    dim_linha = (
        df_silver.select("LINHA")
        .distinct()
        .withColumn("linha_id", F.monotonically_increasing_id())
        .withColumn("linha_codigo", F.col("LINHA"))
        .withColumn("_created_at", F.current_timestamp())
    )

    dim_linha_table = f"{catalog_name}.{schema_name}.dim_linha"
    dim_linha.write.mode("overwrite").format("delta").option(
        "overwriteSchema", "true"
    ).saveAsTable(dim_linha_table)

    print(f"[GOLD] ✓ dim_linha criada: {dim_linha.count()} linhas únicas")

    # Dimensão: dim_data (calendário)
    print("[GOLD] Criando dim_data...")
    dim_data = (
        df_silver.select("DATA")
        .distinct()
        .withColumn("data_id", F.monotonically_increasing_id())
        .withColumn("ano", F.year("DATA"))
        .withColumn("mes", F.month("DATA"))
        .withColumn("dia", F.dayofmonth("DATA"))
        .withColumn("dia_semana", F.dayofweek("DATA"))
        .withColumn("nome_dia_semana", F.date_format("DATA", "EEEE"))
        .withColumn("trimestre", F.quarter("DATA"))
        .withColumn("semana_ano", F.weekofyear("DATA"))
        .withColumn("_created_at", F.current_timestamp())
    )

    dim_data_table = f"{catalog_name}.{schema_name}.dim_data"
    dim_data.write.mode("overwrite").format("delta").option(
        "overwriteSchema", "true"
    ).saveAsTable(dim_data_table)

    print(f"[GOLD] ✓ dim_data criada: {dim_data.count()} datas únicas")
    print("[GOLD] ✓ Dimensões Star Schema criadas com sucesso")


if __name__ == "__main__":
    spark = SparkSession.builder.appName("MCO-Gold-Aggregations").getOrCreate()

    SILVER_TABLE = "mco_catalog.silver.mco_clean"
    GOLD_TABLE = "mco_catalog.gold.fact_passageiros"

    # Cria fact table com agregações
    create_gold_aggregates(spark, SILVER_TABLE, GOLD_TABLE)

    # Cria dimension tables
    create_star_schema_dimensions(spark, SILVER_TABLE)

    spark.stop()

