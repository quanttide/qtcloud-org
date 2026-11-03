# =============================================================================
# lite CDN + DNS（lite.org.cloud.quanttide.com）
#
# 链路：OSS 静态网站桶（lite.tf，公共读）→ CDN 加速（源站 443，对齐 deploy-studio 期的
#       studio 域名配置）→ CNAME 接入（云解析）→ 用户浏览器
#
# 说明（对齐 qtorg / qtsupport manifests/terraform/cdn.tf 的成熟实践）：
#   - 桶 ACL 公共读（lite.tf；新桶创建后曾回退 private，已以 terraform apply 纠正）
#   - 公共读桶不开启 l2_oss_key 私有回源
#   - 强制 HTTPS：https_force 开（与 org.cloud.quanttide.com 同配置）
#   - 证书：acme.sh 签发单域名证书（*.quanttide.com 泛证书不覆盖二级子域），
#     经 SetCdnDomainSSLCertificate 绑定，reloadcmd 见 ~/.acme.sh/deploy-cdn-cert-org-lite.sh；
#     terraform 不管理证书内容（私钥不入库）
#   - 前置：quanttide.com 已完成 ICP 备案
# =============================================================================

resource "alicloud_cdn_domain_new" "lite" {
  domain_name = "lite.org.cloud.quanttide.com"
  cdn_type    = "web"

  # 源站：OSS 静态网站桶（lite 专用桶 qtcloud-org-lite——上传目标一致，见 deploy-lite.yml）
  sources {
    content  = "qtcloud-org-lite.oss-cn-hangzhou.aliyuncs.com"
    type     = "oss"
    port     = 443
    priority = 20
  }
}

# 强制 HTTPS：HTTP 请求 301 跳转 HTTPS
resource "alicloud_cdn_domain_config" "lite_https_force" {
  domain_name   = alicloud_cdn_domain_new.lite.domain_name
  function_name = "https_force"
  function_args {
    arg_name  = "enable"
    arg_value = "on"
  }
}

# ── DNS：CNAME 接入 ─────────────────────────────────────────────────

resource "alicloud_alidns_record" "lite" {
  domain_name = "quanttide.com"
  rr          = "lite.org.cloud"
  type        = "CNAME"
  value       = alicloud_cdn_domain_new.lite.cname
  ttl         = 600
}
