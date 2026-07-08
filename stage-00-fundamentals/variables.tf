variable "file_content" {
  type = string
  description = "A simple file with a text"
  default = "Hello World!"
}

variable "file_name" {
  type = string
  description = "The name of the file stored"
  default = "hello.txt"
}