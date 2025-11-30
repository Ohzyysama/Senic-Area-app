import router from '@ohos.router';
import http from '@ohos.net.http';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';

// 后端响应接口
interface PrizeListResponse {
  success: boolean;
  message: string;
  data: PrizeItemResponse[];
}

// 后端返回的奖品数据结构
interface PrizeItemResponse {
  id: number;
  name: string;
  points: number;
  stock: number;
  description: string;
  image: string;
  status: number;
}

// 前端使用的奖品数据结构
interface PrizeItem {
  id: number;
  name: string;
  description: string;
  image: string;
  pointsRequired: number;
  originalPrice: number;
  stock: number;
  category: string;
  status: number;
}

// 兑换请求接口
interface ExchangeRequest {
  prizeId: number;
}

// 兑换数据接口
interface ExchangeData {
  exchangeCode: string;
}

// 兑换响应接口
interface ExchangeResponse {
  success: boolean;
  message: string;
  data: ExchangeData;
}

// 积分记录接口
interface PointsRecord {
  id: number;
  type: string;
  points: number;
  balance: number;
  sourceId: number;
  description: string;
  createdAt: string;
}

// 积分明细数据接口
interface PointsListData {
  content: PointsRecord[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

// 积分明细响应接口
interface PointsListResponse {
  success: boolean;
  message: string;
  data: PointsListData;
}

@Entry
@Component
struct PointsMall {
  @State prizeList: PrizeItem[] = [];
  @State userPoints: number = 1280;
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '';
  @State currentPage: number = 1;
  @State hasMore: boolean = false;
  @State isExchanging: boolean = false;
  @State showPointsDetail: boolean = false;
  @State pointsRecords: PointsRecord[] = [];
  @State pointsLoading: boolean = false;
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

  // 用户信息
  @StorageLink('userInfo') storedUserInfo: StoredUserData = {
    userId: '',
    token: '',
    nickName: '',
    avatar: ''
  };

  // 奖品分类映射
  private categoryMap: Map<string, string> = new Map([
    ['徽章', '收藏品'],
    ['卡券', '虚拟卡券'],
    ['耳机', '数码配件'],
    ['充电', '数码配件'],
    ['电影', '娱乐休闲'],
    ['月卡', '会员服务'],
    ['套餐', '餐饮美食'],
    ['保温杯', '生活用品'],
    ['伞', '生活用品'],
    ['笔记本', '文具用品']
  ]);

  private async loadDataSequentially() {
    console.log('开始加载数据...');

    // 先加载服务器IP
    await this.loadServerIP();
    console.log('服务器IP加载完成:', this.serverIP);

    // 然后加载用户资料
    await this.loadPrizeList();
    console.log('用户资料加载完成');

    await this.loadUserPoints();
  }

  aboutToAppear() {
    this.loadDataSequentially()
  }

  build() {
    Column() {
      // 顶部导航栏
      this.BuildHeader()

      if (this.isLoading && this.prizeList.length === 0) {
        this.BuildLoading()
      } else if (this.isError && this.prizeList.length === 0) {
        this.BuildError()
      } else {
        // 用户积分信息
        this.BuildPointsInfo()

        // 积分商城列表
        this.BuildPrizeList()

        // 加载更多
        if (this.hasMore && !this.isLoading) {
          this.BuildLoadMore()
        }
      }

      // 积分明细弹窗
      if (this.showPointsDetail) {
        this.BuildPointsDetailModal()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F6FA')
  }

  @Builder BuildHeader() {
    Row() {
      Image($r('app.media.startIcon'))
        .width(24)
        .height(24)
        .fillColor('#333333')
        .onClick(() => {
          router.back();
        })

      Text('积分商城')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ left: 12 })

      Blank()

      // 积分明细按钮
      Button('积分明细', { type: ButtonType.Normal })
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#E6F7FF')
        .fontColor('#007DFF')
        .fontSize(12)
        .onClick(() => {
          this.viewPointsDetail();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
  }

  @Builder BuildLoading() {
    Column() {
      LoadingProgress()
        .width(50)
        .height(50)
        .color('#007DFF')

      Text('加载中...')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 16 })
    }
    .width('100%')
    .height(400)
    .justifyContent(FlexAlign.Center)
  }

  @Builder BuildError() {
    Column() {
      Image($r('app.media.startIcon'))
        .width(80)
        .height(80)
        .margin({ bottom: 16 })

      Text(this.errorMessage || '加载失败')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 20 })

      Button('重新加载')
        .type(ButtonType.Capsule)
        .width(120)
        .height(36)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .onClick(() => {
          this.loadPrizeList();
        })
    }
    .width('100%')
    .height(400)
    .justifyContent(FlexAlign.Center)
  }

  @Builder BuildPointsInfo() {
    Column({ space: 12 }) {
      Row() {
        Text('我的积分')
          .fontSize(16)
          .fontColor('#666666')

        Blank()

        Text(this.userPoints.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B35')
      }
      .width('100%')

      Text('积分可以兑换精美礼品')
        .fontSize(12)
        .fontColor('#999999')
        .width('100%')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .margin({ top: 8 })
  }

  @Builder BuildPrizeList() {
    Scroll() {
      Grid() {
        ForEach(this.prizeList, (prize: PrizeItem) => {
          GridItem() {
            this.BuildPrizeCard(prize)
          }
        }, (prize: PrizeItem) => prize.id.toString())
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .padding(16)
    }
    .layoutWeight(1)
  }

  @Builder BuildPrizeCard(prize: PrizeItem) {
    Column({ space: 12 }) {
      // 奖品图片
      Stack() {
        // 使用默认图标，因为图片URL可能为空
        Image($r('app.media.startIcon'))
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .backgroundColor('#F0F0F0')

        // 奖品名称
        Text(prize.name)
          .fontSize(12)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding(8)
          .width('100%')
          .textAlign(TextAlign.Center)

        // 状态标签
        if (prize.status !== 1) {
          Text('已下架')
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor('#999999')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
            .align(Alignment.TopStart)
            .margin({ top: 8, left: 8 })
        } else if (prize.stock <= 10 && prize.stock > 0) {
          Text(`仅剩${prize.stock}件`)
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor('#FF4D4F')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
            .align(Alignment.TopStart)
            .margin({ top: 8, left: 8 })
        } else if (prize.stock === 0) {
          Text('已售罄')
            .fontSize(10)
            .fontColor(Color.White)
            .backgroundColor('#999999')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .borderRadius(4)
            .align(Alignment.TopStart)
            .margin({ top: 8, left: 8 })
        }
      }
      .width('100%')
      .height(120)

      // 奖品信息
      Column({ space: 8 }) {
        Text(prize.name)
          .fontSize(14)
          .fontColor('#333333')
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)
          .width('100%')

        Row() {
          Text(prize.pointsRequired.toString())
            .fontSize(16)
            .fontColor('#FF6B35')
            .fontWeight(FontWeight.Bold)

          Text('积分')
            .fontSize(12)
            .fontColor('#FF6B35')
            .margin({ left: 2 })

          Blank()

          Text(`价值: ¥${prize.originalPrice}`)
            .fontSize(10)
            .fontColor('#999999')
            .decoration({ type: TextDecorationType.LineThrough })
        }
        .width('100%')

        // 分类标签
        Text(prize.category)
          .fontSize(10)
          .fontColor('#007DFF')
          .backgroundColor('#E6F7FF')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
          .alignSelf(ItemAlign.Start)

        // 兑换按钮
        Button(this.getButtonText(prize), { type: ButtonType.Normal })
          .width('100%')
          .height(32)
          .backgroundColor(this.getButtonColor(prize))
          .fontColor(Color.White)
          .fontSize(12)
          .enabled(this.canExchange(prize) && !this.isExchanging)
          .onClick(() => {
            this.exchangePrize(prize);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 2, offsetY: 2 })
  }

  @Builder BuildLoadMore() {
    Button('加载更多', { type: ButtonType.Normal })
      .width('90%')
      .height(40)
      .backgroundColor('#F0F0F0')
      .fontColor('#666666')
      .fontSize(14)
      .margin({ top: 16, bottom: 16 })
      .onClick(() => {
        this.loadMorePrizes();
      })
  }

  @Builder BuildPointsDetailModal() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 半透明背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .onClick(() => {
          this.showPointsDetail = false;
        })

      // 积分明细内容
      Column({ space: 0 }) {
        // 标题栏
        Row() {
          Text('积分明细')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')

          Blank()

          Image($r('app.media.startIcon'))
            .width(20)
            .height(20)
            .fillColor('#666666')
            .onClick(() => {
              this.showPointsDetail = false;
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)

        // 积分记录列表
        if (this.pointsLoading) {
          Column() {
            LoadingProgress()
              .width(30)
              .height(30)
            Text('加载中...')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 12 })
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
        } else if (this.pointsRecords.length === 0) {
          Column() {
            Image($r('app.media.startIcon'))
              .width(60)
              .height(60)
              .margin({ bottom: 12 })
            Text('暂无积分记录')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.pointsRecords, (record: PointsRecord) => {
              ListItem() {
                this.BuildPointsRecordItem(record)
              }
            }, (record: PointsRecord) => record.id.toString())
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .height('70%')
      .backgroundColor(Color.White)
      .borderRadius({ topLeft: 16, topRight: 16 })
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Bottom)
  }

  @Builder BuildPointsRecordItem(record: PointsRecord) {
    Row() {
      Column({ space: 4 }) {
        Text(record.description)
          .fontSize(16)
          .fontColor('#333333')
          .textAlign(TextAlign.Start)
          .width('100%')

        Text(this.formatDate(record.createdAt))
          .fontSize(12)
          .fontColor('#999999')
          .textAlign(TextAlign.Start)
          .width('100%')
      }
      .layoutWeight(1)

      Column({ space: 2 }) {
        Text(record.points > 0 ? `+${record.points}` : record.points.toString())
          .fontSize(16)
          .fontColor(record.points > 0 ? '#52C41A' : '#FF4D4F')
          .fontWeight(FontWeight.Medium)

        Text(`余额: ${record.balance}`)
          .fontSize(12)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }

  // 根据名称推测分类
  private guessCategory(name: string): string {
    const lowerName = name.toLowerCase();
    const keys = Array.from(this.categoryMap.keys());
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = this.categoryMap.get(key);
      if (value && lowerName.includes(key.toLowerCase())) {
        return value;
      }
    }
    return '其他';
  }

  // 加载奖品列表
  private async loadPrizeList() {
    this.isLoading = true;
    this.isError = false;

    try {
      let httpRequest = http.createHttp();
      let url = 'http://' + `${this.serverIP}` + '/api/prize/list';

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json'
        },
        readTimeout: 60000,
        connectTimeout: 60000
      } as http.HttpRequestOptions;

      httpRequest.request(url, options, (err: Error, data: http.HttpResponse) => {
        this.isLoading = false;

        if (err) {
          console.error('请求失败: ' + JSON.stringify(err));
          this.isError = true;
          this.errorMessage = '网络请求失败';
          return;
        }

        if (data.responseCode === 200) {
          try {
            const resultString: string = data.result.toString();
            const result: PrizeListResponse = JSON.parse(resultString) as PrizeListResponse;

            console.log('奖品列表响应:', result);

            if (result.success === true) {
              this.prizeList = result.data.map((item: PrizeItemResponse): PrizeItem => {
                return {
                  id: item.id,
                  name: item.name,
                  description: item.description,
                  image: item.image,
                  pointsRequired: item.points,
                  originalPrice: this.calculateOriginalPrice(item.points),
                  stock: item.stock,
                  category: this.guessCategory(item.name),
                  status: item.status
                };
              });
              this.hasMore = false;
            } else {
              this.isError = true;
              this.errorMessage = result.message || '获取奖品列表失败';
            }
          } catch (parseError) {
            console.error('数据解析失败:', parseError);
            this.isError = true;
            this.errorMessage = '数据解析失败';
          }
        } else {
          this.isError = true;
          this.errorMessage = `请求失败: ${data.responseCode}`;
        }

        httpRequest.destroy();
      });
    } catch (error) {
      this.isLoading = false;
      this.isError = true;
      this.errorMessage = '网络异常';
      console.error('加载奖品列表异常: ' + JSON.stringify(error));
    }
  }

  // 加载用户积分
  private async loadUserPoints() {
    // 这里可以从用户信息接口获取真实积分
    // 暂时使用模拟数据
    console.log('加载用户积分');
  }

  // 兑换奖品 - 真实API调用
  private async exchangePrize(prize: PrizeItem) {
    if (!this.canExchange(prize)) {
      return;
    }

    // 检查用户是否登录
    const token = this.storedUserInfo.token;
    if (!token) {
      promptAction.showToast({
        message: '请先登录',
        duration: 2000
      });
      return;
    }

    this.isExchanging = true;

    try {
      let httpRequest = http.createHttp();
      let url = 'http://' + `${this.serverIP}` + '/api/prize/exchange';

      const requestData: ExchangeRequest = {
        prizeId: prize.id
      };

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        extraData: JSON.stringify(requestData),
        readTimeout: 60000,
        connectTimeout: 60000
      } as http.HttpRequestOptions;

      httpRequest.request(url, options, (err: Error, data: http.HttpResponse) => {
        this.isExchanging = false;

        if (err) {
          console.error('兑换失败: ' + JSON.stringify(err));
          promptAction.showToast({
            message: '兑换失败，请重试',
            duration: 2000
          });
          return;
        }

        if (data.responseCode === 200) {
          try {
            const resultString: string = data.result.toString();
            const result: ExchangeResponse = JSON.parse(resultString) as ExchangeResponse;

            if (result.success === true) {
              // 兑换成功
              this.userPoints -= prize.pointsRequired;

              // 更新库存
              const index = this.prizeList.findIndex(item => item.id === prize.id);
              if (index !== -1) {
                this.prizeList[index].stock -= 1;
              }

              promptAction.showToast({
                message: `兑换成功！兑换码：${result.data.exchangeCode}`,
                duration: 4000
              });

              console.log(`兑换成功: ${prize.name}, 兑换码: ${result.data.exchangeCode}`);
            } else {
              promptAction.showToast({
                message: result.message || '兑换失败',
                duration: 2000
              });
            }
          } catch (parseError) {
            console.error('数据解析失败:', parseError);
            promptAction.showToast({
              message: '数据解析失败',
              duration: 2000
            });
          }
        } else {
          promptAction.showToast({
            message: `兑换失败: ${data.responseCode}`,
            duration: 2000
          });
        }

        httpRequest.destroy();
      });
    } catch (error) {
      this.isExchanging = false;
      console.error('兑换异常: ' + JSON.stringify(error));
      promptAction.showToast({
        message: '兑换失败',
        duration: 2000
      });
    }
  }

  // 查看积分明细
  private async viewPointsDetail() {
    // 检查用户是否登录
    const token = this.storedUserInfo.token;
    if (!token) {
      promptAction.showToast({
        message: '请先登录',
        duration: 2000
      });
      return;
    }

    this.showPointsDetail = true;
    this.pointsLoading = true;

    try {
      let httpRequest = http.createHttp();
      let url = 'http://' + `${this.serverIP}` + '/api/points/list?page=0';

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        header: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        readTimeout: 60000,
        connectTimeout: 60000
      } as http.HttpRequestOptions;

      httpRequest.request(url, options, (err: Error, data: http.HttpResponse) => {
        this.pointsLoading = false;

        if (err) {
          console.error('加载积分明细失败: ' + JSON.stringify(err));
          promptAction.showToast({
            message: '加载积分明细失败',
            duration: 2000
          });
          return;
        }

        if (data.responseCode === 200) {
          try {
            const resultString: string = data.result.toString();
            const result: PointsListResponse = JSON.parse(resultString) as PointsListResponse;

            if (result.success === true) {
              this.pointsRecords = result.data.content;
            } else {
              promptAction.showToast({
                message: result.message || '加载积分明细失败',
                duration: 2000
              });
            }
          } catch (parseError) {
            console.error('数据解析失败:', parseError);
            promptAction.showToast({
              message: '数据解析失败',
              duration: 2000
            });
          }
        } else {
          promptAction.showToast({
            message: `加载失败: ${data.responseCode}`,
            duration: 2000
          });
        }

        httpRequest.destroy();
      });
    } catch (error) {
      this.pointsLoading = false;
      console.error('加载积分明细异常: ' + JSON.stringify(error));
      promptAction.showToast({
        message: '加载积分明细失败',
        duration: 2000
      });
    }
  }

  // 格式化日期
  private formatDate(dateString: string): string {
    try {
      const date = new Date(dateString);
      return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    } catch (error) {
      return dateString;
    }
  }

  // 根据积分计算原价（模拟）
  private calculateOriginalPrice(points: number): number {
    return Math.round(points / 10);
  }

  // 获取按钮文本
  private getButtonText(prize: PrizeItem): string {
    if (this.isExchanging) {
      return '兑换中...';
    }
    if (prize.status !== 1) {
      return '已下架';
    }
    if (prize.stock === 0) {
      return '已售罄';
    }
    if (this.userPoints < prize.pointsRequired) {
      return '积分不足';
    }
    return '立即兑换';
  }

  // 获取按钮颜色
  private getButtonColor(prize: PrizeItem): string {
    if (this.isExchanging || prize.status !== 1 || prize.stock === 0 || this.userPoints < prize.pointsRequired) {
      return '#CCCCCC';
    }
    return '#007DFF';
  }

  // 检查是否可以兑换
  private canExchange(prize: PrizeItem): boolean {
    return prize.status === 1 && prize.stock > 0 && this.userPoints >= prize.pointsRequired;
  }

  // 加载更多奖品
  private async loadMorePrizes() {
    promptAction.showToast({
      message: '已加载全部商品',
      duration: 1000
    });
  }
}

// 本地存储的用户数据结构
interface StoredUserData {
  userId: string;
  token: string;
  nickName: string;
  avatar: string;
}