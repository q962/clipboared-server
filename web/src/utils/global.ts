import type { ExtendedWindow } from '@/global'
import bus from '@/utils/event.ts'

;(globalThis as any)._G = globalThis

_G.EventBus = bus
_G._window = window as ExtendedWindow
