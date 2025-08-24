# store the file in the same directory this file is located






# Example usage:






variable "user" {
  type = string
  description = "value for the user id"
  default= "982081071114"
}

variable "redshift_config" {

  type = object({
    cluster_identifier     = string
    database_name          = string
    master_username        = string
    node_type              = string
    cluster_type           = string
    manage_master_password = bool
    skip_final_snapshot    = bool
  })

  default = {
    cluster_identifier = "de-tuto-cluster"
    database_name      = "mydb"
    master_username    = "pgadmin"
    node_type          = "ra3.large"
    cluster_type       = "single-node"

    manage_master_password = true

    # Skip final snapshot when destroying the cluster
    skip_final_snapshot = true
  }

}