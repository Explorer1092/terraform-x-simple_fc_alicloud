terraform {
  required_providers {
    alicloud = {
      source  = "hashicorp/alicloud"
      version = "1.162.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.2.0"
    }
  }
}

#     acme = {
#       source  = "vancluever/acme"
#       version = "2.8.0"
#     }

# ## Providers cannot be configured within modules using count, for_each or depends_on.
# provider "acme" {
#   server_url = "https://acme.zerossl.com/v2/DV90"
# }


provider "alicloud" {
  access_key = var.personal_access_key
  secret_key = var.personal_secret_key
  region     = var.region
}

module "zerossl_alicloud" {
  source            = "Explorer1092/zerossl_alicloud/x"
  version           = "1.0.4"
  aliyun_access_key = var.personal_access_key
  aliyun_secret_key = var.personal_secret_key
  common_name       = local.domain
  zerossl_key       = var.zerossl_key
}

resource "alicloud_fc_custom_domain" "default" {
  depends_on  = [module.dns]
  domain_name = local.domain
  protocol    = "HTTPS"
  route_config {
    path          = "/"
    service_name  = module.fc.this_service_name
    function_name = module.fc.this_http_function_name
    qualifier     = "LATEST"
    methods       = ["GET", "POST"]
  }
  cert_config {
    cert_name   = "${local.service_name}_${local.function_name}"
    private_key = module.zerossl_alicloud.private_key
    certificate = module.zerossl_alicloud.certificate_pem
  }
}

data "alicloud_account" "current" {

}

module "dns" {
  source               = "terraform-alicloud-modules/dns/alicloud"
  existing_domain_name = var.root_domain
  records = [
    {
      rr       = var.rr
      type     = "CNAME"
      ttl      = 600
      value    = "${data.alicloud_account.current.id}.${var.region}.fc.aliyuncs.com."
      priority = 1
    }
  ]
}

data "archive_file" "code" {
  type        = "zip"
  source_dir  = abspath("${path.module}/${var.code_path}")
  output_path = abspath("${path.module}/${var.code_path}.zip")
}

module "fc" {
  source                 = "Explorer1092/fc/alicloud"
  service_name           = local.service_name
  http_function_name     = local.function_name
  create_http_function   = true
  http_function_filename = abspath("${path.module}/${var.code_path}.zip")
  http_function_runtime  = "python3"
  http_function_handler  = "http.handler"
  http_triggers = [
    {
      type   = "http"
      config = <<EOF
        {
            "authType": "anonymous",
            "methods": ["GET", "POST"]
        }
        EOF
    }
  ]
}
