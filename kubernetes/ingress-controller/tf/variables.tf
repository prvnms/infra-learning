variable "region" {
    default = "us-east-1"
}


variable "my_ip" {
    description = "Your public IP for SSH / kubectl"
}


variable "key_name" {
    description = "Existing EC2 key pair name"
}