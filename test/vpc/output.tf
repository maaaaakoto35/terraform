## output.tf
output "public_subnet_id_value" {
  value       = "${module.vpc.public_subnet_id_value}"  ## ここではmoduleのoutputを指定する。
}