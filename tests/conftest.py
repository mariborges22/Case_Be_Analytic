"""
Pytest Configuration and Fixtures.

Provides fixtures for unit tests (mock_spark) and integration tests (databricks_spark).
"""

import os
import sys
from pathlib import Path
from unittest.mock import MagicMock

import pytest
from pyspark.sql import SparkSession

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


@pytest.fixture(scope="function")
def mock_spark():
    """
    Fixture: SparkSession mockado para testes unitários.

    Substitui todas as operações Spark sem execução real.
    Use para testes de lógica pura sem dependências externas.
    """
    spark = MagicMock()
    spark.read = MagicMock()
    spark.write = MagicMock()
    spark.sql = MagicMock(return_value=MagicMock())
    spark.createDataFrame = MagicMock()
    spark.table = MagicMock(return_value=MagicMock())
    return spark


@pytest.fixture(scope="session")
def spark():
    """
    Fixture: SparkSession local para testes unitários.

    Cria uma sessão Spark local para testes que precisam de execução real
    mas não requerem conexão com Databricks.
    """
    spark = (
        SparkSession.builder.appName("mco-pipeline-tests")
        .master("local[2]")
        .config("spark.sql.shuffle.partitions", "2")
        .config("spark.default.parallelism", "2")
        .config("spark.sql.adaptive.enabled", "false")
        .config("spark.ui.enabled", "false")
        .getOrCreate()
    )
    yield spark
    spark.stop()


@pytest.fixture(scope="session")
def databricks_spark():
    """
    Fixture: Databricks Connect Serverless para testes de integração.

    Conecta ao cluster Serverless do Databricks usando Service Principal OAuth.
    Requer variáveis de ambiente:
    - DATABRICKS_HOST
    - DATABRICKS_CLIENT_ID
    - DATABRICKS_CLIENT_SECRET

    Raises:
        ImportError: Se databricks-connect não estiver instalado
        ValueError: Se variáveis de ambiente não estiverem configuradas
    """
    try:
        from databricks.connect import DatabricksSession
    except ImportError:
        pytest.skip(
            "databricks-connect não instalado. "
            "Instale com: pip install databricks-connect"
        )

    # Valida variáveis de ambiente
    required_vars = ["DATABRICKS_HOST", "DATABRICKS_CLIENT_ID", "DATABRICKS_CLIENT_SECRET"]
    missing_vars = [var for var in required_vars if not os.getenv(var)]

    if missing_vars:
        pytest.skip(
            f"Variáveis de ambiente não configuradas: {', '.join(missing_vars)}. "
            "Configure as credenciais do Service Principal para testes de integração."
        )

    # Cria sessão Databricks Serverless
    spark = DatabricksSession.builder.serverless().getOrCreate()

    yield spark

    spark.stop()


@pytest.fixture(scope="function")
def sample_bronze_data(spark):
    """
    Fixture: Dados de exemplo da camada Bronze.

    Simula dados MCO brutos para testes.
    """
    data = [
        ("LINHA-001", "2025-09-01", "08:00:00", 45, "2025-09-01T08:00:00", "https://example.com/mco.csv"),
        ("LINHA-001", "2025-09-01", "09:00:00", 52, "2025-09-01T09:00:00", "https://example.com/mco.csv"),
        ("LINHA-002", "2025-09-01", "08:00:00", 38, "2025-09-01T08:00:00", "https://example.com/mco.csv"),
    ]
    schema = ["LINHA", "DATA", "HORA", "QTDE_PASSAGEIROS", "_ingestion_timestamp", "_source_url"]
    return spark.createDataFrame(data, schema)


@pytest.fixture(scope="function")
def temp_path(tmp_path):
    """
    Fixture: Caminho temporário para outputs de teste.
    """
    return tmp_path

