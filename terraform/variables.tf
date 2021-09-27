variable "yandex_token" {
  type        = string
  description = "Security token or IAM token used for authentication in Yandex.Cloud"
}

variable "yandex_cloud_id" {
  type        = string
  description = "The ID of the cloud to apply any resources to"
}

variable "yandex_folder_id" {
  type        = string
  description = "The ID of the folder to operate under"
}

variable "db_password" {
  type        = string
  description = "Set up PostgreSQL password"
}