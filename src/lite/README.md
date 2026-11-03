# 量潮组织 Lite

组织与职务的查表端：首屏即名单，无导航、无配置——谁在什么位子上，一眼查到。

Web 形态，React + Vite + TypeScript + vitest + eslint，遵循同族 `qtclass-lite` 惯例；拟替代 qtorg 站点。

## 开发

```bash
npm install
npm run dev      # 本地预览
npm run build    # tsc + vite 构建
npm run lint
npm test
```

## 结构

```
data/roster.json         # 职务载荷（与组织档案 data/profile 各组织职务表同源）
src/
├── models/roster.ts     # 职务契约（组织 / 机构分组 / 任职条目）
├── data/roster.ts       # 载荷入口（静态载荷，换源不动页面）
├── pages/Home.tsx       # 按组织 → 机构分组的查表
├── App.tsx              # 外壳：只留品牌
└── App.test.tsx         # 冒烟（品牌、组织、职务、人物、无导航）
```

## 数据面

契约静态先行：页面只认 `models/roster.ts` 的形状，数据源当前为仓内静态载荷。职务的事实源是组织档案 `data/profile` 各组织 title.md——档案改职务时同步改 `data/roster.json`。

## 部署

链路：推送 `lite/*` tag → GitHub Actions（本包构建）→ OSS 桶 `qtcloud-org-lite` → CDN `lite.org.cloud.quanttide.com`。

- 流水线：`.github/workflows/deploy-lite.yml`（与本仓 deploy-studio.yml 同款；只由 tag 触发，不设手动触发）
- 基础设施：`../../manifests/terraform/lite.tf`（桶）+ `cdn.tf`（CDN 域名、强制 HTTPS、DNS CNAME）；证书 acme.sh 单域名续期自动重绑
- 首发：待版本号（用户定）后切 `lite/<版本>` tag 触发
