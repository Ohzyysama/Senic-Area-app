// entry/src/main/ets/pages/MapPage.ets
import { router } from '@kit.ArkUI'
import { TabBar } from '../pages/components/TabBar'
import { SpotModel, SpotInfo } from '../model/SpotModel'

@Entry
@Component
export default struct MapPage {
  @State spots: SpotInfo[] = SpotModel.getAllSpots();
  @State selectedSpot: SpotInfo | null = null;

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('景区地图')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 4, color: '#1F000000', offsetX: 0, offsetY: 2 })

      // 地图区域
      Stack() {
        Image($r('app.media.map'))
          .width('100%')
          .height(450)
          .objectFit(ImageFit.Cover)

        // 景点标记
        ForEach(this.spots, (spot: SpotInfo) => {
          Column() {
            // 标记点
            Column() {
              Text('📍')
                .fontSize(28)
            }
            .width(40)
            .height(40)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor('#FFFFFF')
            .borderRadius(20)
            .shadow({ radius: 4, color: '#40000000', offsetX: 0, offsetY: 2 })

            // 景点名称标签
            Text(spot.name)
              .fontSize(12)
              .fontColor('#FFFFFF')
              .backgroundColor('#007DFF')
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(4)
              .margin({ top: 4 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .position({ 
            x: `${spot.x}%`, 
            y: `${spot.y}%` 
          })
          .onClick(() => {
            this.selectedSpot = spot;
            this.navigateToSpotDetail(spot);
          })
        }, (item: SpotInfo) => item.id.toString())
      }
      .width('100%')
      .margin({ top: 10, bottom: 10 })

      // 景点列表卡片 - 横向滑动
      Column() {
        Text('景点推荐')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, top: 12, bottom: 8 })
        
        Scroll() {
          Row({ space: 12 }) {
            ForEach(this.spots, (spot: SpotInfo) => {
              this.BuildSpotCard(spot)
            }, (item: SpotInfo) => item.id.toString())
          }
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto)
        .width('100%')
        .height(180)
      }
      .layoutWeight(1)

      TabBar({ currentPage: 'map' })
    }
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  BuildSpotCard(spot: SpotInfo) {
    Column() {
      // 景点图片
      Stack() {
        Image(spot.image)
          .width('100%')
          .height(100)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)

        // 评分标签
        Row({ space: 4 }) {
          Image($r('app.media.star'))
            .width(12)
            .height(12)
          Text(spot.rating.toFixed(1))
            .fontSize(12)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
        }
        .padding({ left: 6, right: 6, top: 3, bottom: 3 })
        .backgroundColor('#40000000')
        .borderRadius(12)
        .position({ x: 8, y: 8 })
      }
      .width('100%')
      .height(100)

      // 景点信息
      Column({ space: 6 }) {
        // 景点名称
        Text(spot.name)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        // 类别
        Text(spot.category)
          .fontSize(11)
          .fontColor('#666666')
          .width('100%')

        // 访问量
        Text(`${spot.visitCount}人访问`)
          .fontSize(10)
          .fontColor('#999999')
          .width('100%')
      }
      .width('100%')
      .padding({ top: 8, left: 4, right: 4, bottom: 4 })
      .alignItems(HorizontalAlign.Start)
    }
    .width(140)
    .height(160)
    .padding(8)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 4, color: '#1F000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      this.navigateToSpotDetail(spot);
    })
  }

  // 导航到景点详情页面
  navigateToSpotDetail(spot: SpotInfo) {
    try {
      router.pushUrl({
        url: 'pages/Detail/IntroPage',
        params: { 
          spotId: spot.id,
          spotName: spot.name
        }
      })
    } catch (e) {
      console.error('导航到景点详情失败:', e);
    }
  }
}
