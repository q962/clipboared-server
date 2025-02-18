<template>
  <div class="float-btn-box">
    <v-dialog
      v-model="push_dialog"
      max-width="500"
      persistent
      @afterLeave="push_btn_visiable = true"
    >
      <template v-slot:activator="{ props: activatorProps }">
        <v-btn
          :class="{ unvisible: !push_btn_visiable }"
          v-bind="activatorProps"
          rounded="xl"
          @click="push_btn_visiable = false"
        >
          <div>
            <v-icon icon="mdi-clipboard-edit-outline" />
            <span> PUSH</span>
          </div>
        </v-btn>
      </template>

      <template v-slot:default="{ isActive }">
        <v-card>
          <v-card-item>
            <v-card-title>
              <v-icon icon="mdi-clipboard-edit-outline" /><span> PUSH</span></v-card-title
            >
          </v-card-item>

          <v-card-text>
            <v-radio-group v-model="push_type">
              <table style="width: 100%">
                <tbody>
                  <tr>
                    <td>
                      <v-textarea
                        :disabled="pushing"
                        v-model="push_text_content"
                        @click="push_type = 'text'"
                        hide-details
                        variant="outlined"
                        label="内容"
                      ></v-textarea>
                    </td>
                    <td style="width: 2em">
                      <v-radio :disabled="pushing" value="text"></v-radio>
                    </td>
                  </tr>
                  <tr>
                    <td>
                      <v-file-input
                        :disabled="pushing"
                        v-model="push_image_file"
                        @update:modelValue="push_type = 'image'"
                        hide-details
                        accept="image/jpeg,image/png,image/bmp"
                        label="图片"
                      ></v-file-input>
                    </td>
                    <td style="width: 2em">
                      <v-radio :disabled="pushing" value="image"></v-radio>
                    </td>
                  </tr>
                </tbody>
              </table>
            </v-radio-group>

            <v-alert
              v-show="push_error_alert_visiable"
              :border="'top'"
              type="warning"
              variant="outlined"
              prominent
            >
              推送失败
            </v-alert>
          </v-card-text>

          <v-card-actions>
            <v-spacer></v-spacer>

            <v-btn text="重置内容" @click="clear_push_old_data()"></v-btn>
            <v-btn :loading="pushing" variant="tonal" text="推送" @click="push()"></v-btn>
            <v-btn
              text="取消"
              @click="(push_error_alert_visiable = false), (isActive.value = false)"
            ></v-btn>
          </v-card-actions>
        </v-card>
      </template>
    </v-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { myfetch } from '@/utils/utils.ts'

const push_btn_visiable = ref(true)
const push_type = ref()
const push_text_content = ref()
const push_image_file = ref()
const pushing = ref(false)
const push_dialog = ref()
const push_error_alert_visiable = ref(false)

function clear_push_old_data() {
  push_type.value = null
  push_text_content.value = null
  push_image_file.value = null

  push_error_alert_visiable.value = false
}

function push() {
  if (!push_type.value) {
    // TODO: 颤抖提示
    return
  }

  let form_data = undefined! as FormData

  if (push_type.value == 'image') {
    if (!push_image_file.value) return

    form_data = new FormData()
    form_data.append('image', push_image_file.value)
  } else if (push_type.value == 'text') {
    if (!push_text_content.value) return

    form_data = new FormData()
    form_data.append('text', push_text_content.value)
  }

  pushing.value = true
  push_error_alert_visiable.value = false

  push_req(form_data).then((ret: boolean) => {
    pushing.value = false

    if (ret == true) {
      push_dialog.value = false
      clear_push_old_data()
      return
    } else {
      push_error_alert_visiable.value = true

      //
    }
  })
}

function delay(ms: number): Promise<any> {
  return new Promise<any>((resolve) => {
    setTimeout(resolve, ms)
  })
}

async function push_req(form_data: FormData): Promise<boolean> {
  try {
    let start_time = Date.now()

    let response = await myfetch('/api/push', {
      method: 'POST',
      body: form_data
    })

    let end_time = Date.now()

    let cha = end_time - start_time
    if (cha < 300) {
      await delay(300 - cha)
    }

    if (response.status != 200) return false
  } catch (error) {
    EventBus.emit('fetch-failed')
  }

  return true
}
</script>

<style>
.push_type_group .v-radio.fix-width > .v-label {
  width: 100%;
}
</style>

<style scoped lang="scss">
.float-btn-box {
  position: absolute;
  bottom: 0;
  left: 0;
  width: 100%;
  display: flex;
  justify-content: center;

  > .v-btn {
    &.unvisible {
      opacity: 0;
    }

    & {
      top: -5em;
      width: 6em;
      height: 2.5em;
    }
  }
}
.v-radio {
  margin: 1em 0;
}

.clip-data-list {
  height: 100%;
}
</style>
