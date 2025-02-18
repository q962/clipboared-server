import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'io.github.q962.clipserver',
  appName: '剪切板',
  webDir: 'dist-app',

  plugins: {
    CapacitorHttp: {
      enabled: true
    }
  }
}

export default config
