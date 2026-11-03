// 组织职务契约：静态载荷先行，页面只认本形状；接 provider 后换数据源，页面不动
export interface PositionEntry {
  name: string
  title: string
}

export interface PositionGroup {
  title: string
  entries: PositionEntry[]
}

export interface OrgRoster {
  id: string
  name: string
  note?: string
  groups: PositionGroup[]
}

export interface Roster {
  orgs: OrgRoster[]
}
