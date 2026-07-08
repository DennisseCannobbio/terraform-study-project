terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "hello_world" {
  content = var.file_content
  filename = "${path.module}/${var.file_name}"
}