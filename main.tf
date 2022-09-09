terraform {
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "~> 0.35"
    }
  }
}

provider "snowflake" {
  role  = "ACCOUNTADMIN"
}

resource "snowflake_database" "db" {
  name     = "TERRAFORM_HEALTH_DEMO"
}

resource "snowflake_warehouse" "warehouse" {
  name           = "TERRAFORM_HEALTH_DEMO_WAREHOUSE"
  warehouse_size = "X-small"

  auto_suspend = 60
}



resource "snowflake_role" "role" {
        provider = snowflake
        name     = "Health_TERRAFORM_DEMO_SVC_ROLE"
    }
resource "snowflake_database_grant" "grant" {
        provider          = snowflake
        database_name     = snowflake_database.db.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }
resource "snowflake_schema" "schema" {
        database   = snowflake_database.db.name
        name       = "HEALTH"
        is_managed = false
    }
resource "snowflake_schema_grant" "grant" {
        provider          = snowflake
        database_name     = snowflake_database.db.name
        schema_name       = snowflake_schema.schema.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }
resource "snowflake_warehouse_grant" "grant" {
        provider          = snowflake
        warehouse_name    = snowflake_warehouse.warehouse.name
        privilege         = "USAGE"
        roles             = [snowflake_role.role.name]
        with_grant_option = false
    }
resource "tls_private_key" "svc_key" {
        algorithm = "RSA"
        rsa_bits  = 2048
    }
resource "snowflake_user" "user" {
        provider          = snowflake
        name              = "terraform_demo_user"
        default_warehouse = snowflake_warehouse.warehouse.name
        default_role      = snowflake_role.role.name
        default_namespace = "${snowflake_database.db.name}.${snowflake_schema.schema.name}"
        rsa_public_key    = substr(tls_private_key.svc_key.public_key_pem, 27, 398)
    }
resource "snowflake_role_grants" "grants" {
        provider  = snowflake
        role_name = snowflake_role.role.name
        users     = [snowflake_user.user.name]
    }
