import { smdns } from 'capacitor-community-smdns'
import { Capacitor } from '@capacitor/core'
import { getStaticIp, getServerAlias } from './storage'

let server_host: undefined | string = undefined

const listen_cb: Array<(has_server_host?: boolean) => void> = []

smdns.discoverServices('_http._tcp', {
  onServiceFound: (name, host, port) => {
    console.log(name, host, port)

    const array = name!.split('::')

    if (array.length != 2) return

    getServerAlias().then((server_alias) => {
      if (server_alias.value?.length == 0) {
        if (array[0] != 'Clipboard-server') return
      } else {
        if (array[0] != `Clipboard-server-${server_alias.value}`) return
      }

      server_host = array[1]

      listen_cb.map((cb) => {
        cb(!!server_host)
      })
    })
  }
})

export function ServerFound(cb?: (has_server_host?: boolean) => void) {
  if (Capacitor.getPlatform() == 'web') {
    return cb?.(true), true
  }

  if (cb) listen_cb.push(cb)

  return !!server_host
}

export function isPlatform(name: string): boolean {
  switch (name) {
    case 'Capacitor': {
      return Capacitor.isNativePlatform()
    }
  }

  return false
}

export async function myfetch(url: string, opt?: RequestInit): Promise<Response> {
  if (!url.startsWith('/')) url = '/' + url

  // web 访问
  if (Capacitor.getPlatform() == 'web') {
    return fetch(url, opt)
  }

  let _server_host = server_host
  let url_prefix = 'http://'

  if (!server_host) {
    if ((await getStaticIp()).value) {
      if (/^http/.test((await getStaticIp()).value ?? '')) {
        url_prefix = ''
      }
      _server_host = (await getStaticIp()).value ?? ''
    } else {
      throw 'no server_host'
    }
  }

  return fetch(url_prefix + _server_host + url, opt)
}
