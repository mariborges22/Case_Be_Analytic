"""
Configuração global de fixtures Pytest para testes Databricks.
- mock_spark: Spark mockado para testes unitários (sem I/O real).
- databricks_spark: SparkSession real via Databricks Connect Serverless.
"""
from unittest.mock import MagicMock
import pytest

@pytest.fixture(scope="function")
def mock_spark():
    """
    Fixture: SparkSession mockado para testes unitários.
    Substitui todas as operações Spark sem execução real.
    """
    spark = MagicMock()
    spark.read = MagicMock()
    spark.write = MagicMock()
    spark.sql = MagicMock(return_value=MagicMock())
    spark.createDataFrame = MagicMock()
    return spark


@pytest.fixture(scope="session")
def databricks_spark():
    """
    Fixture: SparkSession real via Databricks Connect Serverless.
    Usada somente em testes de integração (tests_integration/).
    Requer: databricks-connect configurado e cluster serverless disponível.
    """
    from databricks.connect import DatabricksSession

    spark = DatabricksSession.builder.serverless().getOrCreate()
    yield spark
    spark.stop()
