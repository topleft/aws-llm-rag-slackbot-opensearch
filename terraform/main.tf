resource "aws_s3_bucket" "example" {
  bucket = "topleft-tf-test-bucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}