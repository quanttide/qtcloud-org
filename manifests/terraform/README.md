# qtcloud-org 部署选型（IaC）

对齐 qtclass 与 qtcloud 的部署模式，作为 Terraform 基础设施代码的设计依据。

## 部署选型

| 维度 | 选型 | 说明 |
|------|------|------|
| 客户端形态 | Flutter Web（工作台） | `src/studio`，`flutter build web --release` 产出站点 |
| 发布分发 | 阿里云 OSS 桶 `qtcloud-org-studio` | 静态网站托管（index.html 默认页）+ 公共读 |
| CDN | 阿里云 CDN `org.cloud.quanttide.com` | 源站 OSS（域名回源），泛域名证书 `*.quanttide.com`（acme.sh 签发，续期后重跑 `scripts/configure-cloud-cdn.sh`） |
| 服务端 | **不适用** | qtcloud-org 工作台为纯客户端，无服务端部署（组织数据由 data 子模块承载，另行规划） |

## 本 IaC 范围

- **应用级**（`qtcloud-org-<env>` 命名）：OSS 发布分发桶 `qtcloud-org-studio`（`studio.tf`：桶 + 静态网站托管 + 公共读 + 关闭阻止公共访问）
- **不含** 服务计算、数据库、API 网关（客户端无服务端）；CDN / DNS / 证书无组织级 IaC 先例（对齐 qtclass），在控制台配置并记录于本文件

## studio 客户端发布

- 基础设施：`terraform apply`（`studio.tf`）
- 构建上传：`.github/workflows/deploy-studio.yml`（推送 tag `studio/*` 触发 → flutter build web → ossutil cp → 刷新 CDN）

## 关键操作记录（手动部署踩坑，参考 qtclass）

1. **阻止公共访问**：2023 后新 OSS 桶默认开启"阻止公共访问"，即使 ACL=public-read 匿名访问也返回 `AccessDenied`。已通过 `PutBucketPublicAccessBlock`（`BlockPublicAccess=false`）关闭，并在 `studio.tf` 固化；如重建桶需注意。
2. **静态网站托管**：桶需配置 `website`（index.html 默认页），否则 CDN 根路径 403。
3. **CDN 配置**（控制台/CLI 完成，`scripts/configure-cloud-cdn.sh` 固化证书与 DNS）：
   - `AddCdnDomain`：`org.cloud.quanttide.com`，源站 OSS `qtcloud-org-studio.oss-cn-hangzhou.aliyuncs.com`（type=oss, port=443）
   - HTTPS：上传 `*.quanttide.com` 证书（`SetCdnDomainSSLCertificate`，acme.sh 3 个月续期）
   - DNS：`org.cloud.quanttide.com` CNAME → `org.cloud.quanttide.com.w.kunlunaq.com`

## 使用

```sh
terraform init \
  -backend-config="bucket=quanttide-terraform-state" \
  -backend-config="key=qtcloud-org/terraform.tfstate" \
  -backend-config="region=cn-hangzhou"
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```
