import { router } from "@kit.ArkUI"

// entry/src/main/ets/pages/components/RecommendationList.ets
interface ScenicSpot {
  id: string
  name: string
  image: Resource
  rating: number
  distance: string
  description: string
}

@Component
export struct RecommendationList {
  private scenicSpots: ScenicSpot[] = [
    {
      id: '1',
      name: '云海观景台',
      image: $r('app.media.startIcon'),
      rating: 4.8,
      distance: '1.2km',
      description: '绝美云海，拍照圣地'
    },
    {
      id: '2',
      name: '千年古树',
      image: $r('app.media.startIcon'),
      rating: 4.6,
      distance: '0.8km',
      description: '千年历史，祈福灵树'
    },
    {
      id: '3',
      name: '瀑布飞流',
      image: $r('app.media.startIcon'),
      rating: 4.9,
      distance: '2.1km',
      description: '气势磅礴，清凉避暑'
    }
  ]

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('推荐景点')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('查看更多')
          .fontSize(14)
          .fontColor('#007DFF')
          .margin({ left: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 12 })

      // 推荐列表
      List({ space: 12 }) {
        ForEach(this.scenicSpots, (item: ScenicSpot) => {
          ListItem() {
            this.BuildScenicItem(item)
          }
        }, (item: ScenicSpot) => item.id)
      }
      .height(280)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder BuildScenicItem(item: ScenicSpot) {
    Row() {
      // 景点图片
      Image(item.image)
        .width(80)
        .height(80)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)

      // 景点信息
      Column() {
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 4 })

        Text(item.description)
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(2)
          .margin({ bottom: 8 })

        // 评分和距离
        Row() {
          Row() {
            Image($r('app.media.startIcon'))
              .width(14)
              .height(14)
            Text(item.rating.toString())
              .fontSize(12)
              .margin({ left: 4 })
          }

          Text(item.distance)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 12 })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .layoutWeight(1)
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(80)
    .padding(8)
    .backgroundColor('#F9F9F9')
    .borderRadius(12)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/DetailPage',
        params: { id: item.id }
      })
    })
  }
}