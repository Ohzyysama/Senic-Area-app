// entry/src/main/ets/pages/components/TabBar.ets
import { router } from '@kit.ArkUI'

interface TabItem {
  key: string;
  icon: string;
  text: string;
  page: string;
}

@Component
export struct TabBar {
  @State currentPage: string = 'home'

  private tabs: TabItem[] = [
    { key: 'home', icon: '🏠', text: '首页', page: 'pages/Index' },
    { key: 'map', icon: '🗺️', text: '地图', page: 'pages/MapPage' },
    { key: 'punch', icon: '📸', text: '打卡', page: 'pages/Punch' },
    { key: 'points', icon: '🎁', text: '积分', page: 'pages/PunchCardFeedPage' },
    { key: 'profile', icon: '👤', text: '我的', page: 'pages/ProfilePage' }
  ]

  build() {
    Row() {
      ForEach(this.tabs, (tab: TabItem) => {
        Column() {
          Text(tab.icon).fontSize(20)
          Text(tab.text)
            .fontSize(12)
            .fontColor(this.currentPage === tab.key ? '#007DFF' : '#666666')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(10)
        .onClick(() => {
          if (this.currentPage !== tab.key) {
            this.currentPage = tab.key
            router.pushUrl({ url: tab.page })   // ★ 改成 pushUrl，强制跳转
          }
        })
      })
    }
    .width('100%')
    .height(60)
    .backgroundColor(Color.White)
  }
}
