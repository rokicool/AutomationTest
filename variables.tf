variable "subscription_id" {
    type = string
    description = "Subscription ID"
}

variable "tenant_id" {
    type = string
    description = "Tenant_id"
}

variable "project_id" {
    type = string
    description = "A small string which will be added to all names"
}


variable "environment" {
    type = string
    description = "Prod, Dev, Test and so on"
}


#windows admin user name
variable "admin_username" {
    type = string
    description = "User name of the admin user"
}


#windows admin user password
variable "admin_password" {
    type = string
    description = "Password of the admin user"
}

