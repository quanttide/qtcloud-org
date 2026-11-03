import Home from './pages/Home'
import './App.css'

// 外壳：只留品牌，无导航菜单、无配置——组织与职务首屏即查表
function App() {
  return (
    <div className="liteApp">
      <header className="liteHeader">
        <span className="liteBrand">量潮组织 Lite</span>
      </header>
      <div className="liteMain">
        <Home />
      </div>
    </div>
  )
}

export default App
