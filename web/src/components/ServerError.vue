<template>
  <v-card title="加载失败！">
    <template #text>
      未能与服务器通信。<br /><br />
      可能的原因及解决办法：<br />
      <ol>
        <li>
          系统不支持 mdns，无法自动获取您的主机 ip<br />
          尝试为您的电脑设置静态ip<br />
          <v-text-field v-model="static_ip" hide-details="auto" label="主机ip地址"></v-text-field>
        </li>
        <li>
          设置服务器的别名<br />
          <v-text-field v-model="server_alias" hide-details="auto" label="别名"></v-text-field>
        </li>
        <li>
          网络故障<br />
          尝试重新加载
        </li>
        <li>
          未连接wifi<br />
          只能在局域网工作
        </li>
        <li>未安装配套的服务器程序</li>
      </ol>
      <br />
      <hr height="1px" />
      <br />

      只需断开 wifi 打开应用即可展示当前页面
    </template>
    <v-card-actions>
      <v-btn @click="reload()">重新加载</v-btn>
    </v-card-actions>
  </v-card>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { setStaticIp, getStaticIp, setServerAlias, getServerAlias } from '@/utils/storage'

const static_ip = ref<string>('')
const server_alias = ref<string>('')

watch(static_ip, (s) => {
  setStaticIp(s as any)
})

watch(server_alias, (s) => {
  setServerAlias(s as any)
})

function reload() {
  window.location.reload()
}

onMounted(() => {
  getStaticIp().then((res) => {
    static_ip.value = res.value ?? ''
  })
  getServerAlias().then((res) => {
    server_alias.value = res.value ?? ''
  })
})
</script>

<style scoped lang="scss">
ol {
  margin-left: 1em;
}
li {
  margin-top: 15px;
}
</style>
