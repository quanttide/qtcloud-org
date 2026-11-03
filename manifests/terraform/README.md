# qtcloud-org 部署选型（IaC）

对齐 qtclass 与 qtcloud 的部署模式，作为 Terraform 基础设施代码的设计依据。

## 部署选型

| 维度 | 选型 | 说明 |
|------|------|------|
| 客户端形态 | Flutter Web（工作台） | `src/studio`，`flutter build web --release` 产出站点 |
| 客户端形态 | Web 查表端（lite） | `src/lite`，`npm run build` 产出静态站（拟替代 qtorg 站点） |
| 发布分发 | 阿里云 OSS 桶 `qtcloud-org-studio` | 静态网站托管（index.html 默认页）+ 公共读 |
| 发布分发 | 阿里云 OSS 桶 `qtcloud-org-lite` | 静态网站托管（index.html + 404 单页回退）+ 公共读（`lite.tf`） |
| CDN | 阿里云 CDN `org.cloud.quanttide.com` | 源站 OSS（域名回源），泛域名证书 `*.quanttide.com`（acme.sh 签发，续期后重跑 `scripts/configure-cloud-cdn.sh`） |
| CDN | 阿里云 CDN `lite.org.cloud.quanttide.com` | 源站 OSS `qtcloud-org-lite`（443），`cdn.tf` 管域名 + 强制 HTTPS + DNS CNAME；证书 acme.sh 单域名（reloadcmd 自动重绑） |
| 服务端 | **不适用** | qtcloud-org 工作台为纯客户端，无服务端部署（组织数据由 data 子模块承载，另行规划） |

## 本 IaC 范围

- **应用级**（`qtcloud-org-<env>` 命名）：OSS 发布分发桶 `qtcloud-org-studio`（`studio.tf`）与 `qtcloud-org-lite`（`lite.tf`），均含桶 + 静态网站托管 + 公共读 + 关闭阻止公共访问
- **lite 的 CDN/DNS 已进 IaC**（`cdn.tf`：CDN 域名 + 强制 HTTPS + DNS CNAME）；studio 的 CDN/DNS 为早期控制台/CLI 手工配置，未回迁 IaC
- **不含** 服务计算、数据库、API 网关（客户端无服务端）；证书由 acme.sh 管理不入库（私钥不进仓）

## studio 客户端发布

- 基础设施：`terraform apply`（`studio.tf`）
- 构建上传：`.github/workflows/deploy-studio.yml`（推送 tag `studio/*` 触发 → flutter build web → ossutil cp → 刷新 CDN）

## lite 站点发布

- 基础设施：`terraform apply`（`lite.tf` 桶 + `cdn.tf` CDN 域名 / 强制 HTTPS / DNS CNAME）
- 构建上传：`.github/workflows/deploy-lite.yml`（推送 tag `lite/*` 触发 → npm ci + vite build → ossutil cp → 刷新 CDN；不设手动触发）
- 证书（2026-11-03 已落地）：acme.sh DNS-01 签发单域名 `lite.org.cloud.quanttide.com`（`*.quanttide.com` 只覆盖一层子域，不覆盖二级子域），`SetCdnDomainSSLCertificate` 绑定；续期 reloadcmd 为 `~/.acme.sh/deploy-cdn-cert-org-lite.sh`（与 deploy-cdn-cert-org.sh 同款）
- 验证（2026-11-03）：DNS CNAME 解析 ✓、HTTP 301 → HTTPS ✓、HTTPS 握手 ✓；桶内尚无产物，首访 404——首发 `lite/*` tag 上传后为 200（版本号由用户定）

## 关键操作记录（手动部署踩坑，参考 qtclass）

1. **阻止公共访问**：2023 后新 OSS 桶默认开启"阻止公共访问"，即使 ACL=public-read 匿名访问也返回 `AccessDenied`。已通过 `PutBucketPublicAccessBlock`（`BlockPublicAccess=false`）关闭，并在 `studio.tf` 固化；如重建桶需注意。另注意：terraform 创建桶后 ACL 曾出现漂移（实际回退为 private），需以 `terraform apply` 纠正（`terraform plan` 可检出）——2026-11-03 `qtcloud-org-lite` 首建时同样回退，已 `-target=alicloud_oss_bucket_acl.lite` 纠正。
2. **静态网站托管**：桶需配置 `website`（index.html 默认页），否则 CDN 根路径 403。
3. **CDN 配置**（2026-08-14 已全部落地，`aliyun cdn` CLI 操作）：
   - `AddCdnDomain`：`org.cloud.quanttide.com`，源站 OSS `qtcloud-org-studio.oss-cn-hangzhou.aliyuncs.com`（type=oss, port=443，对齐 `delib.cloud.quanttide.com`）
   - DNS：`org.cloud.quanttide.com` CNAME → `org.cloud.quanttide.com.w.kunlunaq.com`（`aliyun alidns AddDomainRecord`）
   - HTTPS：**专属证书** `org.cloud.quanttide.com`（acme.sh `dns_ali` 挑战签发，ZeroSSL ECC；⚠ 通配证书 `*.quanttide.com` 不覆盖二级子域）
   - 续期：`acme.sh --reloadcmd` 已指向 `~/.acme.sh/deploy-cdn-cert-org.sh`（续期后自动重绑 CDN，对齐 project.cloud 模式）

## 使用

```sh
terraform init \
  -backend-config="bucket=quanttide-terraform-state" \
  -backend-config="key=qtcloud-org/terraform.tfstate" \
  -backend-config="region=cn-hangzhou"
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```
