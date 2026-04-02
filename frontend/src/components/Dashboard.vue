<template>
  <div class="min-h-screen bg-slate-900 text-slate-100 p-6">
    <header class="mb-6">
      <h1 class="text-3xl font-bold tracking-wide text-cyan-300">智慧流浪动物救助与云领养基地平台数据看板</h1>
      <p class="text-slate-400 mt-2">指挥中心 · 实时态势总览</p>
    </header>

    <section class="grid grid-cols-1 xl:grid-cols-3 gap-5">
      <div class="xl:col-span-1 rounded-xl bg-slate-800/80 border border-slate-700 p-4 shadow-lg">
        <h2 class="text-lg font-semibold text-cyan-200 mb-3">资金板块占比</h2>
        <div ref="fundsChartRef" class="h-[360px] w-full"></div>
      </div>

      <div class="xl:col-span-2 rounded-xl bg-slate-800/80 border border-slate-700 p-4 shadow-lg">
        <h2 class="text-lg font-semibold text-cyan-200 mb-3">设备 24 小时活跃度</h2>
        <div ref="lineChartRef" class="h-[360px] w-full"></div>
      </div>

      <div class="xl:col-span-3 rounded-xl bg-slate-800/80 border border-slate-700 p-4 shadow-lg overflow-hidden">
        <h2 class="text-lg font-semibold text-cyan-200 mb-3">领养贡献榜（动态滚动）</h2>
        <div class="h-[220px] overflow-hidden relative">
          <ul class="scroll-list space-y-2">
            <li
              v-for="(item, index) in topAdopters"
              :key="`${item.userId}-${index}`"
              class="flex items-center justify-between rounded-lg bg-slate-700/40 px-4 py-3"
            >
              <div class="flex items-center gap-3">
                <span
                  class="inline-flex items-center justify-center w-7 h-7 rounded-full text-sm font-bold"
                  :class="index < 3 ? 'bg-amber-400 text-slate-900' : 'bg-slate-600 text-slate-100'"
                >
                  {{ index + 1 }}
                </span>
                <span class="font-medium">{{ item.userName }}</span>
              </div>
              <div class="text-right text-sm text-slate-300">
                <p>领养动物：{{ item.animalCount }} 只</p>
                <p class="text-cyan-300">总金额：¥{{ item.totalAmount.toFixed(2) }}</p>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import * as echarts from 'echarts'
import axios from 'axios'

const API_BASE = import.meta.env.VITE_API_BASE || 'http://127.0.0.1:8000'

const fundsChartRef = ref(null)
const lineChartRef = ref(null)
const topAdopters = ref([])

let fundsChart = null
let lineChart = null

const fundsData = ref([])
const heatmapRaw = ref([])

const buildFundsOption = () => ({
  backgroundColor: 'transparent',
  tooltip: { trigger: 'item' },
  legend: {
    top: 'bottom',
    textStyle: { color: '#cbd5e1' }
  },
  series: [
    {
      name: '资金占比',
      type: 'pie',
      radius: ['28%', '65%'],
      roseType: 'radius',
      itemStyle: {
        borderRadius: 6
      },
      label: { color: '#e2e8f0' },
      data: fundsData.value
    }
  ]
})

const buildLineOption = () => {
  const hours = Array.from({ length: 24 }, (_, i) => i)
  const countMap = new Map(hours.map((h) => [h, 0]))

  heatmapRaw.value.forEach((item) => {
    const prev = countMap.get(item.hour) || 0
    countMap.set(item.hour, prev + item.count)
  })

  const yData = hours.map((h) => countMap.get(h) || 0)

  return {
    backgroundColor: 'transparent',
    tooltip: { trigger: 'axis' },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: hours.map((h) => `${h}:00`),
      axisLabel: { color: '#cbd5e1' },
      axisLine: { lineStyle: { color: '#475569' } }
    },
    yAxis: {
      type: 'value',
      axisLabel: { color: '#cbd5e1' },
      splitLine: { lineStyle: { color: '#334155' } }
    },
    series: [
      {
        name: '事件次数',
        type: 'line',
        smooth: true,
        symbol: 'circle',
        symbolSize: 6,
        lineStyle: {
          width: 3,
          color: '#22d3ee'
        },
        itemStyle: {
          color: '#67e8f9'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(34, 211, 238, 0.45)' },
            { offset: 1, color: 'rgba(34, 211, 238, 0.05)' }
          ])
        },
        data: yData
      }
    ]
  }
}

const fetchData = async () => {
  const [fundsRes, heatmapRes, adoptersRes] = await Promise.all([
    axios.get(`${API_BASE}/api/funds-sankey`),
    axios.get(`${API_BASE}/api/device-heatmap`),
    axios.get(`${API_BASE}/api/top-adopters`)
  ])

  fundsData.value = fundsRes.data
  heatmapRaw.value = heatmapRes.data
  topAdopters.value = adoptersRes.data
}

const renderCharts = async () => {
  await nextTick()

  if (!fundsChart && fundsChartRef.value) {
    fundsChart = echarts.init(fundsChartRef.value)
  }
  if (!lineChart && lineChartRef.value) {
    lineChart = echarts.init(lineChartRef.value)
  }

  fundsChart?.setOption(buildFundsOption())
  lineChart?.setOption(buildLineOption())
}

const handleResize = () => {
  fundsChart?.resize()
  lineChart?.resize()
}

onMounted(async () => {
  try {
    await fetchData()
    await renderCharts()
    window.addEventListener('resize', handleResize)
  } catch (error) {
    console.error('加载数据失败:', error)
  }
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', handleResize)
  fundsChart?.dispose()
  lineChart?.dispose()
  fundsChart = null
  lineChart = null
})
</script>

<style scoped>
.scroll-list {
  animation: autoScroll 15s linear infinite;
}

.scroll-list:hover {
  animation-play-state: paused;
}

@keyframes autoScroll {
  0% {
    transform: translateY(0);
  }
  100% {
    transform: translateY(-40%);
  }
}
</style>
