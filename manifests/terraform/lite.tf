# lite 客户端发布分发桶（IaC）
#
# 桶 qtcloud-org-lite：命名对齐站点规范 {repo}-{type}（如 qtclass-lite）。
# 产物：Vite 静态站（src/lite 构建 dist/）。
# 静态网站托管：index.html 默认页 + 404.html 单页回退。
# 部署流水线：.github/workflows/deploy-lite.yml（tag 触发 → vite build → ossutil cp → 刷新 CDN）。
# CDN 域名 lite.org.cloud.quanttide.com：控制台/CLI 配置，记录见 manifests/terraform/README.md。

resource "alicloud_oss_bucket" "lite" {
  bucket = "qtcloud-org-lite"

  # 静态网站托管（Web 端入口 index.html，404 回退单页）
  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

# 2023 后新桶默认开启"阻止公共访问"，会使 public-read 失效（AccessDenied），需显式关闭
resource "alicloud_oss_bucket_public_access_block" "lite" {
  bucket              = alicloud_oss_bucket.lite.bucket
  block_public_access = false
}

# 公共读：静态站分发；如后续接入 CDN 回源鉴权可改回 private
resource "alicloud_oss_bucket_acl" "lite" {
  bucket = alicloud_oss_bucket.lite.bucket
  acl    = "public-read"
}
