terraform {
  required_version = ">= 0.12.1"
}

locals {
    test-string = "af*dsfg9\"'[]:|<>+=;,?*@&8g8g7d9/f769087()s&dfd)"
    # vm-name = replace(local.test-string, "/[//\"'\\[\\]:|<>+=;,?*@&]/","")
    
    vm-name = replace(local.test-string, "/[^0-9a-zA-Z_-]/","")
    # vm-name = regex("[a-z]+", local.test-string)
}

output "res" {
    value = local.vm-name
}