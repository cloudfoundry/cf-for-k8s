resource "aws_db_instance" "postgres" {
  allocated_storage       = 20
  engine                  = "postgres"
  instance_class          = "db.t2.micro"
  identifier              = "cf4k8s"
  username                = "postgres"
  password                = var.database_password
  publicly_accessible     = true
  skip_final_snapshot     = true
  backup_retention_period = 7
}
