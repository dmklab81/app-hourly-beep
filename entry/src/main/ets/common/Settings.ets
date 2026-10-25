import preferences from '@ohos.data.preferences'
import common from '@ohos.app.ability.common'

export class AppSettings {
  enabled: boolean = true
  volume: number = 70
  bedtimeEnabled: boolean = false
  bedtimeStart: string = '22:00'
  bedtimeEnd: string = '07:00'
  freq: number = 4500
  fullHourPulses: number = 4
  halfHourPulses: number = 2
}

let store: preferences.Preferences | null = null

async function getStore(context: common.UIAbilityContext): Promise<preferences.Preferences> {
  if (!store) {
    store = await preferences.getPreferences(context, 'bip_settings')
  }
  return store
}

export async function loadSettings(context: common.UIAbilityContext): Promise<AppSettings> {
  const s = new AppSettings()
  try {
    const p = await getStore(context)
    s.enabled        = await p.get('enabled',        s.enabled)        as boolean
    s.volume         = await p.get('volume',          s.volume)         as number
    s.bedtimeEnabled = await p.get('bedtimeEnabled',  s.bedtimeEnabled) as boolean
    s.bedtimeStart   = await p.get('bedtimeStart',    s.bedtimeStart)   as string
    s.bedtimeEnd     = await p.get('bedtimeEnd',      s.bedtimeEnd)     as string
    s.freq           = await p.get('freq',            s.freq)           as number
    s.fullHourPulses = await p.get('fullHourPulses',  s.fullHourPulses) as number
    s.halfHourPulses = await p.get('halfHourPulses',  s.halfHourPulses) as number
  } catch (_) {}
  return s
}

export async function saveSettings(context: common.UIAbilityContext, s: AppSettings): Promise<void> {
  try {
    const p = await getStore(context)
    await p.put('enabled',        s.enabled)
    await p.put('volume',         s.volume)
    await p.put('bedtimeEnabled', s.bedtimeEnabled)
    await p.put('bedtimeStart',   s.bedtimeStart)
    await p.put('bedtimeEnd',     s.bedtimeEnd)
    await p.put('freq',           s.freq)
    await p.put('fullHourPulses', s.fullHourPulses)
    await p.put('halfHourPulses', s.halfHourPulses)
    await p.flush()
  } catch (_) {}
}

export function isInBedtime(s: AppSettings): boolean {
  if (!s.bedtimeEnabled) return false
  const now = new Date()
  const cur = now.getHours() * 60 + now.getMinutes()
  const startParts = s.bedtimeStart.split(':')
  const endParts   = s.bedtimeEnd.split(':')
  const start = Number(startParts[0]) * 60 + Number(startParts[1])
  const end   = Number(endParts[0])   * 60 + Number(endParts[1])
  return start > end ? (cur >= start || cur < end) : (cur >= start && cur < end)
}
