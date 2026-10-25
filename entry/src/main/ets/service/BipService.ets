import audio from '@ohos.multimedia.audio'
import vibrator from '@ohos.vibrator'
import { AppSettings, isInBedtime } from '../common/Settings'

// Gera a sequência inteira num único buffer — sem recriar renderer por bip
async function playSequence(pulses: number, freq: number, beepMs: number): Promise<void> {
  const sampleRate  = 44100
  const gapMs       = beepMs
  const beepSamples = Math.floor(sampleRate * beepMs  / 1000)
  const gapSamples  = Math.floor(sampleRate * gapMs   / 1000)
  const totalSamples = pulses * beepSamples + (pulses - 1) * gapSamples

  const buf  = new ArrayBuffer(totalSamples * 2)
  const view = new DataView(buf)

  let pos = 0
  for (let p = 0; p < pulses; p++) {
    // bip
    for (let i = 0; i < beepSamples; i++) {
      const t   = i / sampleRate
      const att = sampleRate * 0.005
      const rel = sampleRate * 0.015
      const env = i < att ? i / att : i > beepSamples - rel ? (beepSamples - i) / rel : 1.0
      const sig = Math.sin(2 * Math.PI * freq * t)
               + 0.7 * Math.sin(2 * Math.PI * freq * 2 * t)
               + 0.3 * Math.sin(2 * Math.PI * freq * 3 * t)
      const v = Math.round(18000 * env * sig / 1.57)
      view.setInt16(pos * 2, Math.max(-32768, Math.min(32767, v)), true)
      pos++
    }
    // silêncio entre bips
    if (p < pulses - 1) {
      for (let i = 0; i < gapSamples; i++) {
        view.setInt16(pos * 2, 0, true)
        pos++
      }
    }
  }

  let renderer: audio.AudioRenderer | null = null
  try {
    renderer = await audio.createAudioRenderer({
      streamInfo: {
        samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_44100,
        channels:     audio.AudioChannel.CHANNEL_1,
        sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE,
        encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW
      },
      rendererInfo: {
        usage:         audio.StreamUsage.STREAM_USAGE_ALARM,
        rendererFlags: 0
      }
    })
    await renderer.start()
    await renderer.write(buf)
    await renderer.drain()
    await renderer.stop()
  } catch (_) {
  } finally {
    if (renderer) {
      try { await renderer.release() } catch (_) {}
    }
  }
}

async function buzz(durationMs: number): Promise<void> {
  try {
    await vibrator.startVibration(
      { type: 'time', duration: durationMs },
      { id: 0, usage: 'alarm' }
    )
  } catch (_) {}
}

export async function doBip(settings: AppSettings, forceFullHour: boolean = false): Promise<void> {
  if (!settings.enabled) return
  if (isInBedtime(settings)) return

  const isFullHour = forceFullHour || new Date().getMinutes() === 0
  const pulses     = isFullHour ? settings.fullHourPulses : settings.halfHourPulses

  const beepMs        = 80
  const totalDuration = pulses * beepMs + (pulses - 1) * beepMs
  await Promise.all([playSequence(pulses, settings.freq, beepMs), buzz(totalDuration)])
}
