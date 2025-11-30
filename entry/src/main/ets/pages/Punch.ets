// entry/src/main/ets/pages/Punch.ets
import { router } from '@kit.ArkUI'
import { TabBar } from '../pages/components/TabBar'

interface PunchRecord {
  id: number;
  user: string;
  photo: Resource;
  likes: number;
}

interface PunchParams {
  spotId?: number;
  name?: string;
}

@Entry
@Component
 struct Punch {
  @State spotName: string = '未知景点';

  private records: PunchRecord[] = [
    { id: 1, user: '游客A', photo: $r('app.media.x1'), likes: 12 },
    { id: 2, user: '游客B', photo: $r('app.media.x2'), likes: 7 },
    { id: 3, user: '游客C', photo: $r('app.media.x3'), likes: 19 }
  ];

  aboutToAppear() {
    try {
      const routerParams = router.getParams() as PunchParams;
      this.spotName = routerParams?.name || '未知景点';
    } catch (error) {
      console.error('Failed to get router params:', error);
      this.spotName = '未知景点';
    }
  }

  build() {
    Column() {
      Text(`${this.spotName} · 打卡`)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      Button('拍照打卡（占位）')
        .margin({ top: 20 })
        .width('70%')
        .height(40)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .borderRadius(8)

      Text('其他游客的打卡')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 30, bottom: 10 })

      List({ space: 10 }) {
        ForEach(this.records, (item: PunchRecord) => {
          ListItem() {
            Row() {
              Image(item.photo)
                .width(60).height(60)
                .borderRadius(8)

              Column() {
                Text(item.user).fontSize(16)
                Text(`点赞：${item.likes}`)
                  .fontSize(14).fontColor('#666')
              }.margin({ left: 12 })
            }
            .padding(10)
            .backgroundColor('#F6F6F6')
            .borderRadius(10)
          }
        }, (item: PunchRecord) => item.id.toString())
      }
      .height(300)

      Blank().layoutWeight(1)

      TabBar({ currentPage: 'punch' })
    }
    .height('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }
}
