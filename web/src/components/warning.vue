<template>
  <v-dialog max-width="500" v-model="isActive">
    <v-card title="提示">
      <v-card-text>
        {{ message }}
      </v-card-text>

      <v-card-actions>
        <v-spacer></v-spacer>

        <v-btn text="关闭" variant="text" @click="isActive = false"></v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup lang="ts">
import { ref, defineExpose } from 'vue'

const message = ref('')
const isActive = ref(false)

function show(msg: string) {
  message.value = msg
  isActive.value = true
}

defineExpose({ show })
//
</script>
