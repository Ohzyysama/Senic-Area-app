// entry/src/main/ets/pages/Punch.ets
import { router } from '@kit.ArkUI'
import { TabBar } from '../pages/components/TabBar'
import { SpotModel, SpotInfo } from '../model/SpotModel'
import camera from '@ohos.multimedia.camera'
import image from '@ohos.multimedia.image'
import picker from '@ohos.file.picker'
import http from '@ohos.net.http'
import { common } from '@kit.AbilityKit'

// 后端返回的用户信息接口（打卡数据中的user字段）
interface CheckinUser {
  id: number;
  nickName: string;
  avatarUrl: string;
}

// 后端返回的景点信息接口（打卡数据中的spot字段）
interface CheckinSpot {
  id: number;
  name: string;
}

// 后端返回的打卡数据接口
interface CheckinResp {
  id: number;
  user: CheckinUser | null;
  spot: CheckinSpot | null;
  photoFileId: string;
  comment: string | null;
  createdAt: string;
}

// 后端返回的用户数据接口（排行榜）
interface UserResp {
  id: number;
  nickName: string;
  avatarUrl: string;
  totalPoints: number;
  checkInCount: number;
}

// API响应接口
interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

// 分页响应接口
interface PageResponse<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

interface PunchRecord {
  id: number;
  user: string;
  avatar: Resource;
  photo: Resource;
  likes: number;
  comments: number;
  time: string;
  spotId: number;
}

interface PunchParams {
  spotId?: number;
  spotName?: string;
  tabIndex?: number; // 用于指定要显示的tab
}

interface RankingUser {
  user: string;
  avatar: Resource;
  totalPunches: number;
}

// 用户信息接口（用于AppStorage）
interface UserInfo {
  userId: string;
  token: string;
  nickName: string;
  avatar: string;
}

// 创建打卡请求数据接口
interface CreateCheckInRequest {
  spotId: number;
  photoFileID: string;
  comment: string;
}

// 点赞请求数据接口
interface LikeCheckInRequest {
  checkInId: number;
}

// 点赞响应数据接口
interface LikeCheckInResponse {
  checkInId: number;
  likeCount: number;
}

@Entry
@Component
struct Punch {
  @State spotId: number = 0;
  @State spotInfo: SpotInfo | null = null;
  @State currentTab: number = 0;  // 0: 打卡, 1: 动态, 2: 排行榜
  @State punchRecords: PunchRecord[] = [];
  @State myPunchHistory: PunchRecord[] = [];
  @State totalPunches: number = 0;
  @State todayPunches: number = 0;
  @State rankingUsers: RankingUser[] = [];
  @State isLoading: boolean = false;
  @State serverIP: string = '';
  
  // 从AppStorage获取token
  @StorageLink('userInfo') storedUserInfo: UserInfo = {
    userId: '',
    token: '',
    nickName: '',
    avatar: ''
  };

