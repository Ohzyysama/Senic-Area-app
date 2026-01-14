// entry/src/main/ets/pages/MapPage.ets
import { router } from '@kit.ArkUI'
import { TabBar } from '../pages/components/TabBar'
import { SpotModel, SpotInfo } from '../model/SpotModel'
import http from '@ohos.net.http'
import { common } from '@kit.AbilityKit'

// 后端返回的景点数据接口
interface SpotResp {
  id: number;
  name: string;
  lat: number | null;
  lng: number | null;
  description: string;
  image: string;
}

// API响应接口
interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

@Entry
@Component
export default struct MapPage {
  @State spots: SpotInfo[] = [];
  @State selectedSpot: SpotInfo | null = null;
  @State isLoading: boolean = true;
  @State serverIP: string = '';
  
  // 地图变换状态
  @State mapScale: number = 1.0;  // 缩放比例（避免与组件scale属性冲突）
  @State offsetX: number = 0;   // X轴偏移
  @State offsetY: number = 0;   // Y轴偏移
  @State lastScale: number = 1.0;  // 上次缩放值
  @State lastOffsetX: number = 0;  // 上次X偏移
  @State lastOffsetY: number = 0;  // 上次Y偏移
  
  // 地图尺寸
  private mapWidth: number = 0;
  private mapHeight: number = 350;

  aboutToAppear() {
    this.loadServerIP();
    this.loadSpots();
  }

  private async loadServerIP() {
    this.serverIP = await this.getServerIP();
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

  // 从后端加载景点列表
  private async loadSpots() {
    try {
      await this.loadServerIP();
      let httpRequest = http.createHttp();
      let response = await httpRequest.request(
        `http://${this.serverIP}/api/public/spots`
      );

      if (response.responseCode === http.ResponseCode.OK) {
        const result: ApiResponse<SpotResp[]> = JSON.parse(response.result.toString()) as ApiResponse<SpotResp[]>;
        
        if (result.success && result.data && result.data.length > 0) {
          // 将后端数据转换为前端SpotInfo格式
          this.spots = result.data.map((spot: SpotResp, index: number) => {
            // 根据索引计算地图上的x, y位置（如果没有经纬度，使用默认布局）
            let x = 25 + (index % 3) * 30;
            let y = 20 + Math.floor(index / 3) * 30;
            
            // 如果有经纬度，可以根据经纬度计算位置（这里简化处理，使用索引布局）
            if (spot.lat !== null && spot.lng !== null) {
              // 可以根据实际地图范围计算位置，这里暂时使用索引布局
              x = 25 + (index % 3) * 30;
              y = 20 + Math.floor(index / 3) * 30;
            }

            // 将后端图片URL转换为Resource（如果image是URL，需要处理）
            let imageResource: Resource = $r('app.media.nankunshan'); // 默认图片
            // 如果后端返回的是URL，这里需要根据实际情况处理
            // 暂时使用默认图片资源

            return {
              id: spot.id,
              name: spot.name,
              x: x,
              y: y,
              description: spot.description || '暂无描述',
              image: imageResource,
              rating: 4.5, // 后端没有评分，使用默认值
              visitCount: 0, // 后端没有访问次数，使用默认值
              category: '景点', // 后端没有类别，使用默认值
              address: '景区内', // 后端没有地址，使用默认值
              openingHours: '全天开放', // 后端没有开放时间，使用默认值
              ticketPrice: '免费', // 后端没有门票价格，使用默认值
              features: [] // 后端没有特色标签，使用空数组
            } as SpotInfo;
          });
        } else {
          // 后端返回空数据，使用假数据
          this.spots = SpotModel.getAllSpots();
        }
      } else {
        // 请求失败，使用假数据
        this.spots = SpotModel.getAllSpots();
      }
    } catch (error) {
      console.error('加载景点列表失败:', error);
      // 如果加载失败，使用本地数据作为后备
      this.spots = SpotModel.getAllSpots();
    } finally {
      this.isLoading = false;
    }
  }

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

      // 地图区域 - 可缩放和移动（固定高度，确保不滑动能看到）
      Stack() {
        // 地图容器
        Stack() {
          Image($r('app.media.map'))
            .width('100%')
            .height(350)
            .objectFit(ImageFit.Cover)
            .id('mapImage')

          // 景点标记
          if (this.isLoading) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#007DFF')
          } else {
            ForEach(this.spots, (spot: SpotInfo) => {
              this.BuildSpotMarker(spot)
            }, (item: SpotInfo) => item.id.toString())
          }
        }
        .width('100%')
        .height(350)
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
      .height(350)
      .margin({ top: 10, bottom: 5 })
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
      .padding({ top: 5, bottom: 5 })

      // 景点列表卡片 - 横向滑动（固定高度，确保不滑动能看到）
      Column() {
        Text('景点推荐')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, top: 8, bottom: 6 })
        
        Scroll() {
          Row({ space: 12 }) {
            if (this.isLoading) {
              LoadingProgress()
                .width(30)
                .height(30)
                .color('#007DFF')
            } else if (this.spots.length === 0) {
              Text('暂无景点数据')
                .fontSize(14)
                .fontColor('#999999')
                .padding(20)
            } else {
              ForEach(this.spots, (spot: SpotInfo) => {
                this.BuildSpotCard(spot)
              }, (item: SpotInfo) => item.id.toString())
            }
          }
          .padding({ left: 16, right: 16, bottom: 16 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto)
        .width('100%')
        .height(160)
      }

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

      // 景点名称标签 - 自然样式，无背景框
      Text(spot.name)
        .fontSize(14 * this.mapScale)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .fontFamily('sans-serif')
        .margin({ top: 4 * this.mapScale })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textShadow({ radius: 2, color: '#FFFFFF', offsetX: 1, offsetY: 1 })
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
