# ----------------------------------------------------------------------------
# Unity Catalog - Main Catalog (Existente)
# ----------------------------------------------------------------------------

# Referência feita via data.databricks_catalog.existing em data_sources.tf

# ----------------------------------------------------------------------------
# Bronze Layer (Raw Data) - Immutable Ingestion
# ----------------------------------------------------------------------------

resource "databricks_schema" "bronze" {
  catalog_name = data.databricks_catalog.existing.name
  name         = var.bronze_schema
  owner        = data.databricks_current_user.me.user_name
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
  catalog_name = data.databricks_catalog.existing.name
  name         = var.silver_schema
  owner        = data.databricks_current_user.me.user_name
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
  catalog_name = data.databricks_catalog.existing.name
  name         = var.gold_schema
  owner        = data.databricks_current_user.me.user_name
  comment      = "Camada Ouro: Agregados de negócio e modelagem dimensional (Star Schema)"
  
  lifecycle {
    prevent_destroy = true
  }
}
