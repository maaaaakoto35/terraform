## output.tf
output "public_subnet_id" {
  value       = "${module.vpc.public_subnet_id}"  ## ここではmoduleのoutputを指定する。
}