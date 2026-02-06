"""
Testes de Integração: Bronze → Silver → Gold via Databricks Connect Serverless.

Usa databricks_spark fixture - execução real em cluster serverless.
Requer variáveis de ambiente: DATABRICKS_HOST, DATABRICKS_CLIENT_ID, DATABRICKS_CLIENT_SECRET
"""

import pytest


@pytest.mark.integration
class TestBronzeToSilverIntegration:
    """Testes de integração da pipeline Bronze → Silver."""

    def test_databricks_spark_session_active(self, databricks_spark):
        """Valida conexão com cluster serverless."""
        assert databricks_spark is not None
        assert databricks_spark.version is not None
        print(f"[TEST] Conectado ao Databricks: Spark {databricks_spark.version}")

    def test_basic_dataframe_operations(self, databricks_spark):
        """Valida operações básicas de DataFrame no Databricks."""
        df = databricks_spark.range(10)
        assert df.count() == 10
        print("[TEST] ✓ Operações básicas de DataFrame funcionando")

    def test_bronze_to_silver_transformation(self, databricks_spark):
        """Valida transformação completa Bronze → Silver com schema MCO."""
        # Arrange: Simula dados Bronze
        bronze_data = [
            ("LINHA-001", "2025-09-01", "08:00:00", 45, "2025-09-01T08:00:00", "https://example.com/mco.csv"),
            ("LINHA-001", "2025-09-01", "08:00:00", 45, "2025-09-01T08:00:00", "https://example.com/mco.csv"),  # Duplicata
            ("LINHA-002", "2025-09-01", "09:00:00", None, "2025-09-01T09:00:00", "https://example.com/mco.csv"),  # Null
            ("LINHA-003", "2025-09-01", "10:00:00", 52, "2025-09-01T10:00:00", "https://example.com/mco.csv"),
        ]
        schema = ["LINHA", "DATA", "HORA", "QTDE_PASSAGEIROS", "_ingestion_timestamp", "_source_url"]
        bronze_df = databricks_spark.createDataFrame(bronze_data, schema)

        # Act: Aplica transformações Silver
        from pyspark.sql import functions as F
        from pyspark.sql.types import IntegerType

        silver_df = (
            bronze_df.dropDuplicates(["LINHA", "DATA", "HORA"])
            .filter(F.col("LINHA").isNotNull())
            .filter(F.col("DATA").isNotNull())
            .filter(F.col("QTDE_PASSAGEIROS").isNotNull())
            .filter(F.col("QTDE_PASSAGEIROS") >= 0)
            .withColumn("QTDE_PASSAGEIROS", F.col("QTDE_PASSAGEIROS").cast(IntegerType()))
            .withColumn("_processed_at", F.current_timestamp())
        )

        # Assert
        assert silver_df.count() == 2  # 1 duplicata + 1 null removidos
        assert "QTDE_PASSAGEIROS" in silver_df.columns
        assert "_processed_at" in silver_df.columns
        print(f"[TEST] ✓ Bronze → Silver: {silver_df.count()} registros válidos")

    def test_schema_evolution_handling(self, databricks_spark):
        """Valida handling de schema evolution."""
        df1 = databricks_spark.createDataFrame([(1, "a")], ["id", "col_v1"])
        df2 = databricks_spark.createDataFrame(
            [(2, "b", "new")], ["id", "col_v1", "col_v2"]
        )

        # Merge schemas
        merged = df1.unionByName(df2, allowMissingColumns=True)

        assert "col_v2" in merged.columns
        assert merged.count() == 2
        print("[TEST] ✓ Schema evolution suportado")


@pytest.mark.integration
class TestSilverToGoldIntegration:
    """Testes de integração da pipeline Silver → Gold."""

    def test_aggregation_performance(self, databricks_spark):
        """Valida agregações Gold com dados MCO."""
        # Arrange: Simula dados Silver
        silver_data = [
            ("LINHA-001", "2025-09-01", 45),
            ("LINHA-001", "2025-09-01", 52),
            ("LINHA-002", "2025-09-01", 38),
            ("LINHA-001", "2025-09-02", 60),
        ]
        schema = ["LINHA", "DATA", "QTDE_PASSAGEIROS"]
        silver_df = databricks_spark.createDataFrame(silver_data, schema)

        # Act: Cria agregações Gold
        from pyspark.sql import functions as F

        gold_df = silver_df.groupBy("LINHA", "DATA").agg(
            F.sum("QTDE_PASSAGEIROS").alias("total_passageiros"),
            F.count("*").alias("total_viagens"),
            F.avg("QTDE_PASSAGEIROS").alias("media_passageiros_viagem"),
        )

        # Assert
        assert gold_df.count() == 3  # 2 linhas únicas x datas
        result = {
            (row["LINHA"], row["DATA"]): row["total_passageiros"]
            for row in gold_df.collect()
        }
        assert result[("LINHA-001", "2025-09-01")] == 97  # 45 + 52
        assert result[("LINHA-002", "2025-09-01")] == 38
        assert result[("LINHA-001", "2025-09-02")] == 60
        print(f"[TEST] ✓ Silver → Gold: {gold_df.count()} agregações criadas")

