import common from '@ohos.app.ability.common'
import { AppSettings, loadSettings, saveSettings } from '../common/Settings'
import { doBip } from '../service/BipService'

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

  async aboutToAppear(): Promise<void> {
    this.settings = await loadSettings(this.context)
    const startParts = this.settings.bedtimeStart.split(':')
    this.bedStartHour = Number(startParts[0])
    this.bedStartMin  = Number(startParts[1])
    const endParts = this.settings.bedtimeEnd.split(':')
    this.bedEndHour = Number(endParts[0])
    this.bedEndMin  = Number(endParts[1])
    this.startTimer()
    focusControl.requestFocus('mainScroll')
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
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId)
    }
    this.intervalId = setInterval(async () => {
      const now = new Date()
      const m = now.getMinutes()
      const s = now.getSeconds()
      if ((m === 0 || m === 30) && s < 5) {
        await doBip(this.settings)
      }
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

  private pad(n: number): string {
    return n < 10 ? `0${n}` : `${n}`
  }

  build() {
    Stack() {
      Scroll(this.scroller) {
        Column({ space: 12 }) {

          Text('Hourly Beep')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ top: 16, bottom: 4 })

          // ── Ativar ──
          Row() {
            Text('Ativado')
              .fontSize(15)
              .fontColor('#CCCCCC')
              .flexGrow(1)
            Toggle({ type: ToggleType.Switch, isOn: this.settings.enabled })
              .selectedColor('#ff61e24a')
              .onChange(async (val) => {
                await this.persist(this.copyWith('enabled', val))
              })
          }
          .width('88%')
          .padding({ left: 12, right: 26, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E')
          .borderRadius(12)

          // ── Volume ──
          Column({ space: 6 }) {
            Text(`Volume: ${this.settings.volume}%`)
              .fontSize(13)
              .fontColor('#CCCCCC')
            Slider({
              value: this.settings.volume,
              min: 0, max: 100, step: 10,
              style: SliderStyle.OutSet
            })
              .selectedColor('#4A90E2')
              .onChange(async (val) => {
                await this.persist(this.copyWith('volume', Math.round(val)))
              })
          }
          .width('88%')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E')
          .borderRadius(12)

          // ── Tom ──
          Column({ space: 6 }) {
            Text(`Tom: ${this.settings.freq} Hz`)
              .fontSize(13)
              .fontColor('#CCCCCC')
            Slider({
              value: this.settings.freq,
              min: 500, max: 8000, step: 500,
              style: SliderStyle.OutSet
            })
              .selectedColor('#4A90E2')
              .onChange(async (val) => {
                await this.persist(this.copyWith('freq', Math.round(val)))
              })
          }
          .width('88%')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E')
          .borderRadius(12)

          // ── Bips hora cheia ──
          Column({ space: 6 }) {
            Text(`Hora cheia: ${this.settings.fullHourPulses} bips`)
              .fontSize(13)
              .fontColor('#CCCCCC')
            Slider({
              value: this.settings.fullHourPulses,
              min: 1, max: 6, step: 1,
              style: SliderStyle.OutSet
            })
              .selectedColor('#4A90E2')
              .onChange(async (val) => {
                await this.persist(this.copyWith('fullHourPulses', Math.round(val)))
              })
          }
          .width('88%')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E')
          .borderRadius(12)

          // ── Bips meia-hora ──
          Column({ space: 6 }) {
            Text(`Meia-hora: ${this.settings.halfHourPulses} bips`)
              .fontSize(13)
              .fontColor('#CCCCCC')
            Slider({
              value: this.settings.halfHourPulses,
              min: 1, max: 4, step: 1,
              style: SliderStyle.OutSet
            })
              .selectedColor('#4A90E2')
              .onChange(async (val) => {
                await this.persist(this.copyWith('halfHourPulses', Math.round(val)))
              })
          }
          .width('88%')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#1E1E2E')
          .borderRadius(12)

          // ── Testar ──
          Button('Beep Test')
            .width('88%')
            .height(40)
            .fontSize(14)
            .backgroundColor('#2A6496')
            .borderRadius(12)
            .onClick(async () => {
              await doBip(this.settings, true)
            })

          // ── Bedtime ──
          Column({ space: 10 }) {
            Row() {
              Text('Silenciar à noite')
                .fontSize(14)
                .fontColor('#CCCCCC')
                .flexGrow(1)
              Toggle({ type: ToggleType.Switch, isOn: this.settings.bedtimeEnabled })
                .selectedColor('#4A90E2')
                .onChange(async (val) => {
                  await this.persist(this.copyWith('bedtimeEnabled', val))
                })
            }

            if (this.settings.bedtimeEnabled) {
              Row({ space: 10 }) {
                Column({ space: 4 }) {
                  Text('Início').fontSize(11).fontColor('#888888')
                  Button(`${this.pad(this.bedStartHour)}:${this.pad(this.bedStartMin)}`)
                    .fontSize(13)
                    .fontColor(Color.White)
                    .backgroundColor('#3A3A5C')
                    .borderRadius(8)
                    .width(68).height(36)
                    .onClick(() => { this.showStartPicker = true })
                }
                Text('→').fontSize(16).fontColor('#888888')
                Column({ space: 4 }) {
                  Text('Fim').fontSize(11).fontColor('#888888')
                  Button(`${this.pad(this.bedEndHour)}:${this.pad(this.bedEndMin)}`)
                    .fontSize(13)
                    .fontColor(Color.White)
                    .backgroundColor('#3A3A5C')
                    .borderRadius(8)
                    .width(68).height(36)
                    .onClick(() => { this.showEndPicker = true })
                }
              }
              .justifyContent(FlexAlign.Center)
            }
          }
          .width('88%')
          .padding({ left: 14, right: 14, top: 10, bottom: 14 })
          .backgroundColor('#1E1E2E')
          .borderRadius(12)

        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 24 })
      }
      .id('mainScroll')
      .width('100%')
      .height('100%')
      .focusable(true)
      .defaultFocus(true)
      .digitalCrownSensitivity(CrownSensitivity.MEDIUM)

      // ── Picker Início ──
      if (this.showStartPicker) {
        Column() {
          Text('Início do silêncio')
            .fontSize(15)
            .fontColor('#CCCCCC')
            .margin({ top: 16, bottom: 4 })
          TimePicker({ selected: new Date(2000, 0, 1, this.bedStartHour, this.bedStartMin) })
            .useMilitaryTime(true)
            .height(120)
            .onChange((val: TimePickerResult) => {
              this.bedStartHour = val.hour
              this.bedStartMin  = val.minute
            })
          Row({ space: 10 }) {
            Button('Cancelar')
              .width('32%').height(30)
              .backgroundColor('#3A3A5C')
              .onClick(() => { this.showStartPicker = false })
            Button('OK')
              .width('32%').height(30)
              .backgroundColor('#4A90E2')
              .onClick(async () => {
                this.showStartPicker = false
                const time = `${this.pad(this.bedStartHour)}:${this.pad(this.bedStartMin)}`
                await this.persist(this.copyWith('bedtimeStart', time))
              })
          }.margin({ top: 8, bottom: 16 })
        }
        .width('100%').height('100%')
        .backgroundColor('#0F0F1A')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Center)
      }

      // ── Picker Fim ──
      if (this.showEndPicker) {
        Column() {
          Text('Fim do silêncio')
            .fontSize(13)
            .fontColor('#CCCCCC')
            .margin({ top: 16, bottom: 4 })
          TimePicker({ selected: new Date(2000, 0, 1, this.bedEndHour, this.bedEndMin) })
            .useMilitaryTime(true)
            .height(160)
            .onChange((val: TimePickerResult) => {
              this.bedEndHour = val.hour
              this.bedEndMin  = val.minute
            })
          Row({ space: 12 }) {
            Button('Cancelar')
              .width('38%').height(36)
              .backgroundColor('#3A3A5C')
              .onClick(() => { this.showEndPicker = false })
            Button('OK')
              .width('38%').height(36)
              .backgroundColor('#4A90E2')
              .onClick(async () => {
                this.showEndPicker = false
                const time = `${this.pad(this.bedEndHour)}:${this.pad(this.bedEndMin)}`
                await this.persist(this.copyWith('bedtimeEnd', time))
              })
          }.margin({ top: 8, bottom: 16 })
        }
        .width('100%').height('100%')
        .backgroundColor('#0F0F1A')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(HorizontalAlign.Center)
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0F0F1A')
  }
}
