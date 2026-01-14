// entry/src/main/ets/model/SpotModel.ets
// 景点数据模型

export interface SpotInfo {
  id: number;
  name: string;
  x: number;  // 地图上的x坐标（百分比）
  y: number;  // 地图上的y坐标（百分比）
  description: string;
  image: Resource;
  rating: number;  // 评分 1-5
  visitCount: number;  // 访问次数
  category: string;  // 景点类别
  address: string;  // 地址
  openingHours: string;  // 开放时间
  ticketPrice: string;  // 门票价格
  features: string[];  // 特色标签
}

export class SpotModel {
  // 获取所有景点信息
  static getAllSpots(): SpotInfo[] {
    return [
      {
        id: 1,
        name: '观景台',
        x: 25,
        y: 20,
        description: '观景台位于景区最高处，可俯瞰整个景区美景。这里视野开阔，是拍照打卡的绝佳地点。清晨时分，可以看到壮观的日出景象；傍晚时分，夕阳西下，景色更是美不胜收。',
        image: $r('app.media.nankunshan'),
        rating: 4.8,
        visitCount: 12580,
        category: '观景点',
        address: '景区主峰顶部',
        openingHours: '06:00-20:00',
        ticketPrice: '免费',
        features: ['日出观赏', '拍照圣地', '观景']
      },
      {
        id: 2,
        name: '古树广场',
        x: 60,
        y: 45,
        description: '古树广场拥有千年古树，是景区内最具历史文化价值的景点之一。广场周围绿树成荫，环境清幽，是游客休憩和了解当地历史文化的理想场所。古树见证了历史的变迁，是景区的重要文化符号。',
        image: $r('app.media.luofushan'),
        rating: 4.6,
        visitCount: 9876,
        category: '文化景点',
        address: '景区中心区域',
        openingHours: '全天开放',
        ticketPrice: '免费',
        features: ['历史文化', '古树', '文化体验']
      },
      {
        id: 3,
        name: '瀑布群',
        x: 75,
        y: 70,
        description: '瀑布群由多个大小不一的瀑布组成，水流从高处倾泻而下，形成壮观的瀑布景观。这里空气清新，负氧离子含量高，是天然的氧吧。夏季来此，可以感受到清凉的水汽，是避暑的好去处。',
        image: $r('app.media.ecological'),
        rating: 4.9,
        visitCount: 15620,
        category: '自然景观',
        address: '景区北部山区',
        openingHours: '07:00-19:00',
        ticketPrice: '30元',
        features: ['瀑布', '避暑', '自然风光']
      },
      {
        id: 4,
        name: '竹林小径',
        x: 35,
        y: 60,
        description: '竹林小径蜿蜒曲折，两旁翠竹成林，环境清幽雅致。漫步其中，可以听到竹叶沙沙作响，感受大自然的宁静。这里是放松心情、享受慢生活的绝佳场所。',
        image: $r('app.media.tourism'),
        rating: 4.5,
        visitCount: 8234,
        category: '休闲步道',
        address: '景区东部',
        openingHours: '全天开放',
        ticketPrice: '免费',
        features: ['竹林', '休闲', '慢生活']
      },
      {
        id: 5,
        name: '文化展览馆',
        x: 50,
        y: 35,
        description: '文化展览馆展示了景区丰富的历史文化和自然生态知识。馆内收藏了大量珍贵的历史文物和自然标本，通过多媒体展示，让游客深入了解景区的文化底蕴和生态价值。',
        image: $r('app.media.culture'),
        rating: 4.4,
        visitCount: 6543,
        category: '文化设施',
        address: '景区入口附近',
        openingHours: '09:00-17:00',
        ticketPrice: '20元',
        features: ['文化', '教育', '展览']
      },
      {
        id: 6,
        name: '山顶餐厅',
        x: 20,
        y: 15,
        description: '山顶餐厅位于观景台附近，提供特色美食和饮品。在这里用餐，可以一边享受美食，一边欣赏美景，是景区内最受欢迎的用餐地点。餐厅提供当地特色菜，让游客品尝到地道的风味。',
        image: $r('app.media.restaurant'),
        rating: 4.3,
        visitCount: 11234,
        category: '餐饮服务',
        address: '观景台旁',
        openingHours: '10:00-21:00',
        ticketPrice: '人均80-150元',
        features: ['美食', '观景', '特色菜']
      }
    ];
  }

  // 根据ID获取景点信息
  static getSpotById(id: number): SpotInfo | undefined {
    return SpotModel.getAllSpots().find(spot => spot.id === id);
  }

  // 获取热门景点（按访问次数排序）
  static getHotSpots(limit: number = 3): SpotInfo[] {
    return SpotModel.getAllSpots()
      .sort((a, b) => b.visitCount - a.visitCount)
      .slice(0, limit);
  }
}
