import { HomeHeader } from './components/HomeHeader'
import { FunctionGrid } from './components/FunctionGrid'
import { RecommendationList } from './components/RecommendationList'
import { TabBar } from './components/TabBar'
@Entry
@Component
struct Index {
  build() {
    Column() {
      // 顶部导航
      HomeHeader()

      // 内容区域 - 可滚动
      Scroll() {
        Column() {
          // 轮播图
          this.BuildBanner()

          // 功能入口网格
          FunctionGrid()

          // 推荐景区列表
          RecommendationList()

          // 热门打卡地
          this.BuildHotSpots()
        }
      }
      .layoutWeight(1)  // 占据剩余空间

      // 底部导航
      TabBar({ currentPage: 'home' })
    }
    .height('100%')
    .backgroundColor(Color.White)
  }

  @Builder BuildBanner() {
    // 轮播图实现
  }

  @Builder BuildHotSpots() {
    // 热门打卡地实现
  }
}