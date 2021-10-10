variable "environment" {
  description = "AWS Environment"
  type        = string
  default     = "dev"
}

variable "aws-profile" {
  description = "Local AWS Profile Name"
  type        = string
  default     = "default"
}
variable "aws_region" {
  description = "aws region"
  default     = "us-east-1"
  type        = string
}