
terraform {
  backend "s3" {
    bucket = "pgr301-terraform-state"
    # Backend-blokken kan ikke bruke variabler, så kandidatnummeret står direkte i nøkkelen
    key    = "wishifai/18/terraform.tfstate"
    region = "eu-west-1"
  }
}