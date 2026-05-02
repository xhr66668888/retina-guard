@Component
export struct ChecklistRow {
  @Prop title: string = '';
  @Prop description: string = '';
  @Prop granted: boolean = false;
  @Prop actionLabel: string = 'Open';
  onAction: () => void = () => {};

  build() {
    Row() {
      // Status circle
      Stack() {
        if (this.granted) {
          Text('✓')
            .fontSize(14)
            .fontColor('#FFFFFF')
        } else {
          Text('·')
            .fontSize(14)
            .fontColor('#1D1D1F')
        }
      }
      .width(24)
      .height(24)
      .borderRadius(12)
      .backgroundColor(this.granted ? '#E60000' : '#F5F5F7')

      // Text
      Column() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1D1D1F')
        Text(this.description)
          .fontSize(12)
          .fontColor('#86868B')
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })

      // Action
      Text(this.granted ? 'Granted' : this.actionLabel)
        .fontSize(14)
        .fontColor(this.granted ? '#86868B' : '#E60000')
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
    .onClick(this.onAction)

    Divider().color('#F5F5F7')
  }
}

@Component
export struct RedBand {
  build() {
    Stack()
      .width('100%')
      .height(4)
      .backgroundColor('#E60000')
      .margin({ top: 24, bottom: 24 })
  }
}
