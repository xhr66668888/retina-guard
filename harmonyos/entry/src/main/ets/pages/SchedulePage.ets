import { AppSettings } from '../common/Models';

@Component
export struct SchedulePage {
  @Prop settings: AppSettings;
  onDailyChange: (v: boolean) => void = () => {};
  onQuietChange: (v: boolean) => void = () => {};
  onDaysChange: (m: number) => void = () => {};

  private dayNames: string[] = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  private isDayActive(index: number): boolean {
    return (this.settings.activeDaysMask & (1 << index)) !== 0;
  }

  private toggleDay(index: number): void {
    let mask = this.settings.activeDaysMask;
    mask ^= (1 << index);
    this.onDaysChange(mask);
  }

  build() {
    Column() {
      Text('SCHEDULE')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1D1D1F')
        .margin({ top: 12, left: 24 })

      // Daily schedule toggle
      Row() {
        Text('Daily schedule')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1D1D1F')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.settings.dailyScheduleEnabled })
          .onChange((v: boolean) => this.onDailyChange(v))
          .selectedColor('#E60000')
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24 })

      Text('Only run protection during specific hours on active days.')
        .fontSize(14)
        .fontColor('#86868B')
        .margin({ top: 8, left: 24, right: 24 })

      Divider().color('#F5F5F7').margin({ top: 16 })

      // Active days
      if (this.settings.dailyScheduleEnabled) {
        Text('ACTIVE DAYS')
          .fontSize(12)
          .fontColor('#86868B')
          .margin({ top: 16, left: 24 })

        Row() {
          ForEach(this.dayNames, (name: string, index?: number) => {
            Button(name)
              .width(40)
              .height(40)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(this.isDayActive(index ?? 0) ? '#E60000' : '#F5F5F7')
              .fontColor(this.isDayActive(index ?? 0) ? '#FFFFFF' : '#1D1D1F')
              .borderRadius(20)
              .margin(4)
              .onClick(() => this.toggleDay(index ?? 0))
          })
        }
        .margin({ top: 8, left: 20 })

        // Schedule info
        Row() {
          Text('Active hours')
            .fontSize(14)
            .fontColor('#1D1D1F')
            .layoutWeight(1)
          Text('09:00 – 18:00')
            .fontSize(14)
            .fontColor('#86868B')
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 16 })

        Divider().color('#F5F5F7').margin({ top: 16 })
      }

      // Quiet hours
      Row() {
        Text('Quiet hours')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1D1D1F')
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.settings.quietHoursEnabled })
          .onChange((v: boolean) => this.onQuietChange(v))
          .selectedColor('#E60000')
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 24 })

      Text('Pause reminders during quiet hours (22:00 – 08:00).')
        .fontSize(14)
        .fontColor('#86868B')
        .margin({ top: 8, left: 24, right: 24 })

      if (this.settings.quietHoursEnabled) {
        Row() {
          Text('Quiet period')
            .fontSize(14)
            .fontColor('#1D1D1F')
            .layoutWeight(1)
          Text('22:00 – 08:00')
            .fontSize(14)
            .fontColor('#86868B')
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 16 })
      }

      Divider().color('#F5F5F7').margin({ top: 16 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
