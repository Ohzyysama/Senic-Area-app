import { router } from '@kit.ArkUI';

// 餐饮数据类型
interface Restaurant {
  id: number;
  name: string;
  type: string; // 菜系类型：中餐、西餐、火锅等
  priceLevel: number; // 价格等级：1-3
  rating: number;
  image: Resource;
  location: string;
  distance: string;
  features: string[]; // 特色标签
  contact: string;
  description: string;
  averageCost: number; // 人均消费
  businessHours: string;
}

// 页面TS文件
@Entry
@Component
struct RestaurantPage {
  @State restaurantList: Restaurant[] = [];
  @State isLoading: boolean = true;

  // 模拟数据
  private mockData: Restaurant[] = [
    {
      id: 1,
      name: '南昆山客家菜馆',
      type: '客家菜',
      priceLevel: 2,
      rating: 4.7,
      image: $r('app.media.restaurant1'),
      location: '南昆山景区入口',
      distance: '距离景区200米',
      features: ['客家酿豆腐', '梅菜扣肉', '环境优雅'],
      contact: '0752-1111111',
      description: '正宗客家风味，选用当地新鲜食材',
      averageCost: 85,
      businessHours: '10:00-21:00'
    },
    {
      id: 2,
      name: '罗浮山素斋馆',
      type: '素食',
      priceLevel: 1,
      rating: 4.5,
      image: $r('app.media.restaurant2'),
      location: '罗浮山寺庙旁',
      distance: '距离寺庙100米',
      features: ['全素宴', '健康养生', '佛家素斋'],
      contact: '0752-2222222',
      description: '传统佛家素斋，清淡健康',
      averageCost: 60,
      businessHours: '08:00-19:00'
    },
    {
      id: 3,
      name: '引领区特色餐厅',
      type: '融合菜',
      priceLevel: 3,
      rating: 4.8,
      image: $r('app.media.restaurant3'),
      location: '引领区商业街',
      distance: '距离游客中心150米',
      features: ['景观位', '创意菜', '网红打卡'],
      contact: '0752-3333333',
      description: '融合当地特色的创意料理',
      averageCost: 120,
      businessHours: '11:00-22:00'
    },
    {
      id: 4,
      name: '山野农家乐',
      type: '农家菜',
      priceLevel: 1,
      rating: 4.4,
      image: $r('app.media.restaurant4'),
      location: '南昆山半山腰',
      distance: '距离登山步道50米',
      features: ['山野时蔬', '土鸡土鸭', '亲民价格'],
      contact: '0752-4444444',
      description: '地道农家风味，食材新鲜',
      averageCost: 65,
      businessHours: '09:00-20:00'
    }
  ];

  aboutToAppear() {
    this.loadRestaurantData();
  }

  // 加载餐饮数据
  loadRestaurantData() {
    this.isLoading = true;

    // 模拟网络请求
    setTimeout(() => {
      this.restaurantList = this.mockData;
      this.isLoading = false;
    }, 1000);
  }


  // 打电话
  makeCall(phoneNumber: string) {
    console.log('拨打电话:', phoneNumber);
  }

  // 获取价格等级显示
  getPriceLevelText(level: number): string {
    switch(level) {
      case 1: return '¥';
      case 2: return '¥¥';
      case 3: return '¥¥¥';
      default: return '¥';
    }
  }

  build() {
    Column() {
      // 页面标题
      Text('餐饮推荐')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 });

      // 加载状态
      if (this.isLoading) {
        this.buildLoadingView()
      } else {
        this.buildRestaurantList()
      }
      Row({ space: 20 }) {
        Button('返回首页')
          .type(ButtonType.Normal)
          .backgroundColor('#666666')
          .onClick(() => {
            router.back();
          })
      }
      .margin({ top: 20, bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F5F5')
  }

  // 加载中视图
  @Builder buildLoadingView() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
      Text('加载中...')
        .fontSize(16)
        .margin({ top: 16 })
        .fontColor('#666666')
    }
    .width('100%')
    .height(400)
    .justifyContent(FlexAlign.Center)
  }

  // 餐厅列表
  @Builder buildRestaurantList() {
    List({ space: 16 }) {
      ForEach(this.restaurantList, (item: Restaurant) => {
        ListItem() {
          this.buildRestaurantCard(item)
        }
      }, (item: Restaurant) => item.id.toString())
    }
    .width('100%')
    .layoutWeight(1)
  }

  // 单个餐厅卡片
  @Builder buildRestaurantCard(item: Restaurant) {
    Column() {
      // 图片区域
      Row() {
        Image(item.image)
          .width(80)
          .height(80)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#E0E0E0')

        // 信息区域
        Column() {
          // 名称和评分
          Row() {
            Text(item.name)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)

            Row() {
              Image($r('app.media.star'))
                .width(16)
                .height(16)
                .margin({ right: 4 })
              Text(item.rating.toString())
                .fontSize(14)
                .fontColor('#FF9500')
            }
          }

          // 类型和价格等级
          Row() {
            Text(item.type)
              .fontSize(12)
              .fontColor('#666666')

            Text(' • ')
              .fontSize(12)
              .fontColor('#666666')

            Text(this.getPriceLevelText(item.priceLevel))
              .fontSize(12)
              .fontColor('#FF6B35')

            Text(' • ')
              .fontSize(12)
              .fontColor('#666666')

            Text(`人均¥${item.averageCost}`)
              .fontSize(12)
              .fontColor('#666666')
          }
          .margin({ top: 4 })
          .width('100%')

          // 位置和距离
          Text(`${item.location} | ${item.distance}`)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })

          // 营业时间
          Text(`营业时间: ${item.businessHours}`)
            .fontSize(11)
            .fontColor('#888888')
            .margin({ top: 2 })

          // 特色标签
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(item.features, (feature: string, index?: number) => {
              Text(feature)
                .fontSize(10)
                .fontColor('#E64A19')
                .backgroundColor('#FFECB3')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(10)
                .margin({ right: 8, bottom: 4 })
            })
          }
          .margin({ top: 8 })

          // 操作区域
          Row() {
            Text(item.description)
              .fontSize(12)
              .fontColor('#666666')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })

            Row({ space: 12 }) {
              // 电话按钮
              Button() {
                Row() {
                  Image($r('app.media.phone'))
                    .width(16)
                    .height(16)
                    .margin({ right: 4 })
                  Text('联系')
                    .fontSize(12)
                    .fontColor(Color.White)
                }
                .justifyContent(FlexAlign.Center)
                .width('100%')
              }
              .type(ButtonType.Normal)
              .backgroundColor('#4CAF50')
              .width(70)
              .height(32)
              .onClick(() => this.makeCall(item.contact))
            }
          }
          .margin({ top: 12 })
          .width('100%')
        }
        .margin({ left: 12 })
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 2, offsetY: 2 })
  }
}