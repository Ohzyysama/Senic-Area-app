// entry/src/main/ets/model/FunctionModel.ets
export interface FunctionItem {
  icon: Resource;
  name: string;
  page: string;
  params?: object;
}

export class FunctionModel {
  static getMainFunctions(): FunctionItem[] {
    const functions: FunctionItem[] = [
      {
        icon: $r('app.media.startIcon'),
        name: '引领区介绍',
        page: 'pages/IntroPage'
      } as FunctionItem,
      {
        icon: $r('app.media.startIcon'),
        name: '景区地图',
        page: 'pages/MapPage'
      } as FunctionItem,
      {
        icon: $r('app.media.startIcon'),
        name: '打卡',
        page: 'pages/Punch'
      } as FunctionItem,
      {
        icon: $r('app.media.startIcon'),
        name: '住宿',
        page: 'pages/BusinessListPage',
      } as FunctionItem,
      {
        icon: $r('app.media.startIcon'),
        name: '餐饮',
        page: 'pages/BusinessListPage',
      } as FunctionItem,
      {
        icon: $r('app.media.startIcon'),
        name: '礼品中心',
        page: 'pages/GiftCenterPage'
      } as FunctionItem,
      {
        icon: $r('app.media.startIcon'),
        name: '打卡榜单',
        page: 'pages/PunchCardFeedPage'
      } as FunctionItem,
      {
        icon: $r('app.media.startIcon'),
        name: '个人中心',
        page: 'pages/ProfilePage'
      } as FunctionItem
    ];
    return functions;
  }
}