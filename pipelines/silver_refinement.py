"""
Silver Refinement Pipeline - Camada Prata.

Limpeza, deduplicação e validação de dados do MCO.
Implementa tratamento de nulos, normalização de tipos e validações de qualidade.
"""

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import DateType, IntegerType, StringType


def refine_to_silver(
    spark: SparkSession,
    bronze_table: str = "mco_catalog.bronze.mco_raw",
    silver_table: str = "mco_catalog.silver.mco_clean",
) -> None:
    """
    Refina dados da Bronze para Silver com limpeza e validação.

    Transformações aplicadas:
    - Remove duplicatas por chave primária (LINHA, DATA, HORA)
    - Remove registros com campos críticos nulos
    - Trata nulos em QTDE_PASSAGEIROS (filtra registros inválidos)
    - Normaliza tipos de dados (datas, inteiros, strings)
    - Adiciona timestamp de processamento

    Args:
        spark: SparkSession ativa do Databricks
        bronze_table: Nome completo da tabela Bronze (catalog.schema.table)
        silver_table: Nome completo da tabela Silver (catalog.schema.table)
    """
    print(f"[SILVER] Iniciando refinamento: {bronze_table} -> {silver_table}")

    # Lê da Bronze
    df_bronze = spark.table(bronze_table)

    # Mostra schema original para debug
    print(f"[SILVER] Schema Bronze: {df_bronze.columns}")
    initial_count = df_bronze.count()
    print(f"[SILVER] Registros originais: {initial_count}")

    # Normaliza nomes de colunas (uppercase para padronização)
    # O MCO pode ter variações: LINHA/Linha, QTDE_PASSAGEIROS/Qtde_Passageiros
    df_normalized = df_bronze.select(
        [F.col(c).alias(c.upper()) for c in df_bronze.columns]
    )

    # Limpeza de dados
    df_clean = (
        df_normalized
        # Remove duplicatas por chave primária
        # Ajuste conforme schema real: LINHA, DATA, HORA são campos típicos do MCO
        .dropDuplicates(
            ["LINHA", "DATA", "HORA"]
            if "HORA" in df_normalized.columns
            else ["LINHA", "DATA"]
        )
        # Remove registros com campos críticos nulos
        .filter(F.col("LINHA").isNotNull()).filter(F.col("DATA").isNotNull())
    )

    # Cast de tipos (CRITICAL: Fazer antes de filtros numéricos)
    df_typed = df_clean.withColumn(
        "DATA_DATE", F.to_date(F.col("DATA"), "yyyy-MM-dd")
    ).withColumn("QTDE_PASSAGEIROS_INT", F.col("QTDE_PASSAGEIROS").cast(IntegerType()))

    # Filtragem de Qualidade (usando colunas tipadas)
    df_valid = (
        df_typed.filter(
            F.col("QTDE_PASSAGEIROS_INT").isNotNull()
        )  # Remove não-numéricos
        .filter(F.col("QTDE_PASSAGEIROS_INT") >= 0)  # Remove negativos
        .drop("DATA", "QTDE_PASSAGEIROS")  # Remove colunas originais (strings)
        .withColumnRenamed("DATA_DATE", "DATA")
        .withColumnRenamed("QTDE_PASSAGEIROS_INT", "QTDE_PASSAGEIROS")
    )

    # Normaliza strings (trim e uppercase para consistência)
    # Ensure we only normalize columns that are currently Strings in df_valid
    string_columns = [
        field.name
        for field in df_valid.schema.fields
        if isinstance(field.dataType, StringType)
    ]

    for col_name in string_columns:
        df_valid = df_valid.withColumn(col_name, F.trim(F.upper(F.col(col_name))))

    # Adiciona timestamp de processamento
    df_silver = df_valid.withColumn("_processed_at", F.current_timestamp())

    # Validações de qualidade
    clean_count = df_silver.count()
    dropped_count = initial_count - clean_count
    drop_percentage = (dropped_count / initial_count * 100) if initial_count > 0 else 0

    print(f"[SILVER] Registros limpos: {clean_count}")
    print(f"[SILVER] Registros descartados: {dropped_count} ({drop_percentage:.2f}%)")

    # Alerta se muitos registros foram descartados
    if drop_percentage > 10:
        print(
            f"[SILVER] ⚠️  ALERTA: {drop_percentage:.2f}% dos registros "
            "foram descartados. Verifique qualidade dos dados."
        )

    # Salva como Delta Table
    df_silver.write.mode("overwrite").format("delta").option(
        "overwriteSchema", "true"
    ).option("delta.enableChangeDataFeed", "true").saveAsTable(silver_table)

    print(f"[SILVER] ✓ Dados refinados salvos em {silver_table}")
    print(f"[SILVER] ✓ Schema: {', '.join(df_silver.columns)}")


if __name__ == "__main__":
    spark = SparkSession.builder.appName("MCO-Silver-Refinement").getOrCreate()

    BRONZE_TABLE = "mco_catalog.bronze.mco_raw"
    SILVER_TABLE = "mco_catalog.silver.mco_clean"

    refine_to_silver(spark, BRONZE_TABLE, SILVER_TABLE)
    spark.stop()
