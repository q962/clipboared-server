import bus from '@/utils/event.ts'

export interface AnyObject extends object {
  [key: string]: any
}

export interface ExtendedWindow extends Window {
  [key: string]: any
}

declare global {
  const EventBus = bus
  const _window = ExtendedWindow

  const _G: AnyObject = globalThis
}
