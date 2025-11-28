// entry/src/main/ets/pages/PunchCardFeedPage.ets
import { TabBar } from '../pages/components/TabBar'

interface RankItem {
  id: number;
  user: string;
  punch: number;
  likes: number;
}

@Entry
@Component
export default struct PunchCardFeedPage {
  private ranking: RankItem[] = [
    { id: 1, user: '游客A', punch: 12, likes: 40 },
    { id: 2, user: '游客B', punch: 9, likes: 25 },
    { id: 3, user: '游客C', punch: 5, likes: 18 }
  ];

  build() {
    Column() {
      Text('打卡排行榜')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      List({ space: 10 }) {
        ForEach(this.ranking, (item: RankItem) => {
          ListItem() {
            Row() {
              Text(`#${item.id}`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ right: 10 })

              Column() {
                Text(item.user).fontSize(16)
                Text(`打卡点：${item.punch} · 获赞：${item.likes}`)
                  .fontSize(14)
                  .fontColor('#666')
              }
            }
            .padding(12)
            .backgroundColor('#F8F8F8')
            .borderRadius(10)
          }
        }, (item: RankItem) => item.id.toString())
      }
      .height(400)

      Blank().layoutWeight(1)

      TabBar({ currentPage: 'points' })
    }
    .height('100%')
    .padding(16)
  }
}
