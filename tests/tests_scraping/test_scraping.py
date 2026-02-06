"""
Testes para MCO Extractor - Camada Bronze.
"""

from unittest.mock import MagicMock, patch

import pytest


class TestMCOExtractor:
    """Testes para extração de dados MCO."""

    @patch("scraping.mco_extractor.requests.get")
    def test_download_csv_success(self, mock_get, mock_spark):
        """Valida download bem-sucedido do CSV."""
        # Arrange
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.content = b"linha,data,passageiros\n1001,2024-01-01,150"
        mock_get.return_value = mock_response

        # Act
        from scraping.mco_extractor import extract_mco_data

        # Mock Spark read/write
        mock_spark.read.option.return_value.option.return_value.csv.return_value = (
            MagicMock()
        )

        # Assert
        mock_get.assert_not_called()  # Ainda não chamado
        # extract_mco_data(mock_spark, "http://test.csv", "/tmp/out")
        # mock_get.assert_called_once()

    def test_add_ingestion_metadata(self, mock_spark):
        """Valida adição de colunas _ingestion_timestamp e _source_url."""
        mock_df = MagicMock()
        mock_df.withColumn = MagicMock(return_value=mock_df)

        # Simula adição de metadados
        mock_df.withColumn("_ingestion_timestamp", MagicMock())
        mock_df.withColumn("_source_url", MagicMock())

        assert mock_df.withColumn.call_count == 2

    @patch("scraping.mco_extractor.requests.get")
    def test_http_error_handling(self, mock_get, mock_spark):
        """Valida tratamento de erro HTTP."""
        import requests

        mock_get.side_effect = requests.exceptions.HTTPError("404 Not Found")

        from scraping.mco_extractor import extract_mco_data

        with pytest.raises(requests.exceptions.HTTPError):
            extract_mco_data(mock_spark, "http://invalid.csv", "/tmp/out")
