import type { Roster } from '../models/roster'
import payload from '../../data/roster.json'

// 静态载荷：与组织档案 data/profile 各组织职务表同源同字；档案改职务时同步改 data/roster.json
export const ROSTER: Roster = payload
