# org 参考实现（自 qtadmin 迁移）

组织管理领域的参考实现，自 qtadmin 拆除时迁移，供 qtcloud-org 产品线恢复时参考。

## 结构

| 文件 | 说明 |
|------|------|
| `org_model.dart` | 数据模型（手写，无 freezed）：OrgDashboard / OrgInstitution / OrgMeeting / OrgRepresentative / OrgRank / OrgPromotion |
| `org_screen.dart` | 组织管理页面（机构看板、代表履职、职级流动） |
| `stat_item.dart` | 统计项组件 |
| `test/` | 模型 + 页面测试（21 个） |
| `../org.json` | 示例数据（机构/代表/职级/晋升），契约对齐 `org_model.dart` |

## 恢复方式

将本目录文件复制到产品线 `src/studio/lib/` 对应位置（models/screens/views），调整 import 为包内路径即可。数据加载沿用 qtadmin 的 `DataLoader` 模式（`FileSource` 读取数据文件）。

## 测试

```bash
flutter pub get
flutter test
```
