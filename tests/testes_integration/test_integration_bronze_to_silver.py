"""
Testes de Integração: Bronze → Silver via Databricks Connect Serverless.
Usa databricks_spark fixture - execução real em cluster serverless.
"""
import pytest


@pytest.mark.integration
class TestBronzeToSilverIntegration:
    """Testes de integração da pipeline Bronze → Silver."""

    def test_spark_session_active(self, databricks_spark):
        """Valida conexão com cluster serverless."""
        assert databricks_spark is not None
        assert databricks_spark.version is not None

    def test_read_bronze_table(self, databricks_spark):
        """Valida leitura de tabela Bronze no catálogo."""
        # Ajuste catalog.schema.table para seu ambiente
        # df = databricks_spark.table("bronze.raw_events")
        # assert df.count() >= 0
        
        # Placeholder: valida operação básica
        df = databricks_spark.range(10)
        assert df.count() == 10

    def test_bronze_to_silver_transformation(self, databricks_spark):
        """Valida transformação completa Bronze → Silver."""
        # Arrange
        bronze_df = databricks_spark.createDataFrame(
            [(1, "test", "2024-01-01"), (2, "test", "2024-01-02")],
            ["id", "name", "date"]
        )
        
        # Act - substitua pela sua transformação real
        # from src.pipelines import bronze_to_silver
        # silver_df = bronze_to_silver(bronze_df)
        silver_df = bronze_df.dropDuplicates(["id"]).filter("id IS NOT NULL")
        
        # Assert
        assert silver_df.count() == 2
        assert "id" in silver_df.columns

    def test_schema_evolution_handling(self, databricks_spark):
        """Valida handling de schema evolution."""
        df1 = databricks_spark.createDataFrame([(1, "a")], ["id", "col_v1"])
        df2 = databricks_spark.createDataFrame([(2, "b", "new")], ["id", "col_v1", "col_v2"])
        
        # Merge schemas
        merged = df1.unionByName(df2, allowMissingColumns=True)
        
        assert "col_v2" in merged.columns
        assert merged.count() == 2


@pytest.mark.integration
class TestSilverToGoldIntegration:
    """Testes de integração da pipeline Silver → Gold."""

    def test_aggregation_performance(self, databricks_spark):
        """Valida agregações Gold com dados reais."""
        silver_df = databricks_spark.createDataFrame(
            [(1, "A", 100), (2, "A", 200), (3, "B", 150)],
            ["id", "category", "value"]
        )
        
        # Act
        gold_df = silver_df.groupBy("category").sum("value")
        
        # Assert
        assert gold_df.count() == 2
        result = {row["category"]: row["sum(value)"] for row in gold_df.collect()}
        assert result["A"] == 300
        assert result["B"] == 150
