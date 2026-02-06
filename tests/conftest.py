import sys
from pathlib import Path
from unittest.mock import MagicMock

import pytest
from pyspark.sql import SparkSession

# Add src to path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT / "src"))


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
def spark():
    """Create Spark session for tests."""
    spark = (
        SparkSession.builder.appName("log-engine-tests")
        .master("local[2]")
        .config("spark.sql.shuffle.partitions", "2")
        .config("spark.default.parallelism", "2")
        .config("spark.sql.adaptive.enabled", "false")
        .config("spark.ui.enabled", "false")
        .getOrCreate()
    )
    yield spark
    spark.stop()


@pytest.fixture(scope="function")
def sample_bronze_data(spark):
    """Sample bronze layer data."""
    data = [
        ("2024-01-01 10:00:00", "INFO", "Service started", "app1"),
        ("2024-01-01 10:01:00", "ERROR", "Connection failed", "app1"),
        ("2024-01-01 10:02:00", "WARN", "High memory usage", "app2"),
    ]
    return spark.createDataFrame(data, ["timestamp", "level", "message", "source"])


@pytest.fixture(scope="function")
def temp_path(tmp_path):
    """Temporary path for test outputs."""
    return tmp_path
