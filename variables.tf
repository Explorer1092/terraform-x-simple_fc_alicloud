variable "rr" {
  default     = "pass"
  description = "domain"
}

variable "root_domain" {
  default     = "sss.ms"
  description = "domain"
}

variable "zerossl_key" {

}

variable "personal_access_key" {
  type = string
  //   sensitive = true
}

variable "personal_secret_key" {
  type = string
  //   sensitive = true
}



variable "code_path" {
  default     = "../../src/pass/http.py"
  description = "../../src/pass/http.py"
}
variable "region" {
  default = "cn-hongkong"
}

locals {
  domain        = "${var.rr}.${var.root_domain}"
  service_name  = replace(local.domain, ".", "")
  function_name = replace(var.rr, ".", "")
}