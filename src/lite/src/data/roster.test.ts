import { describe, it, expect } from 'vitest'
import { ROSTER } from './roster'

describe('载荷完整性', () => {
  it('组织与机构分组齐整', () => {
    expect(ROSTER.orgs.length).toBeGreaterThanOrEqual(4)
    const ids = ROSTER.orgs.map((org) => org.id)
    expect(new Set(ids).size).toBe(ids.length)

    for (const org of ROSTER.orgs) {
      expect(org.name).not.toBe('')
      expect(org.groups.length).toBeGreaterThan(0)
      for (const group of org.groups) {
        expect(group.title).not.toBe('')
        expect(group.entries.length).toBeGreaterThan(0)
        for (const entry of group.entries) {
          expect(entry.name).not.toBe('')
          expect(entry.title).not.toBe('')
        }
      }
    }
  })

  it('本批新职务在载荷中', () => {
    const text = JSON.stringify(ROSTER)
    const titles = [
      '联盟理事会秘书',
      '联盟议长',
      '联盟副议长',
      '联盟秘书长',
      '联盟副秘书长',
      '总裁、议长',
      '副总裁、副议长',
      '游戏总监、实训基地代表',
      '小说总监、实训基地代表',
      '秘书长、实训基地代表',
      '总裁',
    ]
    for (const title of titles) {
      expect(text).toContain(title)
    }
  })
})
