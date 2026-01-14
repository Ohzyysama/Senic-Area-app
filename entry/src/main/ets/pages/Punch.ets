// entry/src/main/ets/pages/Punch.ets
import { router } from '@kit.ArkUI'
import { TabBar } from '../pages/components/TabBar'
import { SpotModel, SpotInfo } from '../model/SpotModel'

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

  // 模拟打卡记录数据
  private allRecords: PunchRecord[] = [
    { id: 1, user: '旅行者小王', avatar: $r('app.media.x1'), photo: $r('app.media.x1'), likes: 128, comments: 23, time: '2小时前', spotId: 1 },
    { id: 2, user: '摄影爱好者', avatar: $r('app.media.x2'), photo: $r('app.media.x2'), likes: 89, comments: 15, time: '5小时前', spotId: 1 },
    { id: 3, user: '风景探索者', avatar: $r('app.media.x3'), photo: $r('app.media.x3'), likes: 156, comments: 31, time: '1天前', spotId: 2 },
    { id: 4, user: '自然爱好者', avatar: $r('app.media.x1'), photo: $r('app.media.nankunshan'), likes: 203, comments: 42, time: '1天前', spotId: 3 },
    { id: 5, user: '文化探索家', avatar: $r('app.media.x2'), photo: $r('app.media.luofushan'), likes: 167, comments: 28, time: '2天前', spotId: 2 },
    { id: 6, user: '户外达人', avatar: $r('app.media.x3'), photo: $r('app.media.ecological'), likes: 94, comments: 18, time: '2天前', spotId: 3 },
    { id: 7, user: '慢生活家', avatar: $r('app.media.x1'), photo: $r('app.media.tourism'), likes: 78, comments: 12, time: '3天前', spotId: 4 },
    { id: 8, user: '知识探索者', avatar: $r('app.media.x2'), photo: $r('app.media.culture'), likes: 112, comments: 19, time: '3天前', spotId: 5 }
  ];

  aboutToAppear() {
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
      this.loadPunchData();
    } catch (error) {
      console.error('Failed to get router params:', error);
      this.spotInfo = SpotModel.getAllSpots()[0];
      this.spotId = this.spotInfo?.id || 0;
      this.loadPunchData();
    }
  }

  loadPunchData() {
    // 加载该景点的打卡记录
    this.punchRecords = this.allRecords.filter(r => r.spotId === this.spotId);
    if (this.punchRecords.length === 0) {
      // 如果没有该景点的记录，显示所有记录
      this.punchRecords = this.allRecords.slice(0, 6);
    }
    
    // 模拟我的打卡历史
    this.myPunchHistory = [
      { id: 101, user: '我', avatar: $r('app.media.x1'), photo: $r('app.media.nankunshan'), likes: 45, comments: 8, time: '昨天', spotId: 1 },
      { id: 102, user: '我', avatar: $r('app.media.x1'), photo: $r('app.media.luofushan'), likes: 32, comments: 5, time: '3天前', spotId: 2 }
    ];

    // 统计数据
    this.totalPunches = this.punchRecords.length + this.myPunchHistory.length;
    this.todayPunches = this.punchRecords.filter(r => r.time.includes('小时前') || r.time === '今天').length;
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
      this.currentTab = index;
    })
  }

  @Builder
  BuildPunchTab() {
    Scroll() {
      Column() {
        // 景点信息卡片
        if (this.spotInfo) {
          this.BuildSpotCard(this.spotInfo)
        }

        // 打卡按钮区域
        Column() {
          Button('📷 立即打卡')
            .width('90%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#007DFF')
            .fontColor(Color.White)
            .borderRadius(25)
            .onClick(() => {
              // TODO: 实现拍照打卡功能
              console.log('开始打卡');
            })

          Text('记录你的美好瞬间')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 8 })
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
        .backgroundColor('#FFFFFF')
        .margin({ top: 12 })

        // 统计信息
        this.BuildStatistics()

        // 我的打卡历史
        if (this.myPunchHistory.length > 0) {
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
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })
        }
      }
      .width('100%')
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  BuildSpotCard(spot: SpotInfo) {
    Column() {
      Stack() {
        Image(spot.image)
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Cover)

        Column() {
          Blank()
          Row() {
            Column() {
              Text(spot.name)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')

              Row({ space: 8 }) {
                Row({ space: 4 }) {
                  Image($r('app.media.star'))
                    .width(14)
                    .height(14)
                  Text(spot.rating.toFixed(1))
                    .fontSize(14)
                    .fontColor('#FFFFFF')
                }

                Text('|')
                  .fontColor('#FFFFFF')
                  .opacity(0.7)

                Text(`${spot.visitCount}人访问`)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
              }
              .margin({ top: 8 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

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
          .padding(16)
        }
        .width('100%')
        .height('100%')
        .backgroundImage($r('app.media.background'))
        .backgroundImageSize(ImageSize.Cover)
        .backgroundColor('#40000000')
      }
    }
    .width('100%')
    .borderRadius(0)
  }

  @Builder
  BuildStatistics() {
    Row() {
      Column() {
        Text(this.totalPunches.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007DFF')
        Text('总打卡数')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .layoutWeight(1)

      Divider()
        .vertical(true)
        .height(40)
        .color('#E0E0E0')

      Column() {
        Text(this.todayPunches.toString())
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#52C41A')
        Text('今日打卡')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .layoutWeight(1)

      Divider()
        .vertical(true)
        .height(40)
        .color('#E0E0E0')

      Column() {
        Text(this.spotInfo?.rating.toFixed(1) || '0')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF6B00')
        Text('景点评分')
          .fontSize(12)
          .fontColor('#666666')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height(80)
    .padding(16)
    .backgroundColor('#FFFFFF')
    .margin({ top: 12 })
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
        Text('打卡排行榜')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .padding({ left: 16, top: 16, bottom: 12 })

        // 前三名
        Column({ space: 12 }) {
          if (this.punchRecords.length > 0) {
            this.BuildRankingItem(this.punchRecords[0], 1, true)
          }
          if (this.punchRecords.length > 1) {
            this.BuildRankingItem(this.punchRecords[1], 2, false)
          }
          if (this.punchRecords.length > 2) {
            this.BuildRankingItem(this.punchRecords[2], 3, false)
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 16 })

        // 其他排名
        if (this.punchRecords.length > 3) {
          Column() {
            Text('其他排名')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 16, top: 16, bottom: 12 })

            ForEach(this.punchRecords.slice(3), (item: PunchRecord, index: number) => {
              this.BuildRankingItem(item, index + 4, false)
            }, (item: PunchRecord) => item.id.toString())
          }
          .width('100%')
          .backgroundColor('#FFFFFF')
          .margin({ top: 12 })
        }
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
        Row({ space: 8 }) {
          Text('👍')
            .fontSize(18)
          Text(record.likes.toString())
            .fontSize(14)
            .fontColor('#666666')
        }

        Row({ space: 8 }) {
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
      // 排名
      Column() {
        if (isTop) {
          Text(rank.toString())
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFD700')
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
        .border({ width: isTop ? 3 : 0, color: '#FFD700' })

      Column() {
        Text(record.user)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')

        Row({ space: 12 }) {
          Text(`${record.likes}点赞`)
            .fontSize(12)
            .fontColor('#666666')

          Text(`${record.comments}评论`)
            .fontSize(12)
            .fontColor('#666666')
        }
        .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      // 奖牌图标（仅前三名）
      if (isTop && rank <= 3) {
        Image($r('app.media.prize'))
          .width(30)
          .height(30)
      }
    }
    .width('100%')
    .height(70)
    .padding(12)
    .backgroundColor(isTop ? '#FFF9E6' : '#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
  }
}
