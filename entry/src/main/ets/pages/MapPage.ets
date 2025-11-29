// entry/src/main/ets/pages/MapPage.ets
import { router } from '@kit.ArkUI'
import { TabBar } from '../pages/components/TabBar'

interface MapSpot {
  id: number;
  name: string;
  x: number;
  y: number;
}

@Entry
@Component
export default struct MapPage {
  private spots: MapSpot[] = [
    { id: 1, name: '观景台', x: 50, y: 120 },
    { id: 2, name: '古树广场', x: 160, y: 200 },
    { id: 3, name: '瀑布群', x: 260, y: 300 }
  ];

  build() {
    Column() {
      Text('景区地图')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      Stack() {
        Image($r('app.media.map'))
          .width('90%')
          .height(400)
          .borderRadius(12)
          .objectFit(ImageFit.Cover)

        ForEach(this.spots, (spot: MapSpot) => {
          Column() {
            Text('📍').fontSize(22)
            Text(spot.name).fontSize(12).fontColor('#333')
          }
          .position({ x: spot.x, y: spot.y })
          .onClick(() => {
            try {
              router.pushUrl({
                url: 'pages/Punch',
                params: { spotId: spot.id, name: spot.name }
              })
            } catch (e) {
              console.error('router error', e);
            }
          })
        }, (item: MapSpot) => item.id.toString())
      }

      Text('点击地图上的景点前往打卡')
        .fontSize(14)
        .fontColor('#666')
        .margin({ top: 20 })

      Blank().layoutWeight(1)

      TabBar({ currentPage: 'map' })
    }
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
