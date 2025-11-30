// entry/src/main/ets/model/FunctionModel.ets
import '../pages/Detail/IntroPage.ets'

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
        icon: $r('app.media.intro'),
        name: '引领区介绍',
        page: 'pages/Detail/IntroPage'
      } as FunctionItem,
      {
        icon: $r('app.media.mapIcon'),
        name: '景区地图',
        page: 'pages/MapPage'
      } as FunctionItem,
      {
        icon: $r('app.media.checkIn'),
        name: '打卡',
        page: 'pages/Punch'
      } as FunctionItem,
      {
        icon: $r('app.media.hotel'),
        name: '住宿',
        page: 'pages/Detail/Accommodation',
      } as FunctionItem,
      {
        icon: $r('app.media.restaurant'),
        name: '餐饮',
        page: 'pages/Detail/RestaurantPage',
      } as FunctionItem,
      {
        icon: $r('app.media.prize'),
        name: '礼品中心',
        page: 'pages/GiftCenterPage'
      } as FunctionItem,
      {
        icon: $r('app.media.table'),
        name: '打卡榜单',
        page: 'pages/PunchCardFeedPage'
      } as FunctionItem,
      {
        icon: $r('app.media.profile'),
        name: '个人中心',
        page: 'pages/Individual/Profile'
      } as FunctionItem
    ];
    return functions;
  }
}