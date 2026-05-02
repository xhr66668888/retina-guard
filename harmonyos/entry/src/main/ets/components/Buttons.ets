@Component
export struct RedPillButton {
  @Prop text: string = '';
  @Prop enabled: boolean = true;
  onAction: () => void = () => {};

  build() {
    Button(this.text)
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor(this.enabled ? '#E60000' : '#F5F5F7')
      .fontColor(this.enabled ? '#FFFFFF' : '#86868B')
      .borderRadius(24)
      .enabled(this.enabled)
      .onClick(this.onAction)
  }
}

@Component
export struct GhostButton {
  @Prop text: string = '';
  onAction: () => void = () => {};

  build() {
    Button(this.text)
      .width('100%')
      .height(48)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .backgroundColor('#F5F5F7')
      .fontColor('#1D1D1F')
      .borderRadius(24)
      .onClick(this.onAction)
  }
}
