output "studio_bucket" {
  description = "studio 客户端发布分发桶（部署产物见 .github/workflows/deploy-studio.yml）"
  value       = alicloud_oss_bucket.studio.bucket
}

output "lite_bucket" {
  description = "lite 站点发布分发桶（部署产物见 .github/workflows/deploy-lite.yml）"
  value       = alicloud_oss_bucket.lite.bucket
}
