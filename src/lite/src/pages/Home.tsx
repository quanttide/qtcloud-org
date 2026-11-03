import { ROSTER } from '../data/roster'

// 首屏即查表：按组织 → 机构分组列职务，无导航、无配置——看谁在什么位子上
function Home() {
  return (
    <main>
      <p className="rosterHint">职务查表：组织 → 机构 → 任职</p>
      {ROSTER.orgs.map((org) => (
        <section key={org.id} className="orgSection">
          <div className="orgHead">
            <h2>{org.name}</h2>
            {org.note && <span className="orgNote">{org.note}</span>}
          </div>
          {org.groups.map((group) => (
            <div key={group.title} className="orgGroup">
              <h3>{group.title}</h3>
              <ul className="entryList">
                {group.entries.map((entry) => (
                  <li key={entry.name} className="entryRow">
                    <span className="entryName">{entry.name}</span>
                    <span className="entryTitle">{entry.title}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </section>
      ))}
    </main>
  )
}

export default Home
