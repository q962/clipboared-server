<template>
  <div class="clip-data-item">
    <template v-if="typeof item == 'string'">
      <textarea
        @click.stop="toggle_rows_v2()"
        :class="{ unscroll: has_more_rows() && !is_show_all_rows }"
        class="float"
        :rows="rows"
        readonly
        :value="item"
      ></textarea>
      <div class="btn-box">
        <v-btn class="btn" variant="plain" @click="set_clip()">复制</v-btn>
        <v-icon
          class="expand-icon"
          v-show="text_rows > rows || is_show_all_rows"
          :icon="is_show_all_rows ? 'mdi-chevron-up' : 'mdi-chevron-down'"
          size="large"
          @click="toggle_rows()"
        ></v-icon>
      </div>
    </template>
    <template v-else>
      <img v-viewer="{ navbar: false }" class="small_img" :src="imageUrl" />
      <v-btn class="btn" variant="plain" @click="save_img()">保存</v-btn>
    </template>
  </div>

  <warning class="warning" ref="warningRef"></warning>
</template>

<script setup lang="ts">
import { ref, defineProps, computed } from 'vue'
import imageCompression from 'browser-image-compression'
import warning from './warning.vue'
import { Clipboard } from '@capacitor/clipboard'

const props = defineProps(['item', 'item_id']) as {
  item: string | number | Uint8Array
  item_id: number
}

const warningRef = ref()

let imgBlob = undefined! as Blob

const imageUrl = computed(() => {
  if (!(props.item instanceof Uint8Array)) {
    return
  }

  imgBlob = new Blob([props.item as Uint8Array])

  return window.URL.createObjectURL(imgBlob)
})

const text_rows = computed(() => {
  return (props.item as string).split('\r\n').length
})

let is_show_all_rows = ref(false)
const rows = computed(() => {
  if (text_rows.value > 3) {
    if (is_show_all_rows.value) return text_rows.value > 10 ? 10 : text_rows.value
    else return 3
  }
  return text_rows.value
})

const has_more_rows = () => {
  if (text_rows.value > 3) {
    return true
  }
  return false
}

function toggle_rows_v2() {
  if (!has_more_rows()) return

  toggle_rows()
}

function toggle_rows() {
  is_show_all_rows.value = !is_show_all_rows.value
}

function set_clip() {
  Clipboard.write({
    string: props.item as string
  }).catch(() => {
    warningRef.value.show('设置剪切板内容失败：没有权限')
  })
}

async function save_img() {
  if (navigator.userAgent.indexOf('Safari') > -1) {
    warningRef.value.show('Safari 浏览器请长按图片保存')
  } else {
    try {
      const compressedFile = (await imageCompression(
        new File([imgBlob], 'a.bmp', { type: 'image/bmp' }),
        {
          useWebWorker: true,
          fileType: 'image/jpeg'
        }
      )) as Blob

      let url = window.URL.createObjectURL(compressedFile)
      let url_split = url.split('/')

      var a = document.createElement('a')
      a.download = url_split[url_split.length - 1] + '.jpg'
      a.href = url
      a.click()
    } catch (error) {
      warningRef.value.show('保存失败，请尝试长按图片保存')
    }
  }
}
</script>

<style scoped lang="scss">
.clip-data-item {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  border-radius: 5px;
  background: var(--color-background-soft);
  margin: 5px 0;
  padding: 10px;
  column-gap: 10px;
}

.small_img {
  max-width: 100%;
  max-height: 100px;
}

.btn {
  height: 100%;
}

.btn-box {
  display: grid;
  grid-template-columns: 100%;
  grid-template-rows: minmax(0, 1fr) auto;

  .expand-icon {
    margin-top: 5px;
    place-self: center;
  }
}

textarea {
  resize: unset;

  outline: unset;
  cursor: default;
  color: var(--color-text);
  text-overflow: ellipsis;
  white-space: pre;
  scrollbar-width: none;

  &.unscroll {
    overflow-y: hidden;
  }

  &::-webkit-scrollbar {
    display: none;
  }
}
</style>
