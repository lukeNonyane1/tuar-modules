variable "cluster_name" {
    description = "The name to use for all the cluster resources"
}

variable "db_password" {
    description = "This is the password of the database"
}

variable "db_remote_state_bucket" {
    description = "The name of the S3 bucket used for the database's remote state storage"
}

variable "db_remote_state_key" {
    description = "The name of the key in the S3 bucket used for the database's remote state storage"
}

variable "db_instance_class" {
    description = "This is the instance class of the database"
}

