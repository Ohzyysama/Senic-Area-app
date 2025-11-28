// entry/src/main/ets/pages/components/FunctionGrid.ets
import { FunctionModel, FunctionItem } from '../../model/FunctionModel'
import { router } from '@kit.ArkUI'

@Component
export struct FunctionGrid {
  private mainFunctions: FunctionItem[] = FunctionModel.getMainFunctions()

  build() {
    Grid() {
      ForEach(this.mainFunctions, (item: FunctionItem) => {
        GridItem() {
          this.BuildFunctionItem(item)
        }
      }, (item: FunctionItem) => item.name)
    }
    .columnsTemplate('1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .height(200)
    .margin({ top: 10, bottom: 10 })
  }

  @Builder BuildFunctionItem(item: FunctionItem) {
    Column() {
      Image(item.icon)
        .width(40)
        .height(40)
      Text(item.name)
        .fontSize(14)
        .margin({ top: 8 })
    }
    .width('100%')
    .height(80)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      // 跳转逻辑
      console.log(item.page)
      router.pushUrl({
        url : item.page
      })
    })
  }
}