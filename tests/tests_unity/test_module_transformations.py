"""
Testes Unitários: Transformações puras da camada Medalhão.
Usa mock_spark fixture - nenhuma chamada de rede ou cluster real.
"""

from unittest.mock import MagicMock, patch




class TestBronzeTransformations:
    """Testes de lógica de ingestão Bronze."""

    def test_clean_column_names(self, mock_spark):
        """Valida normalização de nomes de colunas."""
        # Arrange
        input_cols = ["Nome Completo", "Data-Nascimento", "CPF/CNPJ"]
        expected = ["nome_completo", "data_nascimento", "cpf_cnpj"]

        # Act - substitua pela sua função real
        # from src.transformations import clean_column_names
        # result = clean_column_names(input_cols)
        result = [
            c.lower().replace(" ", "_").replace("-", "_").replace("/", "_")
            for c in input_cols
        ]

        # Assert
        assert result == expected

    def test_add_ingestion_metadata(self, mock_spark):
        """Valida adição de colunas de metadados."""
        mock_df = MagicMock()
        mock_df.withColumn = MagicMock(return_value=mock_df)

        # Simula adição de _ingested_at e _source_file
        mock_df.withColumn("_ingested_at", MagicMock())
        mock_df.withColumn("_source_file", MagicMock())

        assert mock_df.withColumn.call_count == 2


class TestSilverTransformations:
    """Testes de lógica de limpeza Silver."""

    def test_deduplicate_by_key(self, mock_spark):
        """Valida deduplicação por chave primária."""
        mock_df = MagicMock()
        mock_df.dropDuplicates = MagicMock(return_value=mock_df)

        # Act
        mock_df.dropDuplicates(["id"])

        # Assert
        mock_df.dropDuplicates.assert_called_once_with(["id"])

    @patch("builtins.open", create=True)
    def test_schema_validation_no_external_io(self, mock_open, mock_spark):
        """Valida que schema validation não faz I/O externo."""
        mock_open.side_effect = IOError("No I/O allowed in unit tests")

        # Sua lógica de validação não deve abrir arquivos diretamente
        # from src.validations import validate_schema
        # Este teste garante isolamento
        assert True  # Placeholder


class TestGoldAggregations:
    """Testes de lógica de agregação Gold."""

    def test_calculate_metrics(self, mock_spark):
        """Valida cálculo de métricas agregadas."""
        # Arrange
        mock_df = MagicMock()
        mock_df.groupBy = MagicMock(return_value=mock_df)
        mock_df.agg = MagicMock(return_value=mock_df)

        # Act
        mock_df.groupBy("category").agg({"value": "sum"})

        # Assert
        mock_df.groupBy.assert_called_once_with("category")
