provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.service_region
}

// Provision cloudant resource instance with Lite plan
resource "ibm_cloudant" "cloudant" {
  // Required arguments:
  name     = "test_cloudant_for_terraform"
  location = var.service_region
  plan     = "lite"
}

// Create cloudant data source
data "ibm_cloudant" "cloudant" {
  name     = ibm_cloudant.cloudant.name
}
