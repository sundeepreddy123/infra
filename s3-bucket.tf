resource "aws_s3_bucket_lifecycle_configuration" "bucket-config" {
  bucket  =  aws_s3_bucket.mylogs.id

  rule {
    id  =  "log-archive-rule"
    status  =  "Enabled"

    # Filter: only to the "logs/" folder
    filter {
      prefix  =  "logs/"
    }

    # Transition to IA after 30 days
    transition {
      days    =  30
      storage_class  =  "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days    =  90
      storage_class  =  "GLACIER"
    }

    # Delete after 1 year
    expiration  {
      days  =  365
      }
    }
  }
