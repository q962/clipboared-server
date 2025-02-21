import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'io.github.q962.clipserver',
  appName: '剪切板',
  webDir: 'dist-app',

  plugins: {
    CapacitorHttp: {
      enabled: true
    }
  },
  android: {
    buildOptions: {
      releaseType: 'APK'
    }
  }
}

export default config
