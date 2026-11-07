import common from '@ohos.app.ability.common'
import { AppSettings, loadSettings, saveSettings } from '../common/Settings'
import { doBip } from '../service/BipService'

const MINS: number[] = [0, 10, 20, 30, 40, 50]

@Entry
@Component
struct IndexPage {
  @State settings: AppSettings = new AppSettings()
  @State bedStartHour: number = 22
  @State bedStartMin: number = 0
  @State bedEndHour: number = 7
  @State bedEndMin: number = 0
  @State showStartPicker: boolean = false
  @State showEndPicker: boolean = false

  private intervalId: number = -1
  private context = getContext(this) as common.UIAbilityContext
  private scroller: Scroller = new Scroller()
  private startMinScroller: Scroller = new Scroller()
  private endMinScroller: Scroller = new Scroller()

  async aboutToAppear(): Promise<void> {
    this.settings = await loadSettings(this.context)
    const startParts = this.settings.bedtimeStart.split(':')
    this.bedStartHour = Number(startParts[0])
    this.bedStartMin  = Math.round(Number(startParts[1]) / 10) * 10 % 60
    const endParts = this.settings.bedtimeEnd.split(':')
    this.bedEndHour = Number(endParts[0])
    this.bedEndMin  = Math.round(Number(endParts[1]) / 10) * 10 % 60
    this.startTimer()
  }

  onBackPress(): boolean {
    if (this.showStartPicker) { this.showStartPicker = false; return true }
    if (this.showEndPicker)   { this.showEndPicker   = false; return true }
    return false
  }

