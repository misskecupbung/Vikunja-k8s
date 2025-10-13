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

output "public_ip_address" {
  value       = try(google_sql_database_instance.this.public_ip_address, null)
  description = "Public IPv4 address of the Cloud SQL instance (null if disabled)"
}
