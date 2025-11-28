import { router } from "@kit.ArkUI"
import http from '@ohos.net.http';
import { common } from "@kit.AbilityKit";

// 后端响应接口定义
interface NearbyResponse {
  success: boolean;
  message: string;
  data: SpotItem[];
}

interface SpotItem {
  id: number;
  name: string;
  lat: number;
  lng: number;
  description: string;
  image: string;
}

// 前端使用的商家数据结构
interface Business {
  id: string;
  name: string;
  image: Resource;
  rating: number;
  type: string;
  distance: string;
  description: string;
  priceLevel: string;
  features: string[];
  lat?: number;
  lng?: number;
}

// 使用枚举和Map替代索引签名
enum BusinessType {
  ACCOMMODATION = '住宿',
  DINING = '餐饮',
  SHOPPING = '购物',
  LEISURE = '休闲',
  SCENIC = '景点'
}

@Component
export struct BusinessRecommendationList {
  @State businesses: Business[] = []
  @State isLoading: boolean = true
  @State serverIP:string = ''

  private async loadServerIP() {
    this.serverIP = await this.getServerIP();
    console.log('加载的服务器IP:', this.serverIP);
  }

  private async getServerIP(): Promise<string> {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      const resourceMgr = context.resourceManager;
      const ipValue = await resourceMgr.getString($r('app.string.ip').id);
      return ipValue;
    } catch (error) {
      console.error('获取服务器IP失败:', error);
      return 'localhost:8080';
    }
  }

  // 使用数组替代对象映射
  private businessTypes: string[] = ['住宿', '餐饮', '购物', '休闲', '景点']

  // 使用Map存储价格权重
  private priceWeights: Map<string, number> = new Map([
    ['住宿', 2], // 偏向高价
    ['餐饮', 1], // 中等
    ['购物', 0], // 低价
    ['休闲', 1], // 中等
    ['景点', 0]  // 低价
  ])

  // 使用Map存储特色标签
  private featurePools: Map<string, string[]> = new Map([
    ['住宿', ['温泉', '游泳池', '免费停车', 'WiFi', '早餐', '接驳服务']],
    ['餐饮', ['客家菜', '本地特色', '环境优美', '包间', '停车', '外卖']],
    ['购物', ['特产', '手工艺品', '价格实惠', '包邮', '礼品', '免税']],
    ['休闲', ['观景台', '功夫茶', '茶点', '休息区', 'WiFi', '书吧']],
    ['景点', ['观景', '拍照', '徒步', '自然风光', '文化', '历史']]
  ])

  aboutToAppear() {
    this.loadServerIP()
    this.loadNearbyBusinesses()
  }

  async loadNearbyBusinesses() {
    try {
      // 获取用户当前位置（这里需要实际的位置获取逻辑）
      const userLat = 31.2304  // 模拟用户纬度
      const userLng = 121.4737 // 模拟用户经度

      let httpRequest = http.createHttp()
      let response = await httpRequest.request(
        `http://${this.serverIP}/api/public/nearby?lat=${userLat}&lng=${userLng}&limit=5`
      )

      if (response.responseCode === http.ResponseCode.OK) {
        const result: NearbyResponse = JSON.parse(response.result.toString()) as NearbyResponse

        if (result.success === true) {
          // 转换景点数据为商家数据
          this.businesses = result.data.map((item: SpotItem): Business => {
            const businessType = this.guessBusinessType(item.name, item.description)
            return {
              id: item.id.toString(),
              name: item.name,
              image: this.getImageResource(item.image),
              rating: this.generateRandomRating(),
              type: businessType,
              distance: this.calculateDistance(item.lat, item.lng, userLat, userLng),
              description: item.description,
              priceLevel: this.generatePriceLevel(businessType),
              features: this.generateFeatures(businessType),
              lat: item.lat,
              lng: item.lng
            }
          })
        }
      }
    } catch (error) {
      console.error('加载附近商家失败:', error)
      // 使用默认数据
      this.businesses = this.getDefaultBusinesses()
    } finally {
      this.isLoading = false
    }
  }

  // 根据名称和描述推测商家类型
  private guessBusinessType(name: string, description: string): string {
    const text = (name + description).toLowerCase()

    if (text.includes('酒店') || text.includes('住宿') || text.includes('客栈') || text.includes('宾馆')) {
      return BusinessType.ACCOMMODATION
    } else if (text.includes('餐厅') || text.includes('饭店') || text.includes('美食') || text.includes('餐馆')) {
      return BusinessType.DINING
    } else if (text.includes('商店') || text.includes('超市') || text.includes('特产') || text.includes('商场')) {
      return BusinessType.SHOPPING
    } else if (text.includes('茶') || text.includes('咖啡') || text.includes('休闲') || text.includes('酒吧')) {
      return BusinessType.LEISURE
    } else {
      // 随机返回一个类型
      return this.businessTypes[Math.floor(Math.random() * this.businessTypes.length)]
    }
  }

  // 生成随机评分
  private generateRandomRating(): number {
    return 4.0 + Math.random() * 1.0 // 4.0-5.0之间
  }

  // 计算距离
  private calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): string {
    // 简化版距离计算（实际应该使用Haversine公式）
    const distance = Math.sqrt(Math.pow(lat1 - lat2, 2) + Math.pow(lng1 - lng2, 2)) * 111
    if (distance < 1) {
      return `${Math.round(distance * 1000)}m`
    } else {
      return `${distance.toFixed(1)}km`
    }
  }

  // 生成价格等级
  private generatePriceLevel(type: string): string {
    // 使用Map获取权重
    const weight = this.priceWeights.get(type) || 1
    const level = Math.min(weight + Math.floor(Math.random() * 2), 2)
    return '¥'.repeat(level + 1)
  }

  // 生成特色标签
  private generateFeatures(type: string): string[] {
    // 使用Map获取特色标签
    const features = this.featurePools.get(type) || this.featurePools.get('景点') || []
    const count = 2 + Math.floor(Math.random() * 2) // 2-3个标签

    // 随机选择特征
    const shuffled = [...features].sort(() => 0.5 - Math.random())
    return shuffled.slice(0, count)
  }

  // 图片资源处理
  private getImageResource(imageUrl: string): Resource {
    // 根据图片URL返回对应资源（简化处理）
    if (imageUrl && imageUrl.trim() !== '') {
      console.log('图片URL:', imageUrl)
      // 这里可以处理网络图片，但鸿蒙需要特殊处理
    }
    return $r('app.media.startIcon') // 默认图片
  }

  // 默认数据
  private getDefaultBusinesses(): Business[] {
    return [
      {
        id: '1',
        name: '南昆山温泉度假酒店',
        image: $r('app.media.startIcon'),
        rating: 4.8,
        type: '住宿',
        distance: '1.5km',
        description: '五星级温泉度假，环境优雅舒适',
        priceLevel: '¥¥¥',
        features: ['温泉', '游泳池', '免费停车']
      },
      {
        id: '2',
        name: '客家风味餐厅',
        image: $r('app.media.startIcon'),
        rating: 4.6,
        type: '餐饮',
        distance: '0.8km',
        description: '正宗客家菜，食材新鲜地道',
        priceLevel: '¥¥',
        features: ['客家酿豆腐', '梅菜扣肉', '环境优美']
      },
      {
        id: '3',
        name: '山野特产商店',
        image: $r('app.media.startIcon'),
        rating: 4.5,
        type: '购物',
        distance: '1.2km',
        description: '当地特产，纪念品精选',
        priceLevel: '¥',
        features: ['山货', '手工艺品', '价格实惠']
      },
      {
        id: '4',
        name: '罗浮山茶社',
        image: $r('app.media.startIcon'),
        rating: 4.7,
        type: '休闲',
        distance: '2.1km',
        description: '传统茶艺，观景品茗',
        priceLevel: '¥¥',
        features: ['观景台', '功夫茶', '茶点']
      }
    ]
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('附近推荐')
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
          Text('加载附近推荐...')
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 8 })
        }
        .height(120)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        // 商家列表
        List({ space: 12 }) {
          ForEach(this.businesses, (item: Business) => {
            ListItem() {
              this.BuildBusinessItem(item)
            }
          }, (item: Business) => item.id)
        }
        .height(320)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder BuildBusinessItem(item: Business) {
    Row() {
      // 商家图片
      Image(item.image)
        .width(80)
        .height(80)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)

      // 商家信息
      Column() {
        // 名称和类型
        Row() {
          Text(item.name)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text(item.type)
            .fontSize(12)
            .fontColor('#007DFF')
            .backgroundColor('#E6F2FF')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
        }
        .width('100%')
        .margin({ bottom: 4 })

        // 描述
        Text(item.description)
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(2)
          .margin({ bottom: 8 })

        // 特色标签
        Row() {
          ForEach(item.features.slice(0, 2), (feature: string) => {
            Text(feature)
              .fontSize(10)
              .fontColor('#E64A19')
              .backgroundColor('#FFECB3')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(8)
              .margin({ right: 6 })
          })

          if (item.features.length > 2) {
            Text(`+${item.features.length - 2}`)
              .fontSize(10)
              .fontColor('#666666')
              .backgroundColor('#F0F0F0')
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(8)
          }
        }
        .width('100%')
        .margin({ bottom: 8 })

        // 评分、距离和价格
        Row() {
          // 评分
          Row() {
            Image($r('app.media.startIcon')) // 暂时用其他图标代替星星
              .width(14)
              .height(14)
            Text(item.rating.toFixed(1))
              .fontSize(12)
              .margin({ left: 4 })
              .fontColor('#FF9500')
          }

          // 距离
          Text(item.distance)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 12 })

          // 价格等级
          Text(item.priceLevel)
            .fontSize(12)
            .fontColor('#4CAF50')
            .fontWeight(FontWeight.Medium)
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
    .height(100)
    .padding(12)
    .backgroundColor('#F9F9F9')
    .borderRadius(12)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/BusinessDetailPage',
        params: {
          id: item.id,
          type: item.type
        }
      })
    })
  }
}