  aboutToDisappear(): void {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId)
      this.intervalId = -1
    }
  }

  private startTimer(): void {
    if (this.intervalId !== -1) clearInterval(this.intervalId)
    this.intervalId = setInterval(async () => {
      const now = new Date()
      const m = now.getMinutes()
      const s = now.getSeconds()
      if ((m === 0 || m === 30) && s < 5) await doBip(this.settings)
    }, 5000)
  }

  private copyWith(field: string, value: boolean | number | string): AppSettings {
    const s = new AppSettings()
    s.enabled        = field === 'enabled'        ? value as boolean : this.settings.enabled
    s.volume         = field === 'volume'         ? value as number  : this.settings.volume
    s.bedtimeEnabled = field === 'bedtimeEnabled' ? value as boolean : this.settings.bedtimeEnabled
    s.bedtimeStart   = field === 'bedtimeStart'   ? value as string  : this.settings.bedtimeStart
    s.bedtimeEnd     = field === 'bedtimeEnd'     ? value as string  : this.settings.bedtimeEnd
    s.freq           = field === 'freq'           ? value as number  : this.settings.freq
    s.fullHourPulses = field === 'fullHourPulses' ? value as number  : this.settings.fullHourPulses
    s.halfHourPulses = field === 'halfHourPulses' ? value as number  : this.settings.halfHourPulses
    return s
  }

  private async persist(s: AppSettings): Promise<void> {
    this.settings = s
    await saveSettings(this.context, s)
  }

  private pad(n: number): string { return n < 10 ? `0${n}` : `${n}` }

  @Builder
  TimePicker2(
    hour: number,
    min: number,
    onHour: (h: number) => void,
    onMin: (m: number) => void,
    minScroller: Scroller
  ) {
    Row({ space: 10 }) {
      // ── Hora ──
      Column({ space: 4 }) {
        Button('+')
          .width(50).height(28).fontSize(16).fontColor('#CCCCCC')
          .backgroundColor('#2A2A3C').borderRadius(8)
          .onClick(() => onHour((hour + 1) % 24))
        Text(this.pad(hour))
          .fontSize(34).fontColor('#FFFFFF').fontWeight(FontWeight.Bold)
          .width(58).textAlign(TextAlign.Center)
        Button('-')
          .width(50).height(28).fontSize(16).fontColor('#CCCCCC')
          .backgroundColor('#2A2A3C').borderRadius(8)
          .onClick(() => onHour((hour + 23) % 24))
      }

      Text(':').fontSize(34).fontColor('#666688').margin({ bottom: 4 })

      // ── Minuto (List com coroa) ──
      Column({ space: 4 }) {
        Button('+')
          .width(50).height(28).fontSize(16).fontColor('#4A90E2')
          .backgroundColor('#2A2A3C').borderRadius(8)
          .onClick(() => {
            const next = (min + 10) % 60
            onMin(next)
            minScroller.scrollToIndex(next / 10, false, ScrollAlign.CENTER)
          })
        List({ scroller: minScroller, initialIndex: min / 10 }) {
          ForEach(MINS, (m: number) => {
            ListItem() {
              Text(this.pad(m))
                .fontSize(34).fontWeight(FontWeight.Bold)
                .fontColor('#4A90E2')
                .width(58).height(44).textAlign(TextAlign.Center)
            }
          }, (m: number) => `${m}`)
        }
        .width(58).height(44)
        .scrollBar(BarState.Off)
        .scrollSnapAlign(ScrollSnapAlign.CENTER)
        .digitalCrownSensitivity(CrownSensitivity.MEDIUM)
        .focusable(true)
        .defaultFocus(true)
        .onScrollIndex((first: number) => { onMin(MINS[first]) })
        Button('-')
          .width(50).height(28).fontSize(16).fontColor('#4A90E2')
          .backgroundColor('#2A2A3C').borderRadius(8)
          .onClick(() => {
            const prev = (min - 10 + 60) % 60
            onMin(prev)
            minScroller.scrollToIndex(prev / 10, false, ScrollAlign.CENTER)
          })
      }
    }
  }

  build() {
    Stack() {

      // ── Tela principal ──
      Scroll(this.scroller) {
        Column({ space: 12 }) {

          Text('Hourly Beep')
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF').margin({ top: 16, bottom: 4 })

          Row() {
            Text('Active').fontSize(15).fontColor('#CCCCCC').flexGrow(1)
            Toggle({ type: ToggleType.Switch, isOn: this.settings.enabled })
              .selectedColor('#ff61e24a')
              .onChange(async (val) => { await this.persist(this.copyWith('enabled', val)) })
          }
          .width('88%').padding({ left: 12, right: 26, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E').borderRadius(12)

          Column({ space: 6 }) {
            Text(`Volume: ${this.settings.volume}%`).fontSize(13).fontColor('#CCCCCC')
            Slider({ value: this.settings.volume, min: 0, max: 100, step: 10, style: SliderStyle.OutSet })
              .selectedColor('#4A90E2')
              .onChange(async (val) => { await this.persist(this.copyWith('volume', Math.round(val))) })
          }
          .width('88%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E').borderRadius(12)

          Column({ space: 6 }) {
            Text(`Freq: ${this.settings.freq} Hz`).fontSize(13).fontColor('#CCCCCC')
            Slider({ value: this.settings.freq, min: 500, max: 8000, step: 500, style: SliderStyle.OutSet })
              .selectedColor('#4A90E2')
              .onChange(async (val) => { await this.persist(this.copyWith('freq', Math.round(val))) })
          }
          .width('88%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E').borderRadius(12)

          Column({ space: 6 }) {
            Text(`Full Hour: ${this.settings.fullHourPulses} bips`).fontSize(13).fontColor('#CCCCCC')
            Slider({ value: this.settings.fullHourPulses, min: 1, max: 6, step: 1, style: SliderStyle.OutSet })
              .selectedColor('#4A90E2')
              .onChange(async (val) => { await this.persist(this.copyWith('fullHourPulses', Math.round(val))) })
          }
          .width('88%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E').borderRadius(12)

          Column({ space: 6 }) {
            Text(`Half Hour: ${this.settings.halfHourPulses} bips`).fontSize(13).fontColor('#CCCCCC')
            Slider({ value: this.settings.halfHourPulses, min: 0, max: 4, step: 1, style: SliderStyle.OutSet })
              .selectedColor('#4A90E2')
              .onChange(async (val) => { await this.persist(this.copyWith('halfHourPulses', Math.round(val))) })
          }
          .width('88%').padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E').borderRadius(12)

          Button('Beep Test')
            .width('88%').height(40).fontSize(14)
            .backgroundColor('#2A6496').borderRadius(12)
            .onClick(async () => { await doBip(this.settings, true) })

          Column({ space: 10 }) {
            Row() {
              Text('Bed time').fontSize(14).fontColor('#CCCCCC').flexGrow(1)
              Toggle({ type: ToggleType.Switch, isOn: this.settings.bedtimeEnabled })
                .selectedColor('#4A90E2')
                .onChange(async (val) => { await this.persist(this.copyWith('bedtimeEnabled', val)) })
            }
            if (this.settings.bedtimeEnabled) {
              Row({ space: 10 }) {
                Column({ space: 4 }) {
                  Text('Start').fontSize(11).fontColor('#888888')
                  Button(`${this.pad(this.bedStartHour)}:${this.pad(this.bedStartMin)}`)
                    .fontSize(13).fontColor(Color.White).backgroundColor('#3A3A5C')
                    .borderRadius(8).width(68).height(36)
                    .onClick(() => { this.showStartPicker = true })
                }
                Text('→').fontSize(16).fontColor('#888888')
                Column({ space: 4 }) {
                  Text('End').fontSize(11).fontColor('#888888')
                  Button(`${this.pad(this.bedEndHour)}:${this.pad(this.bedEndMin)}`)
                    .fontSize(13).fontColor(Color.White).backgroundColor('#3A3A5C')
                    .borderRadius(8).width(68).height(36)
                    .onClick(() => { this.showEndPicker = true })
                }
              }.justifyContent(FlexAlign.Center)
            }
          }
          .width('88%').padding({ left: 14, right: 14, top: 10, bottom: 14 })
          .backgroundColor('#1E1E2E').borderRadius(12)

        }
        .width('100%').alignItems(HorizontalAlign.Center).padding({ bottom: 24 })
      }
      .id('mainScroll')
      .width('100%').height('100%')
      .focusable(true).defaultFocus(true)
      .digitalCrownSensitivity(CrownSensitivity.MEDIUM)
      .onAppear(() => { focusControl.requestFocus('mainScroll') })

      // ── Picker Start ──
      if (this.showStartPicker) {
        Column({ space: 0 }) {
          Text('Start').fontSize(14).fontColor('#CCCCCC').margin({ top: 14 })
          this.TimePicker2(
            this.bedStartHour, this.bedStartMin,
            (h) => { this.bedStartHour = h },
            (m) => { this.bedStartMin = m },
            this.startMinScroller
          )
          Row({ space: 10 }) {
            Button('Cancel').width('42%').height(34).fontSize(13)
              .backgroundColor('#3A3A5C').borderRadius(10)
              .onClick(() => { this.showStartPicker = false })
            Button('OK').width('42%').height(34).fontSize(13)
              .backgroundColor('#4A90E2').borderRadius(10)
              .onClick(async () => {
                this.showStartPicker = false
                await this.persist(this.copyWith('bedtimeStart', `${this.pad(this.bedStartHour)}:${this.pad(this.bedStartMin)}`))
              })
          }.margin({ bottom: 14 })
        }
        .width('100%').height('100%')
        .backgroundColor('#0F0F1A')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Center)
      }

      // ── Picker End ──
      if (this.showEndPicker) {
        Column({ space: 0 }) {
          Text('End').fontSize(14).fontColor('#CCCCCC').margin({ top: 14 })
          this.TimePicker2(
            this.bedEndHour, this.bedEndMin,
            (h) => { this.bedEndHour = h },
            (m) => { this.bedEndMin = m },
            this.endMinScroller
          )
          Row({ space: 10 }) {
            Button('Cancel').width('42%').height(34).fontSize(13)
              .backgroundColor('#3A3A5C').borderRadius(10)
              .onClick(() => { this.showEndPicker = false })
            Button('OK').width('42%').height(34).fontSize(13)
              .backgroundColor('#4A90E2').borderRadius(10)
              .onClick(async () => {
                this.showEndPicker = false
                await this.persist(this.copyWith('bedtimeEnd', `${this.pad(this.bedEndHour)}:${this.pad(this.bedEndMin)}`))
              })
          }.margin({ bottom: 14 })
        }
        .width('100%').height('100%')
        .backgroundColor('#0F0F1A')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Center)
      }

    }
    .width('100%').height('100%').backgroundColor('#0F0F1A')
  }
}
