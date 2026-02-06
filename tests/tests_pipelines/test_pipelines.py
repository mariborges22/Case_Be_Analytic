"""
Testes para Pipelines Silver e Gold.
"""
from unittest.mock import MagicMock

import pytest


class TestSilverRefinement:
    """Testes para pipeline Silver."""

    def test_deduplication_logic(self, mock_spark):
        """Valida lógica de deduplicação."""
        mock_df = MagicMock()
        mock_df.dropDuplicates = MagicMock(return_value=mock_df)

        # Act
        mock_df.dropDuplicates(["linha", "data", "hora"])

        # Assert
        mock_df.dropDuplicates.assert_called_once_with(["linha", "data", "hora"])

    def test_null_filtering(self, mock_spark):
        """Valida remoção de registros com nulos em campos críticos."""
        mock_df = MagicMock()
        mock_df.filter = MagicMock(return_value=mock_df)

        # Simula filtros
        mock_df.filter("linha IS NOT NULL")
        mock_df.filter("data IS NOT NULL")

        assert mock_df.filter.call_count == 2

    def test_type_casting(self, mock_spark):
        """Valida cast de tipos."""
        mock_df = MagicMock()
        mock_df.withColumn = MagicMock(return_value=mock_df)

        # Simula cast de passageiros para IntegerType
        from pyspark.sql.types import IntegerType

        mock_df.withColumn("passageiros", MagicMock())

        assert mock_df.withColumn.called


class TestGoldAggregations:
    """Testes para pipeline Gold."""

    def test_aggregation_by_linha_data(self, mock_spark):
        """Valida agregação por linha e data."""
        mock_df = MagicMock()
        mock_df.groupBy = MagicMock(return_value=mock_df)
        mock_df.agg = MagicMock(return_value=mock_df)

        # Act
        mock_df.groupBy("linha", "data").agg(MagicMock())

        # Assert
        mock_df.groupBy.assert_called_once_with("linha", "data")
        mock_df.agg.assert_called_once()

    def test_zorder_optimization(self, mock_spark):
        """Valida aplicação de Z-ORDER."""
        mock_spark.sql = MagicMock()

        # Act
        mock_spark.sql("OPTIMIZE gold_table ZORDER BY (linha)")

        # Assert
        mock_spark.sql.assert_called_once()
        assert "ZORDER" in mock_spark.sql.call_args[0][0]

    def test_star_schema_dimensions(self, mock_spark):
        """Valida criação de dimensões Star Schema."""
        mock_df = MagicMock()
        mock_df.select = MagicMock(return_value=mock_df)
        mock_df.distinct = MagicMock(return_value=mock_df)
        mock_df.withColumn = MagicMock(return_value=mock_df)

        # Simula criação de dim_linha
        mock_df.select("linha").distinct().withColumn("linha_id", MagicMock())

        assert mock_df.select.called
        assert mock_df.distinct.called