  aboutToAppear() {
    this.loadServerIP();
    try {
      const routerParams = router.getParams() as PunchParams;
      if (routerParams?.spotId) {
        this.spotId = routerParams.spotId;
        const spot = SpotModel.getSpotById(this.spotId);
        this.spotInfo = spot ? spot : null;
      } else {
        // 如果没有指定景点，默认显示第一个景点
        const allSpots = SpotModel.getAllSpots();
        this.spotInfo = allSpots.length > 0 ? allSpots[0] : null;
        this.spotId = this.spotInfo?.id || 0;
      }
      // 如果指定了tabIndex，切换到对应tab
      if (routerParams?.tabIndex !== undefined) {
        this.currentTab = routerParams.tabIndex;
      }
      this.loadPunchData();
    } catch (error) {
      console.error('Failed to get router params:', error);
      this.spotInfo = SpotModel.getAllSpots()[0];
      this.spotId = this.spotInfo?.id || 0;
      this.loadPunchData();
    }
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

  async loadPunchData() {
    await this.loadServerIP();
    
    // 根据当前tab加载不同数据
    if (this.currentTab === 1) {
      // 动态tab：加载打卡动态
      await this.loadFeed();
    } else if (this.currentTab === 2) {
      // 排行榜tab：加载排行榜
      await this.loadRanking();
    } else {
      // 打卡tab：加载我的打卡
      await this.loadMyCheckIns();
    }
  }

  // 加载打卡动态
  private async loadFeed() {
    try {
      let httpRequest = http.createHttp();
      let response = await httpRequest.request(
        `http://${this.serverIP}/api/public/feed?page=0`
      );

      if (response.responseCode === http.ResponseCode.OK) {
        const result: ApiResponse<PageResponse<CheckinResp>> = JSON.parse(response.result.toString()) as ApiResponse<PageResponse<CheckinResp>>;
        
        if (result.success && result.data && result.data.content && result.data.content.length > 0) {
          // 转换后端数据为前端格式
          this.punchRecords = result.data.content.map((checkin: CheckinResp) => {
            // 格式化时间
            const timeStr = this.formatTime(checkin.createdAt);
            
            // 图片资源处理（photoFileId是云存储ID，这里暂时使用默认图片）
            let photoResource: Resource = $r('app.media.nankunshan');
            // TODO: 如果photoFileId是URL，需要转换为Resource
            
            // 头像资源处理
            let avatarResource: Resource = $r('app.media.x1');
            // TODO: 如果avatarUrl是URL，需要转换为Resource

            return {
              id: checkin.id,
              user: checkin.user?.nickName || '用户',
              avatar: avatarResource,
              photo: photoResource,
              likes: 0, // 后端没有直接返回点赞数，暂时使用占位数据
              comments: checkin.comment ? 1 : 0, // 后端没有评论数统计，使用comment字段判断（有评论则显示1）
              time: timeStr,
              spotId: checkin.spot?.id || 0
            } as PunchRecord;
          });
        } else {
          // 后端返回空数据，使用假数据
          this.punchRecords = this.getMockPunchRecords();
        }
      } else {
        // 请求失败，使用假数据
        this.punchRecords = this.getMockPunchRecords();
      }
    } catch (error) {
      console.error('加载打卡动态失败:', error);
      // 使用假数据作为后备
      this.punchRecords = this.getMockPunchRecords();
    }
    
    // 如果最终还是没有数据，使用假数据
    if (this.punchRecords.length === 0) {
      this.punchRecords = this.getMockPunchRecords();
    }
  }

  // 获取假数据 - 打卡动态
  private getMockPunchRecords(): PunchRecord[] {
    const allSpots = SpotModel.getAllSpots();
    const mockUsers = ['旅行者小王', '摄影爱好者', '风景控', '户外达人', '背包客', '自然探索者', '山野行者', '风景摄影师'];
    const mockAvatars = [$r('app.media.x1'), $r('app.media.x1')]; // 可以添加更多头像资源
    const mockPhotos = [
      $r('app.media.nankunshan'),
      $r('app.media.luofushan'),
      $r('app.media.ecological'),
      $r('app.media.tourism'),
      $r('app.media.culture')
    ];
    const mockTimes = ['刚刚', '1小时前', '3小时前', '5小时前', '1天前', '2天前', '3天前', '5天前'];

    const records: PunchRecord[] = [];
    for (let index = 0; index < 12; index++) {
      const spot = allSpots[index % allSpots.length];
      const userIndex = index % mockUsers.length;
      records.push({
        id: 1000 + index,
        user: mockUsers[userIndex],
        avatar: mockAvatars[userIndex % mockAvatars.length],
        photo: mockPhotos[index % mockPhotos.length],
        likes: Math.floor(Math.random() * 50) + 5,
        comments: Math.floor(Math.random() * 10),
        time: mockTimes[index % mockTimes.length],
        spotId: spot.id
      } as PunchRecord);
    }
    return records;
  }

  // 加载我的打卡
  private async loadMyCheckIns() {
    if (!this.storedUserInfo.token) {
      // 未登录，不加载
      this.myPunchHistory = [];
      this.totalPunches = 0;
      this.todayPunches = 0;
      return;
    }

    try {
      let httpRequest = http.createHttp();
      let response = await httpRequest.request(
        `http://${this.serverIP}/api/checkin/my?page=0`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Authorization': `Bearer ${this.storedUserInfo.token}`
          }
        }
      );

      if (response.responseCode === http.ResponseCode.OK) {
        const result: ApiResponse<PageResponse<CheckinResp>> = JSON.parse(response.result.toString()) as ApiResponse<PageResponse<CheckinResp>>;
        
        if (result.success && result.data && result.data.content) {
          this.myPunchHistory = result.data.content.map((checkin: CheckinResp) => {
            const timeStr = this.formatTime(checkin.createdAt);
            let photoResource: Resource = $r('app.media.nankunshan');
            let avatarResource: Resource = $r('app.media.x1');

            return {
              id: checkin.id,
              user: '我',
              avatar: avatarResource,
              photo: photoResource,
              likes: 0, // 后端没有直接返回，暂时使用占位数据
              comments: checkin.comment ? 1 : 0, // 后端没有评论数统计，使用comment字段判断
              time: timeStr,
              spotId: checkin.spot?.id || 0
            } as PunchRecord;
          });
          
          // 统计数据
          this.totalPunches = this.myPunchHistory.length;
          const now = new Date();
          this.todayPunches = this.myPunchHistory.filter(record => {
            const recordTime = new Date(record.time);
            return recordTime.toDateString() === now.toDateString();
          }).length;
        }
      }
    } catch (error) {
      console.error('加载我的打卡失败:', error);
      this.myPunchHistory = [];
      this.totalPunches = 0;
      this.todayPunches = 0;
    }
  }

  // 加载排行榜
  private async loadRanking() {
    try {
      let httpRequest = http.createHttp();
      let response = await httpRequest.request(
        `http://${this.serverIP}/api/public/ranking?page=0`
      );

      if (response.responseCode === http.ResponseCode.OK) {
        const result: ApiResponse<PageResponse<UserResp>> = JSON.parse(response.result.toString()) as ApiResponse<PageResponse<UserResp>>;
        
        if (result.success && result.data && result.data.content && result.data.content.length > 0) {
          this.rankingUsers = result.data.content.map((user: UserResp) => {
            let avatarResource: Resource = $r('app.media.x1');
            // TODO: 如果avatarUrl是URL，需要转换为Resource

            return {
              user: user.nickName || '用户',
              avatar: avatarResource,
              totalPunches: user.checkInCount || 0 // 使用checkInCount作为总打卡数
            } as RankingUser;
          });
        } else {
          // 后端返回空数据，使用假数据
          this.rankingUsers = this.getMockRankingUsers();
        }
      } else {
        // 请求失败，使用假数据
        this.rankingUsers = this.getMockRankingUsers();
      }
    } catch (error) {
      console.error('加载排行榜失败:', error);
      // 使用假数据作为后备
      this.rankingUsers = this.getMockRankingUsers();
    }
    
    // 如果最终还是没有数据，使用假数据
    if (this.rankingUsers.length === 0) {
      this.rankingUsers = this.getMockRankingUsers();
    }
  }

  // 获取假数据 - 排行榜
  private getMockRankingUsers(): RankingUser[] {
    const mockUsers = [
      '旅行达人',
      '风景摄影师',
      '户外探索者',
      '背包客小王',
      '自然爱好者',
      '山野行者',
      '风景控',
      '摄影爱好者',
      '旅行者',
      '探索者'
    ];
    const mockAvatars = [$r('app.media.x1')];
    const mockPunches = [156, 142, 128, 115, 98, 87, 76, 65, 54, 43];

    return mockUsers.map((user, index) => {
      return {
        user: user,
        avatar: mockAvatars[index % mockAvatars.length],
        totalPunches: mockPunches[index] || (50 - index * 3)
      } as RankingUser;
    });
  }

  // 格式化时间
  private formatTime(timeStr: string): string {
    try {
      const time = new Date(timeStr);
      const now = new Date();
      const diff = now.getTime() - time.getTime();
      const hours = Math.floor(diff / (1000 * 60 * 60));
      const days = Math.floor(hours / 24);

      if (hours < 1) {
        return '刚刚';
      } else if (hours < 24) {
        return `${hours}小时前`;
      } else if (days < 7) {
        return `${days}天前`;
      } else {
        return time.toLocaleDateString();
      }
    } catch (error) {
      return timeStr;
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      this.BuildHeader()

      // 内容区域
      if (this.currentTab === 0) {
        this.BuildPunchTab()
      } else if (this.currentTab === 1) {
        this.BuildDynamicTab()
      } else {
        this.BuildRankingTab()
      }

      TabBar({ currentPage: 'punch' })
    }
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  BuildHeader() {
    Column() {
      Row() {
        // 返回按钮
        Text('←')
          .fontSize(24)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Text(this.spotInfo?.name || '景点打卡')
          .fontSize(20)
        .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank().width(24)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      // 标签栏
      Row() {
        this.BuildTabItem('打卡', 0)
        this.BuildTabItem('动态', 1)
        this.BuildTabItem('排行榜', 2)
      }
      .width('100%')
      .height(48)
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .backgroundColor('#FFFFFF')
    .shadow({ radius: 2, color: '#1F000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  BuildTabItem(title: string, index: number) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontColor(this.currentTab === index ? '#007DFF' : '#666666')
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)

      if (this.currentTab === index) {
        Divider()
          .color('#007DFF')
          .strokeWidth(3)
          .width(30)
          .margin({ top: 4 })
      }
    }
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      if (this.currentTab !== index) {
        this.currentTab = index;
        this.loadPunchData();
      }
    })
  }

  @Builder
  BuildPunchTab() {
    Column() {
      // 主要内容区域 - 固定显示，不滚动
      Column() {
        // 景点信息卡片 - 固定高度
        if (this.spotInfo) {
          this.BuildSpotCard(this.spotInfo)
        }

        // 打卡按钮区域 - 固定高度，压缩间距
        Column() {
          Row({ space: 12 }) {
            // 拍照打卡按钮
            Button() {
              Row({ space: 8 }) {
                Image($r('app.media.checkIn'))
                  .width(24)
                  .height(24)
                  .fillColor('#FFFFFF')
                Text('立即打卡')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
              }
            }
            .width('70%')
            .height(50)
            .backgroundColor('#007DFF')
            .borderRadius(25)
            .onClick(() => {
              this.takePhoto();
            })

            // 导航图标按钮
            Button() {
              Image($r('app.media.startIcon'))
                .width(24)
                .height(24)
                .fillColor('#007DFF')
            }
            .width(50)
            .height(50)
            .backgroundColor('#E6F4FF')
            .borderRadius(25)
            .onClick(() => {
              // 导航到景点
              console.log('导航到景点:', this.spotInfo?.name);
              // TODO: 实现导航功能
            })
          }
          .width('90%')
          .justifyContent(FlexAlign.Center)

          Text('记录你的美好瞬间')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
        .backgroundColor('#FFFFFF')
        .margin({ top: 6 })

        // 统计信息 - 固定高度，压缩间距
        this.BuildStatistics()
      }
      .width('100%')

      // 我的打卡历史 - 可滚动部分，填充剩余空间
      if (this.myPunchHistory.length > 0) {
        Scroll() {
          Column() {
            Row() {
              Text('我的打卡')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')

              Blank()

              Text('查看全部')
                .fontSize(14)
                .fontColor('#007DFF')
                .onClick(() => {
                  this.currentTab = 1;
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 12 })

            ForEach(this.myPunchHistory, (item: PunchRecord) => {
              this.BuildPunchCard(item, true)
            }, (item: PunchRecord) => item.id.toString())
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .width('100%')
        .backgroundColor('#FFFFFF')
        .margin({ top: 12 })
      } else {
        // 如果没有打卡历史，占位空间
        Blank()
          .layoutWeight(1)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  BuildSpotCard(spot: SpotInfo) {
    Stack() {
      // 使用景点图片资源，完全填充，无灰色背景
      Image(spot.image)
        .width('100%')
        .height(100)
        .objectFit(ImageFit.Cover)
        .backgroundColor(Color.Transparent)

      // 渐变遮罩层
      Column() {
        Blank()
        Row() {
          Column() {
            Text(spot.name)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')

            Row({ space: 8 }) {
              Row({ space: 4 }) {
                Image($r('app.media.star'))
                  .width(12)
                  .height(12)
                Text(spot.rating.toFixed(1))
                  .fontSize(12)
                  .fontColor('#FFFFFF')
              }

              Text('|')
                .fontColor('#FFFFFF')
                .opacity(0.7)

              Text(`${spot.visitCount}人访问`)
                .fontSize(12)
                .fontColor('#FFFFFF')
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // 导航图标按钮
          Button() {
            Image($r('app.media.startIcon'))
              .width(20)
              .height(20)
              .fillColor('#FFFFFF')
          }
          .type(ButtonType.Normal)
          .backgroundColor('#007DFF')
          .width(40)
          .height(40)
          .borderRadius(20)
          .margin({ right: 8 })
          .onClick(() => {
            // 导航到景点
            console.log('导航到景点:', spot.name);
            // TODO: 实现导航功能
          })

          Button('详情')
            .type(ButtonType.Normal)
            .backgroundColor('#FFFFFF')
            .fontColor('#007DFF')
            .fontSize(12)
            .padding({ left: 16, right: 16 })
            .borderRadius(16)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/Detail/IntroPage',
                params: { spotId: spot.id, spotName: spot.name }
              })
            })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 12, bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#40000000')
    }
    .width('100%')
    .height(100)
    .backgroundColor(Color.Transparent)
  }

  @Builder
  BuildStatistics() {
    Row() {
      Column() {
        Text(this.totalPunches.toString())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007DFF')
        Text('总打卡数')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .layoutWeight(1)

      Divider()
        .vertical(true)
        .height(30)
        .color('#E0E0E0')

      Column() {
        Text(this.todayPunches.toString())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#52C41A')
        Text('今日打卡')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .layoutWeight(1)

      Divider()
        .vertical(true)
        .height(30)
        .color('#E0E0E0')

      Column() {
        Text(this.spotInfo?.rating.toFixed(1) || '0')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B00')
        Text('景点评分')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height(65)
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor('#FFFFFF')
    .margin({ top: 6 })
  }

  @Builder
  BuildDynamicTab() {
    Scroll() {
      Column() {
        Text('打卡动态')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, top: 16, bottom: 12 })

        if (this.punchRecords.length > 0) {
          ForEach(this.punchRecords, (item: PunchRecord) => {
            this.BuildPunchCard(item, false)
          }, (item: PunchRecord) => item.id.toString())
        } else {
          Column() {
            Text('暂无打卡动态')
              .fontSize(14)
              .fontColor('#999999')
              .margin({ top: 40 })
          }
          .width('100%')
          .height(200)
        }
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  BuildRankingTab() {
    Scroll() {
      Column() {
        // 标题位于顶部
        Text('打卡排行榜')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, top: 16, bottom: 12 })
          .backgroundColor('#FFFFFF')

        // 所有用户的总打卡数排行榜（所有景点之和）
        Column({ space: 8 }) {
          // 前三名 - 紧密排列
          if (this.rankingUsers.length > 0) {
            this.BuildRankingItemByUser(this.rankingUsers[0], 1, true)
          }
          if (this.rankingUsers.length > 1) {
            this.BuildRankingItemByUser(this.rankingUsers[1], 2, true)
          }
          if (this.rankingUsers.length > 2) {
            this.BuildRankingItemByUser(this.rankingUsers[2], 3, true)
          }

          // 其他排名 - 紧密排列
          if (this.rankingUsers.length > 3) {
            ForEach(this.rankingUsers.slice(3), (user: RankingUser, index: number) => {
              this.BuildRankingItemByUser(user, index + 4, false)
            }, (user: RankingUser) => user.user)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .backgroundColor('#FFFFFF')
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  BuildPunchCard(record: PunchRecord, isMyPunch: boolean) {
    Column() {
      Row() {
        Image(record.avatar)
          .width(40)
          .height(40)
          .borderRadius(20)

        Column() {
          Text(record.user)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')

          Text(record.time)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Image(record.photo)
        .width('100%')
      .height(300)
        .borderRadius(12)
        .objectFit(ImageFit.Cover)
        .margin({ top: 12 })

      Row() {
        // 点赞 - 使用爱心图标（可点击）
        Row({ space: 6 }) {
          Text('❤️')
            .fontSize(18)
          Text(record.likes.toString())
            .fontSize(14)
            .fontColor('#666666')
        }
        .onClick(() => {
          this.likeCheckIn(record.id);
        })

        // 评论 - 使用聊天气泡图标
        Row({ space: 6 }) {
          Text('💬')
            .fontSize(18)
          Text(record.comments.toString())
            .fontSize(14)
            .fontColor('#666666')
        }
        .margin({ left: 20 })

        Blank()

        Text(record.time)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .margin({ top: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .margin({ bottom: 12 })
  }

  @Builder
  BuildRankingItem(record: PunchRecord, rank: number, isTop: boolean) {
    Row() {
      // 排名 - 前三名特殊标识
      Column() {
        if (rank === 1) {
          Text('🥇')
            .fontSize(24)
        } else if (rank === 2) {
          Text('🥈')
            .fontSize(24)
        } else if (rank === 3) {
          Text('🥉')
            .fontSize(24)
        } else {
          Text(rank.toString())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
        }
      }
      .width(40)
      .justifyContent(FlexAlign.Center)

      Image(record.avatar)
        .width(50)
        .height(50)
        .borderRadius(25)
        .border({ width: isTop ? 3 : 0, color: rank === 1 ? '#FFD700' : rank === 2 ? '#C0C0C0' : rank === 3 ? '#CD7F32' : '#FFFFFF' })

      Column() {
        Text(record.user)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        // 显示总打卡数（所有景点之和）
        Text(`${record.likes + record.comments}次打卡`)
          .fontSize(14)
          .fontColor('#007DFF')
          .fontWeight(FontWeight.Bold)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .height(70)
    .padding(12)
    .backgroundColor(isTop ? (rank === 1 ? '#FFF9E6' : rank === 2 ? '#F5F5F5' : '#FFF4E6') : '#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  @Builder
  BuildRankingItemByUser(user: RankingUser, rank: number, isTop: boolean) {
    Row() {
      // 排名 - 前三名特殊标识
      Column() {
        if (rank === 1) {
          Text('🥇')
            .fontSize(24)
        } else if (rank === 2) {
          Text('🥈')
            .fontSize(24)
        } else if (rank === 3) {
          Text('🥉')
            .fontSize(24)
        } else {
          Text(rank.toString())
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#666666')
        }
      }
      .width(40)
      .justifyContent(FlexAlign.Center)

      Image(user.avatar)
        .width(50)
        .height(50)
        .borderRadius(25)
        .border({ width: isTop ? 3 : 0, color: rank === 1 ? '#FFD700' : rank === 2 ? '#C0C0C0' : rank === 3 ? '#CD7F32' : '#FFFFFF' })

      Column() {
        Text(user.user)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        // 显示总打卡数（所有景点之和）
        Text(`${user.totalPunches}次打卡`)
          .fontSize(14)
          .fontColor('#007DFF')
          .fontWeight(FontWeight.Bold)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })
    }
    .width('100%')
    .height(70)
    .padding(12)
    .backgroundColor(isTop ? (rank === 1 ? '#FFF9E6' : rank === 2 ? '#F5F5F5' : '#FFF4E6') : '#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }

  // 拍照打卡功能
  private async takePhoto() {
    if (!this.storedUserInfo.token) {
      console.error('请先登录');
      return;
    }

    try {
      // 使用图片选择器，支持拍照和相册选择
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoPicker.select(photoSelectOptions);

      if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const imageUri = photoSelectResult.photoUris[0];
        console.log('选择的图片URI:', imageUri);
        
        // TODO: 上传图片到云存储，获取photoFileID
        // 这里暂时使用占位符
        const photoFileID = 'placeholder_file_id';
        
        // 调用后端API创建打卡
        await this.createCheckIn(photoFileID);
      }
    } catch (error) {
      console.error('拍照打卡失败:', error);
    }
  }

  // 创建打卡
  private async createCheckIn(photoFileID: string) {
    try {
      await this.loadServerIP();
      let httpRequest = http.createHttp();
      
      const requestData: CreateCheckInRequest = {
        spotId: this.spotId,
        photoFileID: photoFileID,
        comment: ''
      };

      let response = await httpRequest.request(
        `http://${this.serverIP}/api/checkin/create`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.storedUserInfo.token}`
          },
          extraData: JSON.stringify(requestData)
        }
      );

      if (response.responseCode === http.ResponseCode.OK) {
        const result: ApiResponse<null> = JSON.parse(response.result.toString()) as ApiResponse<null>;
        if (result.success) {
          console.log('打卡成功！景点:', this.spotInfo?.name);
          // 刷新打卡数据
          await this.loadPunchData();
        }
      }
    } catch (error) {
      console.error('创建打卡失败:', error);
    }
  }

  // 点赞打卡
  private async likeCheckIn(checkInId: number) {
    if (!this.storedUserInfo.token) {
      console.error('请先登录');
      return;
    }

    try {
      await this.loadServerIP();
      let httpRequest = http.createHttp();
      
      const requestData: LikeCheckInRequest = {
        checkInId: checkInId
      };

      let response = await httpRequest.request(
        `http://${this.serverIP}/api/checkin/like`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.storedUserInfo.token}`
          },
          extraData: JSON.stringify(requestData)
        }
      );

      if (response.responseCode === http.ResponseCode.OK) {
        const result: ApiResponse<LikeCheckInResponse> = JSON.parse(response.result.toString()) as ApiResponse<LikeCheckInResponse>;
        if (result.success && result.data) {
          // 更新对应记录的点赞数
          const record = this.punchRecords.find(r => r.id === checkInId);
          if (record) {
            record.likes = result.data.likeCount;
          }
          const myRecord = this.myPunchHistory.find(r => r.id === checkInId);
          if (myRecord) {
            myRecord.likes = result.data.likeCount;
          }
        }
      }
    } catch (error) {
      console.error('点赞失败:', error);
    }
  }
}
