// entry/src/main/ets/pages/MapPage.ets
import { router } from '@kit.ArkUI'
import { TabBar } from '../pages/components/TabBar'
import { SpotModel, SpotInfo } from '../model/SpotModel'

@Entry
@Component
export default struct MapPage {
  @State spots: SpotInfo[] = SpotModel.getAllSpots();
  @State selectedSpot: SpotInfo | null = null;
  
  // 地图变换状态
  @State mapScale: number = 1.0;  // 缩放比例（避免与组件scale属性冲突）
  @State offsetX: number = 0;   // X轴偏移
  @State offsetY: number = 0;   // Y轴偏移
  @State lastScale: number = 1.0;  // 上次缩放值
  @State lastOffsetX: number = 0;  // 上次X偏移
  @State lastOffsetY: number = 0;  // 上次Y偏移
  
  // 地图尺寸
  private mapWidth: number = 0;
  private mapHeight: number = 450;

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

      // 地图区域 - 可缩放和移动
      Stack() {
        // 地图容器
        Stack() {
          Image($r('app.media.map'))
            .width('100%')
            .height(450)
            .objectFit(ImageFit.Cover)
            .id('mapImage')

          // 景点标记
          ForEach(this.spots, (spot: SpotInfo) => {
            this.BuildSpotMarker(spot)
          }, (item: SpotInfo) => item.id.toString())
        }
        .width('100%')
        .height(450)
        .clip(true)
        .scale({ x: this.mapScale, y: this.mapScale, centerX: '50%', centerY: '50%' })
        .translate({ x: this.offsetX / this.mapScale, y: this.offsetY / this.mapScale })
        .gesture(
          GestureGroup(GestureMode.Parallel,
            // 缩放手势
            PinchGesture({ fingers: 2 })
              .onActionStart((event?: GestureEvent) => {
                this.lastScale = this.mapScale;
              })
              .onActionUpdate((event?: GestureEvent) => {
                if (event) {
                  let newScale = this.lastScale * event.scale;
                  // 限制缩放范围 0.5x - 3x
                  newScale = Math.max(0.5, Math.min(3.0, newScale));
                  this.mapScale = newScale;
                }
              })
              .onActionEnd(() => {
                this.lastScale = this.mapScale;
              }),
            // 拖动手势
            PanGesture({ fingers: 1, direction: PanDirection.All, distance: 1 })
              .onActionStart((event?: GestureEvent) => {
                this.lastOffsetX = this.offsetX;
                this.lastOffsetY = this.offsetY;
              })
              .onActionUpdate((event?: GestureEvent) => {
                if (event) {
                  this.offsetX = this.lastOffsetX + event.offsetX;
                  this.offsetY = this.lastOffsetY + event.offsetY;
                  // 限制拖动范围，防止地图移出视野
                  this.limitMapOffset();
                }
              })
              .onActionEnd(() => {
                this.lastOffsetX = this.offsetX;
                this.lastOffsetY = this.offsetY;
              })
          )
        )
      }
      .width('100%')
      .height(450)
      .margin({ top: 10, bottom: 10 })
      .onAreaChange((oldValue: Area, newValue: Area) => {
        // 获取地图容器的实际宽度
        if (newValue && newValue.width !== undefined) {
          const width = newValue.width;
          if (typeof width === 'number') {
            this.mapWidth = width;
          } else {
            // 如果是字符串类型（如百分比），使用默认值
            this.mapWidth = 100;
          }
        }
      })

      // 缩放控制按钮
      Row() {
        Button('+')
          .width(40)
          .height(40)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#FFFFFF')
          .fontColor('#333333')
          .borderRadius(20)
          .onClick(() => {
            this.zoomIn();
          })

        Button('−')
          .width(40)
          .height(40)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .backgroundColor('#FFFFFF')
          .fontColor('#333333')
          .borderRadius(20)
          .margin({ left: 8 })
          .onClick(() => {
            this.zoomOut();
          })

        Button('重置')
          .width(60)
          .height(40)
          .fontSize(14)
          .backgroundColor('#007DFF')
          .fontColor('#FFFFFF')
          .borderRadius(20)
          .margin({ left: 8 })
          .onClick(() => {
            this.resetMap();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 8, bottom: 8 })

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

  // 构建景点标记
  @Builder
  BuildSpotMarker(spot: SpotInfo) {
    Column() {
      // 标记点
      Column() {
        Text('📍')
          .fontSize(28 * this.mapScale)
      }
      .width(40 * this.mapScale)
      .height(40 * this.mapScale)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderRadius(20 * this.mapScale)
      .shadow({ radius: 4, color: '#40000000', offsetX: 0, offsetY: 2 })

      // 景点名称标签
      Text(spot.name)
        .fontSize(12 * this.mapScale)
        .fontColor('#FFFFFF')
        .backgroundColor('#007DFF')
        .padding({ 
          left: 8 * this.mapScale, 
          right: 8 * this.mapScale, 
          top: 4 * this.mapScale, 
          bottom: 4 * this.mapScale 
        })
        .borderRadius(4 * this.mapScale)
        .margin({ top: 4 * this.mapScale })
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
  }

  // 限制地图偏移范围
  limitMapOffset() {
    const maxOffsetX = (this.mapWidth || 100) * (this.mapScale - 1) / 2;
    const maxOffsetY = this.mapHeight * (this.mapScale - 1) / 2;
    
    this.offsetX = Math.max(-maxOffsetX, Math.min(maxOffsetX, this.offsetX));
    this.offsetY = Math.max(-maxOffsetY, Math.min(maxOffsetY, this.offsetY));
  }

  // 放大
  zoomIn() {
    this.lastScale = this.mapScale;
    this.mapScale = Math.min(3.0, this.mapScale + 0.2);
    this.limitMapOffset();
    this.lastScale = this.mapScale;
  }

  // 缩小
  zoomOut() {
    this.lastScale = this.mapScale;
    this.mapScale = Math.max(0.5, this.mapScale - 0.2);
    this.limitMapOffset();
    this.lastScale = this.mapScale;
  }

  // 重置地图
  resetMap() {
    this.mapScale = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;
    this.lastScale = 1.0;
    this.lastOffsetX = 0;
    this.lastOffsetY = 0;
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
