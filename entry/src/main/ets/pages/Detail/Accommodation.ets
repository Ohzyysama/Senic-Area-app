import { router } from '@kit.ArkUI';

// 住宿数据类型
interface Accommodation {
  id: number;
  name: string;
  type: string; // 酒店类型：酒店、民宿、度假村等
  price: number;
  rating: number;
  image: string;
  location: string;
  distance: string; // 距离景区的距离
  facilities: string[]; // 设施标签
  contact: string;
  description: string;
}

// 页面TS文件
@Entry
@Component
struct AccommodationPage {
  @State accommodationList: Accommodation[] = [];
  @State isLoading: boolean = true;

  // 模拟数据
  private mockData: Accommodation[] = [
    {
      id: 1,
      name: '南昆山温泉度假村',
      type: '度假村',
      price: 688,
      rating: 4.8,
      image: 'common/hotel1.jpg',
      location: '南昆山景区内',
      distance: '距离景区入口500米',
      facilities: ['温泉', '游泳池', '餐厅', '停车场'],
      contact: '0752-1234567',
      description: '集温泉、住宿、餐饮于一体的高端度假村'
    },
    {
      id: 2,
      name: '罗浮山观景民宿',
      type: '民宿',
      price: 328,
      rating: 4.6,
      image: 'common/hotel2.jpg',
      location: '罗浮山脚下',
      distance: '距离山门800米',
      facilities: ['观景台', '免费早餐', 'WiFi'],
      contact: '0752-7654321',
      description: '传统客家风格民宿，视野开阔'
    },
    {
      id: 3,
      name: '引领区精品酒店',
      type: '酒店',
      price: 458,
      rating: 4.5,
      image: 'common/hotel3.jpg',
      location: '引领区核心位置',
      distance: '距离游客中心300米',
      facilities: ['商务中心', '健身房', '会议室'],
      contact: '0752-8888999',
      description: '现代化精品酒店，设施齐全'
    }
  ];

  aboutToAppear() {
    this.loadAccommodationData();
  }

  // 加载住宿数据
  loadAccommodationData() {
    this.isLoading = true;

    // 模拟网络请求
    setTimeout(() => {
      this.accommodationList = this.mockData;
      this.isLoading = false;
    }, 1000);
  }

  // 打电话
  makeCall(phoneNumber: string) {
    // 调用系统打电话功能
    console.log('拨打电话:', phoneNumber);
  }

  build() {
    Column() {
      // 页面标题
      Text('住宿推荐')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 });

      // 加载状态
      if (this.isLoading) {
        this.buildLoadingView()
      } else {
        this.buildAccommodationList()
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

  // 住宿列表
  @Builder buildAccommodationList() {
    List({ space: 16 }) {
      ForEach(this.accommodationList, (item: Accommodation) => {
        ListItem() {
          this.buildAccommodationCard(item)
        }
      }, (item: Accommodation) => item.id.toString())
    }
    .width('100%')
    .layoutWeight(1)
  }

  // 单个住宿卡片
  @Builder buildAccommodationCard(item: Accommodation) {
    Column() {
      // 图片区域
      Row() {
        Image(item.image)
          .width(80)
          .height(80)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#E0E0E0') // 图片加载前的背景色

        // 信息区域
        Column() {
          // 名称和评分
          Row() {
            Text(item.name)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)

            Row() {
              Image($r('app.media.star')) // 星级图标
                .width(16)
                .height(16)
                .margin({ right: 4 })
              Text(item.rating.toString())
                .fontSize(14)
                .fontColor('#FF9500')
            }
          }

          // 类型和位置
          Text(`${item.type} | ${item.location}`)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ top: 4 })

          // 距离
          Text(item.distance)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })

          // 设施标签 - 使用 Flex 布局
          Row() {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(item.facilities, (facility: string, index?: number) => {
                Text(facility)
                  .fontSize(10)
                  .fontColor('#007DFF')
                  .backgroundColor('#E6F2FF')
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .borderRadius(10)
                  .margin({ right: 8, bottom: 4 })
              })
            }
          }
          .margin({ top: 8 })
          .width('100%')

          // 价格和操作区域
          Row() {
            Text(`¥${item.price}`)
              .fontSize(20)
              .fontColor('#FF6B35')
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)

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

      // 描述
      Text(item.description)
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 12 })
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 2, offsetY: 2 })
  }
}