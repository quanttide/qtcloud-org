import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import '@testing-library/jest-dom/vitest'
import App from './App'

// 冒烟：品牌、四个组织与本批新职务都必须渲染出来
describe('职务查表渲染', () => {
  it('品牌', () => {
    render(<App />)
    expect(screen.getAllByText(/量潮组织 Lite/).length).toBeGreaterThan(0)
  })

  const orgs = ['量潮创新联盟', '量潮科技', '量潮实训基地', '量潮研究院']
  for (const org of orgs) {
    it(`组织 ${org}`, () => {
      render(<App />)
      expect(screen.getAllByText(org).length).toBeGreaterThan(0)
    })
  }

  const titles = [
    /联盟理事会秘书/,
    /联盟议长/,
    /联盟副议长/,
    /联盟秘书长/,
    /联盟副秘书长/,
    /总裁、议长/,
    /副总裁、副议长/,
    /游戏总监/,
    /小说总监/,
    /秘书长、实训基地代表/,
  ]
  for (const title of titles) {
    it(`职务 ${title}`, () => {
      render(<App />)
      expect(screen.getAllByText(title).length).toBeGreaterThan(0)
    })
  }

  const people = ['涂雅芳', '赵子奕', '鲍宇航', '李可欣', '林莉婷', '黄亮', '王敏华', '罗析芸', '孟金曼', '秦悦鑫']
  for (const person of people) {
    it(`人物 ${person}`, () => {
      render(<App />)
      expect(screen.getAllByText(person).length).toBeGreaterThan(0)
    })
  }

  it('无导航菜单与配置项', () => {
    render(<App />)
    expect(document.querySelectorAll('nav').length).toBe(0)
    expect(screen.queryByText(/设置|目录|配置/)).toBeNull()
  })
})

afterEach(cleanup)
