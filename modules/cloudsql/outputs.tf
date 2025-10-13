output "instance_connection_name" {
  value       = google_sql_database_instance.this.connection_name
  description = "Cloud SQL instance connection name"
}

output "db_name" {
  value       = google_sql_database.db.name
  description = "Database name"
}

output "db_user" {
  value       = google_sql_user.user.name
  description = "Database user"
}
