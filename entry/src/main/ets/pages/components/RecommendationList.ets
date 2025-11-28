import { router } from "@kit.ArkUI"
import http from '@ohos.net.http';

// 后端响应接口定义
interface SpotResponse {
  success: boolean;
  message: string;
  data: SpotItem[];
}

// 后端返回的数据结构
interface SpotItem {
  id: number;
  name: string;
  lat: number;
  lng: number;
  description: string;
  image: string;  // 图片URL
}

// 前端使用的数据结构
interface ScenicSpot {
  id: string;
  name: string;
  image: Resource;
  rating: number;
  distance: string;
  description: string;
  lat?: number;    // 可选字段，用于地图功能
  lng?: number;    // 可选字段，用于地图功能
}

@Component
export struct RecommendationList {
  @State scenicSpots: ScenicSpot[] = []
  @State isLoading: boolean = true

  aboutToAppear() {
    this.loadScenicSpots()
  }

  async loadScenicSpots() {
    try {
      let httpRequest = http.createHttp()
      let response = await httpRequest.request(
        'http://' + $r('app.string.ip') + '/api/public/spots'
      )

      if (response.responseCode === http.ResponseCode.OK) {
        const result: SpotResponse = JSON.parse(response.result.toString()) as SpotResponse

        if (result.success === true) {
          // 转换后端数据为前端格式
          this.scenicSpots = result.data.map((item: SpotItem): ScenicSpot => {
            return {
              id: item.id.toString(),  // number 转 string
              name: item.name,
              image: this.getImageResource(item.image), // 转换图片
              rating: this.generateRandomRating(),      // 生成随机评分
              distance: this.calculateDistance(item.lat, item.lng), // 计算距离
              description: item.description,
              lat: item.lat,
              lng: item.lng
            }
          })
        }
      }
    } catch (error) {
      console.error('加载景点数据失败:', error)
      // 加载失败时使用默认数据
      this.scenicSpots = this.getDefaultSpots()
    } finally {
      this.isLoading = false
    }
  }

  // 根据图片URL返回对应的Resource
  private getImageResource(imageUrl: string): Resource {
    // 如果后端返回了有效的图片URL，可以在这里处理
    // 目前先用默认图片
    if (imageUrl && imageUrl.trim() !== '') {
      // 这里可以处理网络图片，但鸿蒙需要特殊处理
      console.log('图片URL:', imageUrl)
    }
    return $r('app.media.startIcon') // 默认图片
  }

  // 生成随机评分（4.5-5.0之间）
  private generateRandomRating(): number {
    return 4.5 + Math.random() * 0.5
  }

  // 计算距离（模拟）
  private calculateDistance(lat: number, lng: number): string {
    // 这里可以根据用户当前位置计算真实距离
    // 目前返回模拟距离
    const distances = ['0.5km', '1.2km', '0.8km', '2.1km', '1.5km']
    return distances[Math.floor(Math.random() * distances.length)]
  }

  // 默认数据（网络请求失败时使用）
  private getDefaultSpots(): ScenicSpot[] {
    return [
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
  }

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

      // 加载状态
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(20)
            .height(20)
          Text('加载中...')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 8 })
        }
        .height(120)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
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
            // 这里需要有一个星星图标资源
            Image($r('app.media.startIcon')) // 暂时用其他图标代替
              .width(14)
              .height(14)
            Text(item.rating.toFixed(1))
              .fontSize(12)
              .margin({ left: 4 })
              .fontColor('#FF9500')
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
        params: {
          id: item.id,
          name: item.name,
          description: item.description
        }
      })
    })
  }
}