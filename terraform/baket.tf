# Создадим сервисный  аккаунт
resource "yandex_iam_service_account" "diman-diplom" {
  folder_id   = var.folder_id
  name        = "diman-diplom"
  description = "Service account"
}

# Создадим роль "editor"
resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = var.folder_id
  role      = "editor"
  members   = [
    "serviceAccount:${yandex_iam_service_account.diman-diplom.id}"
  ]
}

# Create Role "storage-admin для управления сервисом Object Storage
resource "yandex_resourcemanager_folder_iam_binding" "storage-admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  members   = [
    "serviceAccount:${yandex_iam_service_account.diman-diplom.id}"
  ]
}

# Шифруем
resource "yandex_resourcemanager_folder_iam_binding" "encrypterDecrypter" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  members   = [
    "serviceAccount:${yandex_iam_service_account.diman-diplom.id}"
  ]
}

# Создаем Static Access Key
resource "yandex_iam_service_account_static_access_key" "bucket-static_access_key" {
  service_account_id = yandex_iam_service_account.diman-diplom.id
  description        = "Static access key for Terraform Backend Bucket"
}

# Создаем KMS symmetric key for Storage Bucket
resource "yandex_kms_symmetric_key" "key-a" {
  folder_id         = var.folder_id
  name              = "symmetric-key"
  description       = "Simmetric key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h"
  lifecycle {
    prevent_destroy = false
  }
}

# Создаем Storage Bucket
resource "yandex_storage_bucket" "diman-diplom" {
  bucket     = "diman-diplom"
  access_key = yandex_iam_service_account_static_access_key.bucket-static_access_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.bucket-static_access_key.secret_key
  default_storage_class = "STANDARD"
  acl           = "public-read"
  force_destroy = "true"

  anonymous_access_flags {
    read = true
    list = true
    config_read = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
 }
 
# "local_file" for "backendConf"
resource "local_file" "backendConf" {
  content  = <<EOT
endpoint = "storage.yandexcloud.net"
bucket = "${yandex_storage_bucket.diman-diplom.bucket}"
region = "ru-central1"
key = "terraform/terraform.tfstate"
access_key = "${yandex_iam_service_account_static_access_key.bucket-static_access_key.access_key}"
secret_key = "${yandex_iam_service_account_static_access_key.bucket-static_access_key.secret_key}"
skip_region_validation = true
skip_credentials_validation = true
EOT
  filename = "./backend.key"
}

resource "yandex_storage_object" "object-2" {
    access_key = yandex_iam_service_account_static_access_key.bucket-static_access_key.access_key
    secret_key = yandex_iam_service_account_static_access_key.bucket-static_access_key.secret_key
    bucket = yandex_storage_bucket.diman-diplom.bucket
    key = "terraform.tfstate"
    source = "./terraform.tfstate"
    acl    = "private"
    depends_on = [local_file.backendConf]
}


