# ----------------------------------------------------------------------------
# Unity Catalog - Main Catalog
# ----------------------------------------------------------------------------

resource "databricks_catalog" "mco_catalog" {
  name         = var.catalog_name
  storage_root = "s3://${aws_s3_bucket.databricks_data.id}/"
  comment      = "Catálogo principal do Lakehouse MCO (Transporte e Mobilidade)"

  properties = {
    purpose = "analytics"
  }
}

# ----------------------------------------------------------------------------
# Bronze Layer (Raw Data) - Immutable Ingestion
# ----------------------------------------------------------------------------

resource "databricks_schema" "bronze" {
  catalog_name = var.catalog_name
  name         = var.bronze_schema
  comment      = "Camada Bronze: Dados brutos e imutáveis do MCO (ELT - Extract & Load)"
  
  properties = {
    layer        = "bronze"
    data_type    = "raw"
    is_immutable = "true"
    description  = "Ingestão de dados MCO originais sem transformação"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# ----------------------------------------------------------------------------
# Silver Layer (Validated Data) - Single Source of Truth
# ----------------------------------------------------------------------------

resource "databricks_schema" "silver" {
  catalog_name = var.catalog_name
  name         = var.silver_schema
  comment      = "Camada Prata: Dados limpos, validados e desduplicados (ELT - Transform)"
  
  properties = {
    layer       = "silver"
    data_type   = "validated"
    operations  = "cleaning,deduplication,normalization,null_handling"
    description = "Versão única da verdade (single source of truth)"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# ----------------------------------------------------------------------------
# Gold Layer (Enriched Data) - Business Aggregates
# ----------------------------------------------------------------------------

resource "databricks_schema" "gold" {
  catalog_name = var.catalog_name
  name         = var.gold_schema
  comment      = "Camada Ouro: Agregados de negócio e modelagem dimensional (Star Schema)"
  
  lifecycle {
    prevent_destroy = true
  }
}
