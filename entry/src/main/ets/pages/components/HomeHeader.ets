// entry/src/main/ets/pages/components/HomeHeader.ets
@Component
export struct HomeHeader {
  @State private weatherInfo: string = '晴 25°C'
  @State private searchText: string = ''

  build() {
    Row() {
      // 左侧：景区信息
      Row() {
        Image($r('app.media.startIcon'))
          .width(20)
          .height(20)
        Text('XX风景名胜区')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 8 })
      }
      .layoutWeight(1)

      // 中间：搜索框
      TextInput({ placeholder: '搜索景点、住宿、美食...', text: this.searchText })
        .width('60%')
        .height(36)
        .backgroundColor('#F5F5F5')
        .borderRadius(18)
        .padding({ left: 12, right: 12 })
        .onChange((value: string) => {
          this.searchText = value
        })

      // 右侧：天气信息
      Row() {
        Image($r('app.media.startIcon'))
          .width(20)
          .height(20)
        Text(this.weatherInfo)
          .fontSize(14)
          .margin({ left: 4 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
    .alignItems(VerticalAlign.Center)
  }
}