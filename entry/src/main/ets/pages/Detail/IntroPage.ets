import router from '@ohos.router';
import http from '@ohos.net.http';
import { common } from '@kit.AbilityKit';

// 后端响应接口定义
interface IntroResponse {
  success: boolean;
  message: string;
  data: string;  // 后端返回的是字符串，不是对象
}

// 轮播图数据类型定义
interface SwiperItemInfo {
  id: number;
  image: Resource;
  title: string;
  description: string;
}

@Entry
@Component
struct Introduction {
  // 轮播图数据
  private swiperData: Array<SwiperItemInfo> = [
    {
      id: 1,
      image: $r('app.media.nankunshan'),
      title: '南昆山',
      description: '北回归线上的绿洲，被誉为"南国避暑天堂"'
    },
    {
      id: 2,
      image: $r('app.media.luofushan'),
      title: '罗浮山',
      description: '岭南第一山，道教名山，拥有丰富的自然和文化资源'
    },
    {
      id: 3,
      image: $r('app.media.ecological'),
      title: '生态保护',
      description: '坚持绿色发展，构建生态安全屏障'
    },
    {
      id: 4,
      image: $r('app.media.tourism'),
      title: '旅游发展',
      description: '打造国际知名的生态旅游目的地'
    },
    {
      id: 5,
      image: $r('app.media.culture'),
      title: '文化传承',
      description: '弘扬岭南文化，促进文旅融合发展'
    }
  ];

  @State currentIndex: number = 0;
  @State title: string = '南昆山-罗浮山引领区';
  @State content: string = '正在加载引领区介绍...';
  @State isLoading: boolean = true;
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

  aboutToAppear(): void {
    this.loadServerIP()
    this.getIntro();
  }

  async getIntro() {
    try {
      let httpRequest = http.createHttp();
      let response = await httpRequest.request(
        'http://' + `${this.serverIP}` + '/api/public/introduction'  // 修正路径
      );

      console.log('响应状态码:', response.responseCode);
      console.log('响应数据:', response.result.toString());

      if (response.responseCode === http.ResponseCode.OK) {
        // 正确解析后端响应
        const result: IntroResponse = JSON.parse(response.result.toString()) as IntroResponse;

        console.log('解析后的数据:', result);

        if (result.success === true) {
          // 后端返回的是字符串，直接赋值给content
          this.content = result.data;
          this.title = '引领区简介';
        } else {
          this.content = '获取引领区介绍失败: ' + result.message;
        }
      } else {
        this.content = '网络请求失败，状态码: ' + response.responseCode;
        console.error('HTTP请求失败:', response.responseCode, response.result.toString());
      }
    } catch (error) {
      console.error('获取引领区介绍错误:', error);
      this.content = '获取引领区介绍失败，请检查网络连接';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 标题
      Text(this.title)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 });

      // 轮播图容器
      Swiper() {
        ForEach(this.swiperData, (item: SwiperItemInfo) => {
          Column() {
            Image(item.image)
              .borderRadius(10)
              .margin({ top: 20 })
              .width('100%')
              .objectFit(ImageFit.Cover)
              .height(200)

            Text(item.title)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ top: 10 })
              .fontColor('#333333')

            Text(item.description)
              .fontSize(14)
              .margin({ top: 5, bottom: 10 })
              .textAlign(TextAlign.Center)
              .fontColor('#666666')
              .padding({ left: 10, right: 10 })
          }
          .width('100%')
        })
      }
      .index(this.currentIndex)
      .autoPlay(true)
      .interval(3000)
      .indicator(false)
      .loop(true)
      .duration(500)
      .width('90%')
      .height(300)
      .margin({ bottom: 20 })
      .onChange((index: number) => {
        this.currentIndex = index;
      })

      // 指示器
      Row() {
        ForEach(this.swiperData, (item: SwiperItemInfo, index: number) => {
          Circle({ width: 8, height: 8 })
            .fill(index === this.currentIndex ? '#007DFF' : '#CCCCCC')
            .margin({ left: 4, right: 4 })
        })
      }
      .margin({ bottom: 30 })

      // 加载状态
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(30)
            .height(30)
            .color('#007DFF')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 10 })
        }
        .margin({ bottom: 20 })
      }

      // 引领区介绍标题
      Text('引领区详细介绍')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ bottom: 15 })
        .width('90%')
        .textAlign(TextAlign.Start)

      // 引领区介绍内容
      Scroll() {
        Column() {
          Text(this.content)
            .fontSize(16)
            .lineHeight(24)
            .textAlign(TextAlign.Start)
            .fontColor('#444444')
            .width('100%')
        }
        .width('100%')
      }
      .height(200)
      .width('90%')
      .border({ width: 1, color: '#E5E5E5' })
      .borderRadius(8)
      .backgroundColor(Color.White)
      .padding(15)

      // 导航按钮
      Row({ space: 20 }) {
        Button('返回首页')
          .type(ButtonType.Normal)
          .backgroundColor('#007DFF')
          .fontColor(Color.White)
          .borderRadius(20)
          .padding({ left: 30, right: 30 })
          .onClick(() => {
            router.back();
          })

        Button('刷新内容')
          .type(ButtonType.Normal)
          .backgroundColor('#52C41A')
          .fontColor(Color.White)
          .borderRadius(20)
          .padding({ left: 30, right: 30 })
          .onClick(() => {
            this.isLoading = true;
            this.content = '正在重新加载...';
            this.getIntro();
          })
      }
      .margin({ top: 25, bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Center)
  }
}