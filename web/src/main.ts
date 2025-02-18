import './assets/main.css'

import '@/utils/global.ts'

import { createApp } from 'vue'

import '@mdi/font/css/materialdesignicons.css'

// Vuetify
import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import 'viewerjs/dist/viewer.css'
import VueViewer from 'v-viewer'

import App from './App.vue'

const vuetify = createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'light'
  }
})

const app = createApp(App).use(vuetify).use(VueViewer).mount('#app')

const prefersDarkScheme = window.matchMedia('(prefers-color-scheme: dark)')
function setDarkTheme() {
  const appContext = app.$.appContext
  const ThemeSymbol = Symbol.for('vuetify:theme')
  appContext.provides[ThemeSymbol].name.value = prefersDarkScheme.matches ? 'dark' : 'light'
}
prefersDarkScheme.addEventListener('change', setDarkTheme)
setDarkTheme()
