import { useState, useEffect, useCallback } from 'react'
import { Line, Doughnut, Bar } from 'react-chartjs-2'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'
import {
  Cpu,
  MemoryStick,
  HardDrive,
  Network,
  Activity,
  Thermometer,
  Clock,
  RefreshCw,
  AlertTriangle,
  CheckCircle,
  TrendingUp,
  TrendingDown,
  Zap,
  Server,
  Wifi,
  Monitor,
  Settings,
  Bell,
  Moon,
  Sun,
  ChevronDown,
  ChevronUp,
  BarChart3,
  PieChart,
  Layers,
  Eye,
  EyeOff,
} from 'lucide-react'
import './App.css'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

function App() {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [lastUpdate, setLastUpdate] = useState(null)
  const [error, setError] = useState(null)
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [refreshInterval, setRefreshInterval] = useState(3)
  const [darkMode, setDarkMode] = useState(true)
  const [expandedSections, setExpandedSections] = useState({
    cpu: true,
    memory: true,
    disk: true,
    network: true,
    gpu: true,
    system: true,
  })
  const [selectedMetric, setSelectedMetric] = useState('cpu')
  const [showHistory, setShowHistory] = useState(true)
  const [cpuHistory, setCpuHistory] = useState([])
  const [memHistory, setMemHistory] = useState([])

  const fetchData = useCallback(async () => {
    try {
      const response = await fetch('/data/system_data.json?' + Date.now())
      if (!response.ok) throw new Error('Data not found')
      const json = await response.json()
      setData(json)
      setLastUpdate(new Date())
      setError(null)
      setLoading(false)

      // Update history
      setCpuHistory(prev => {
        const newHistory = [...prev, json.cpu?.current || 0].slice(-30)
        return newHistory
      })
      setMemHistory(prev => {
        const newHistory = [...prev, json.memory?.percent || 0].slice(-30)
        return newHistory
      })
    } catch (err) {
      console.error('Error fetching data:', err)
      setData(getDemoData())
      setLastUpdate(new Date())
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchData()
    let interval
    if (autoRefresh) {
      interval = setInterval(fetchData, refreshInterval * 1000)
    }
    return () => clearInterval(interval)
  }, [fetchData, autoRefresh, refreshInterval])

  const toggleSection = (section) => {
    setExpandedSections(prev => ({
      ...prev,
      [section]: !prev[section]
    }))
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <div className="relative">
            <RefreshCw className="w-16 h-16 text-blue-500 animate-spin" />
            <div className="absolute inset-0 bg-blue-500/20 blur-2xl rounded-full"></div>
          </div>
          <p className="text-white text-xl font-medium">Loading System Data...</p>
          <p className="text-slate-400 text-sm">Connecting to system monitor</p>
        </div>
      </div>
    )
  }

  const getHealthColor = () => {
    if (data?.health === 'Critical') return 'from-red-500/20 to-red-600/20 border-red-500/50'
    if (data?.health === 'Warning') return 'from-yellow-500/20 to-yellow-600/20 border-yellow-500/50'
    return 'from-green-500/20 to-green-600/20 border-green-500/50'
  }

  const liveChartData = {
    labels: Array(Math.max(cpuHistory.length, 1)).fill('').map((_, i) => i.toString()),
    datasets: [
      {
        label: 'CPU %',
        data: cpuHistory.length ? cpuHistory : [0],
        borderColor: 'rgb(59, 130, 246)',
        backgroundColor: 'rgba(59, 130, 246, 0.1)',
        fill: true,
        tension: 0.4,
      },
      {
        label: 'Memory %',
        data: memHistory.length ? memHistory : [0],
        borderColor: 'rgb(139, 92, 246)',
        backgroundColor: 'rgba(139, 92, 246, 0.1)',
        fill: true,
        tension: 0.4,
      }
    ]
  }

  return (
    <div className={`min-h-screen transition-colors duration-300 ${darkMode
        ? 'bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900'
        : 'bg-gradient-to-br from-slate-100 via-white to-slate-100'
      } p-4 md:p-6`}>
      {/* Header */}
      <header className="mb-6">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div className="relative">
              <div className="p-3 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl shadow-lg shadow-blue-500/25">
                <Activity className="w-8 h-8 text-white" />
              </div>
              <div className="absolute -top-1 -right-1 w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
            </div>
            <div>
              <h1 className={`text-2xl md:text-3xl font-bold ${darkMode ? 'text-white' : 'text-slate-900'}`}>
                System Monitor
              </h1>
              <p className={`${darkMode ? 'text-slate-400' : 'text-slate-600'} text-sm`}>
                {data?.hostname || 'localhost'} • {data?.kernel?.split('-')[0] || 'Unknown'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3 flex-wrap">
            {/* Refresh controls */}
            <div className={`flex items-center gap-2 px-3 py-2 ${darkMode ? 'bg-slate-800/50' : 'bg-white shadow'
              } rounded-lg border ${darkMode ? 'border-slate-700' : 'border-slate-200'}`}>
              <Clock className={`w-4 h-4 ${darkMode ? 'text-slate-400' : 'text-slate-600'}`} />
              <span className={`text-xs ${darkMode ? 'text-slate-300' : 'text-slate-700'}`}>
                {lastUpdate?.toLocaleTimeString()}
              </span>
            </div>

            {/* Auto-refresh toggle */}
            <button
              onClick={() => setAutoRefresh(!autoRefresh)}
              className={`flex items-center gap-2 px-3 py-2 rounded-lg transition-all ${autoRefresh
                  ? 'bg-green-500/20 text-green-400 border border-green-500/30'
                  : darkMode
                    ? 'bg-slate-700 text-slate-300 border border-slate-600'
                    : 'bg-slate-200 text-slate-700 border border-slate-300'
                }`}
            >
              {autoRefresh ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
              <span className="text-xs font-medium">
                {autoRefresh ? 'Live' : 'Paused'}
              </span>
            </button>

            {/* Refresh interval */}
            <select
              value={refreshInterval}
              onChange={(e) => setRefreshInterval(Number(e.target.value))}
              className={`px-3 py-2 rounded-lg text-xs ${darkMode
                  ? 'bg-slate-700 text-slate-300 border-slate-600'
                  : 'bg-white text-slate-700 border-slate-300'
                } border focus:outline-none focus:ring-2 focus:ring-blue-500`}
            >
              <option value={1}>1s</option>
              <option value={3}>3s</option>
              <option value={5}>5s</option>
              <option value={10}>10s</option>
            </select>

            {/* Manual refresh */}
            <button
              onClick={fetchData}
              className="p-2 bg-blue-600 hover:bg-blue-700 rounded-lg transition-colors shadow-lg shadow-blue-500/25"
            >
              <RefreshCw className="w-5 h-5 text-white" />
            </button>

            {/* Dark mode toggle */}
            <button
              onClick={() => setDarkMode(!darkMode)}
              className={`p-2 rounded-lg transition-colors ${darkMode
                  ? 'bg-slate-700 hover:bg-slate-600 text-yellow-400'
                  : 'bg-slate-200 hover:bg-slate-300 text-slate-700'
                }`}
            >
              {darkMode ? <Sun className="w-5 h-5" /> : <Moon className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </header>

      {/* Status Banner */}
      <div className={`mb-6 p-4 rounded-xl backdrop-blur-sm flex items-center justify-between bg-gradient-to-r ${getHealthColor()} border`}>
        <div className="flex items-center gap-3">
          {data?.health === 'Good' ? (
            <CheckCircle className="w-6 h-6 text-green-400" />
          ) : data?.health === 'Critical' ? (
            <AlertTriangle className="w-6 h-6 text-red-400" />
          ) : (
            <AlertTriangle className="w-6 h-6 text-yellow-400" />
          )}
          <div>
            <span className="text-white font-medium">
              System Status: <span className="font-bold">{data?.health || 'Good'}</span>
            </span>
            <p className={`text-xs ${darkMode ? 'text-slate-400' : 'text-slate-600'}`}>
              Uptime: {data?.uptime || 'Unknown'} • Load: {data?.load_avg || '0 0 0'}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Bell className="w-5 h-5 text-slate-400 cursor-pointer hover:text-white transition-colors" />
          <Settings className="w-5 h-5 text-slate-400 cursor-pointer hover:text-white transition-colors" />
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 mb-6">
        <QuickStat
          icon={<Cpu className="w-5 h-5" />}
          label="CPU"
          value={`${data?.cpu?.current || 0}%`}
          color="blue"
          trend={data?.cpu?.current > 50 ? 'up' : 'down'}
          darkMode={darkMode}
          onClick={() => setSelectedMetric('cpu')}
          selected={selectedMetric === 'cpu'}
        />
        <QuickStat
          icon={<MemoryStick className="w-5 h-5" />}
          label="Memory"
          value={`${data?.memory?.percent || 0}%`}
          color="purple"
          darkMode={darkMode}
          onClick={() => setSelectedMetric('memory')}
          selected={selectedMetric === 'memory'}
        />
        <QuickStat
          icon={<HardDrive className="w-5 h-5" />}
          label="Disk"
          value={`${data?.disk?.percent || 0}%`}
          color="cyan"
          darkMode={darkMode}
          onClick={() => setSelectedMetric('disk')}
          selected={selectedMetric === 'disk'}
        />
        <QuickStat
          icon={<Thermometer className="w-5 h-5" />}
          label="CPU Temp"
          value={data?.cpu?.temperature || 'N/A'}
          color="red"
          darkMode={darkMode}
        />
        <QuickStat
          icon={<Network className="w-5 h-5" />}
          label="Network"
          value={`↓${data?.network?.rx_total?.split(' ')[0] || '0'}`}
          color="green"
          darkMode={darkMode}
          onClick={() => setSelectedMetric('network')}
          selected={selectedMetric === 'network'}
        />
        <QuickStat
          icon={<Server className="w-5 h-5" />}
          label="Processes"
          value={data?.processes?.total || 0}
          color="orange"
          darkMode={darkMode}
        />
      </div>

      {/* Live Chart */}
      <div className={`mb-6 p-6 rounded-2xl ${darkMode ? 'bg-slate-800/50' : 'bg-white shadow-lg'
        } border ${darkMode ? 'border-slate-700' : 'border-slate-200'}`}>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className={`p-2 ${darkMode ? 'bg-blue-500/20' : 'bg-blue-100'} rounded-lg`}>
              <BarChart3 className="w-5 h-5 text-blue-500" />
            </div>
            <h2 className={`text-xl font-semibold ${darkMode ? 'text-white' : 'text-slate-900'}`}>
              Live Performance
            </h2>
            <span className="flex items-center gap-1 text-xs text-green-400 bg-green-500/20 px-2 py-1 rounded-full">
              <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></span>
              Live
            </span>
          </div>
          <button
            onClick={() => setShowHistory(!showHistory)}
            className={`px-3 py-1 text-sm rounded-lg ${darkMode ? 'bg-slate-700 text-slate-300' : 'bg-slate-100 text-slate-700'
              }`}
          >
            {showHistory ? 'Hide' : 'Show'} History
          </button>
        </div>
        {showHistory && (
          <div className="h-48">
            <Line data={liveChartData} options={liveChartOptions(darkMode)} />
          </div>
        )}
        <div className="flex items-center gap-6 mt-4">
          <LegendItem color="rgb(59, 130, 246)" label="CPU" />
          <LegendItem color="rgb(139, 92, 246)" label="Memory" />
        </div>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        {/* CPU Section */}
        <CollapsibleCard
          title="CPU Utilization"
          icon={<Cpu className="w-5 h-5 text-blue-400" />}
          color="blue"
          expanded={expandedSections.cpu}
          onToggle={() => toggleSection('cpu')}
          darkMode={darkMode}
        >
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className={`text-3xl font-bold ${darkMode ? 'text-white' : 'text-slate-900'}`}>
                  {data?.cpu?.current || 0}%
                </p>
                <p className={`text-sm ${darkMode ? 'text-slate-400' : 'text-slate-600'}`}>
                  {data?.cpu?.model || 'Unknown CPU'}
                </p>
              </div>
              <div className="text-right">
                <p className={`text-sm ${darkMode ? 'text-slate-400' : 'text-slate-600'}`}>
                  {data?.cpu?.cores || 0} cores
                </p>
                <p className={`text-sm ${darkMode ? 'text-slate-400' : 'text-slate-600'}`}>
                  Temp: {data?.cpu?.temperature || 'N/A'}
                </p>
              </div>
            </div>
            <ProgressBar value={data?.cpu?.current || 0} color="blue" darkMode={darkMode} />
            <div className="grid grid-cols-3 gap-3">
              <MiniStat label="Avg" value={`${data?.cpu?.avg || 0}%`} darkMode={darkMode} />
              <MiniStat label="Max" value={`${data?.cpu?.max || 0}%`} darkMode={darkMode} />
              <MiniStat label="Min" value={`${data?.cpu?.min || 0}%`} darkMode={darkMode} />
            </div>
          </div>
        </CollapsibleCard>

        {/* Memory Section */}
        <CollapsibleCard
          title="Memory Usage"
          icon={<MemoryStick className="w-5 h-5 text-purple-400" />}
          color="purple"
          expanded={expandedSections.memory}
          onToggle={() => toggleSection('memory')}
          darkMode={darkMode}
        >
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className={`text-3xl font-bold ${darkMode ? 'text-white' : 'text-slate-900'}`}>
                  {data?.memory?.percent || 0}%
                </p>
                <p className={`text-sm ${darkMode ? 'text-slate-400' : 'text-slate-600'}`}>
                  {data?.memory?.used || 0} GB / {data?.memory?.total || 0} GB
                </p>
              </div>
            </div>
            <ProgressBar value={data?.memory?.percent || 0} color="purple" darkMode={darkMode} />
            <div className="grid grid-cols-2 gap-3">
              <MiniStat label="Available" value={`${data?.memory?.available || 0} GB`} darkMode={darkMode} />
              <MiniStat label="Cached" value={`${data?.memory?.cached || 0} GB`} darkMode={darkMode} />
              <MiniStat label="Swap" value={`${data?.memory?.swap_used || 0} MB`} darkMode={darkMode} />
              <MiniStat label="Total" value={`${data?.memory?.total || 0} GB`} darkMode={darkMode} />
            </div>
          </div>
        </CollapsibleCard>
      </div>

      {/* Second Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        {/* Disk */}
        <CollapsibleCard
          title="Disk Storage"
          icon={<HardDrive className="w-5 h-5 text-cyan-400" />}
          color="cyan"
          expanded={expandedSections.disk}
          onToggle={() => toggleSection('disk')}
          darkMode={darkMode}
        >
          <div className="space-y-4">
            {(data?.disk?.filesystems || [{ mount: '/', percent: data?.disk?.percent || 0, used: data?.disk?.used || '0G', total: data?.disk?.total || '0G' }]).slice(0, 3).map((fs, idx) => (
              <div key={idx}>
                <div className="flex justify-between text-sm mb-1">
                  <span className={darkMode ? 'text-slate-400' : 'text-slate-600'}>{fs.mount}</span>
                  <span className={darkMode ? 'text-white' : 'text-slate-900'}>{fs.used} / {fs.total}</span>
                </div>
                <ProgressBar
                  value={fs.percent}
                  color={fs.percent > 90 ? 'red' : fs.percent > 70 ? 'yellow' : 'cyan'}
                  darkMode={darkMode}
                  showPercent
                />
              </div>
            ))}
            <div className="grid grid-cols-2 gap-3 pt-2 border-t border-slate-700">
              <MiniStat label="Read" value={`${data?.disk?.read || 0} MB`} darkMode={darkMode} />
              <MiniStat label="Written" value={`${data?.disk?.written || 0} MB`} darkMode={darkMode} />
            </div>
          </div>
        </CollapsibleCard>

        {/* Network */}
        <CollapsibleCard
          title="Network"
          icon={<Wifi className="w-5 h-5 text-green-400" />}
          color="green"
          expanded={expandedSections.network}
          onToggle={() => toggleSection('network')}
          darkMode={darkMode}
        >
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-gradient-to-r from-green-500/10 to-transparent rounded-lg">
              <div className="flex items-center gap-2">
                <TrendingDown className="w-4 h-4 text-green-400" />
                <span className={darkMode ? 'text-slate-300' : 'text-slate-700'}>Download</span>
              </div>
              <span className={`font-mono font-bold ${darkMode ? 'text-white' : 'text-slate-900'}`}>
                {data?.network?.rx_total || '0 MB'}
              </span>
            </div>
            <div className="flex items-center justify-between p-3 bg-gradient-to-r from-blue-500/10 to-transparent rounded-lg">
              <div className="flex items-center gap-2">
                <TrendingUp className="w-4 h-4 text-blue-400" />
                <span className={darkMode ? 'text-slate-300' : 'text-slate-700'}>Upload</span>
              </div>
              <span className={`font-mono font-bold ${darkMode ? 'text-white' : 'text-slate-900'}`}>
                {data?.network?.tx_total || '0 MB'}
              </span>
            </div>
            <div className="space-y-2 pt-2 border-t border-slate-700">
              {(data?.network?.interfaces || []).map((iface, idx) => (
                <div key={idx} className="flex justify-between text-sm">
                  <span className={darkMode ? 'text-slate-400' : 'text-slate-600'}>{iface.name}</span>
                  <span className={`flex items-center gap-1 ${iface.status === 'up' ? 'text-green-400' : 'text-slate-500'
                    }`}>
                    <span className={`w-2 h-2 rounded-full ${iface.status === 'up' ? 'bg-green-500' : 'bg-slate-500'
                      }`}></span>
                    {iface.status}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </CollapsibleCard>

        {/* GPU */}
        <CollapsibleCard
          title="GPU"
          icon={<Zap className="w-5 h-5 text-orange-400" />}
          color="orange"
          expanded={expandedSections.gpu}
          onToggle={() => toggleSection('gpu')}
          darkMode={darkMode}
        >
          {data?.gpu?.available ? (
            <div className="space-y-4">
              <p className={`text-sm ${darkMode ? 'text-slate-300' : 'text-slate-700'} truncate`}>
                {data?.gpu?.name}
              </p>
              <div>
                <div className="flex justify-between text-sm mb-1">
                  <span className={darkMode ? 'text-slate-400' : 'text-slate-600'}>Utilization</span>
                  <span className={darkMode ? 'text-white' : 'text-slate-900'}>{data?.gpu?.utilization || 0}%</span>
                </div>
                <ProgressBar value={data?.gpu?.utilization || 0} color="orange" darkMode={darkMode} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <MiniStat label="Temp" value={`${data?.gpu?.temperature || 'N/A'}°C`} darkMode={darkMode} />
                <MiniStat label="Memory" value={`${data?.gpu?.memory_used || 0} MB`} darkMode={darkMode} />
                <MiniStat label="Fan" value={`${data?.gpu?.fan || 'N/A'}%`} darkMode={darkMode} />
                <MiniStat label="Power" value={`${data?.gpu?.power || 'N/A'} W`} darkMode={darkMode} />
              </div>
            </div>
          ) : (
            <div className={`flex flex-col items-center justify-center h-32 ${darkMode ? 'text-slate-500' : 'text-slate-400'
              }`}>
              <Monitor className="w-12 h-12 mb-2 opacity-50" />
              <p>No GPU detected</p>
            </div>
          )}
        </CollapsibleCard>
      </div>

      {/* System Info */}
      <CollapsibleCard
        title="System Information"
        icon={<Server className="w-5 h-5 text-slate-400" />}
        color="slate"
        expanded={expandedSections.system}
        onToggle={() => toggleSection('system')}
        darkMode={darkMode}
      >
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          <InfoCard label="Hostname" value={data?.hostname || 'N/A'} darkMode={darkMode} />
          <InfoCard label="Kernel" value={data?.kernel?.split('-')[0] || 'N/A'} darkMode={darkMode} />
          <InfoCard label="Uptime" value={data?.uptime || 'N/A'} darkMode={darkMode} />
          <InfoCard label="Load Avg" value={data?.load_avg?.split(' ')[0] || 'N/A'} darkMode={darkMode} />
          <InfoCard label="Processes" value={`${data?.processes?.total || 0} (${data?.processes?.running || 0} running)`} darkMode={darkMode} />
          <InfoCard label="CPU Cores" value={data?.cpu?.cores || 'N/A'} darkMode={darkMode} />
        </div>
      </CollapsibleCard>

      {/* Footer */}
      <footer className={`mt-8 text-center ${darkMode ? 'text-slate-500' : 'text-slate-400'} text-sm`}>
        <p>System Monitor Dashboard • {autoRefresh ? `Auto-refreshes every ${refreshInterval}s` : 'Paused'}</p>
        <p className="mt-1">Press <kbd className={`px-2 py-1 rounded ${darkMode ? 'bg-slate-700' : 'bg-slate-200'}`}>j</kbd> in terminal to generate new data</p>
      </footer>
    </div>
  )
}

// Components
function QuickStat({ icon, label, value, color, trend, darkMode, onClick, selected }) {
  const colorClasses = {
    blue: 'from-blue-500/20 to-blue-600/20 border-blue-500/30 hover:border-blue-500',
    purple: 'from-purple-500/20 to-purple-600/20 border-purple-500/30 hover:border-purple-500',
    cyan: 'from-cyan-500/20 to-cyan-600/20 border-cyan-500/30 hover:border-cyan-500',
    red: 'from-red-500/20 to-red-600/20 border-red-500/30 hover:border-red-500',
    green: 'from-green-500/20 to-green-600/20 border-green-500/30 hover:border-green-500',
    orange: 'from-orange-500/20 to-orange-600/20 border-orange-500/30 hover:border-orange-500',
  }

  return (
    <div
      onClick={onClick}
      className={`p-4 rounded-xl bg-gradient-to-br ${colorClasses[color]} border backdrop-blur-sm cursor-pointer transition-all hover:scale-105 ${selected ? 'ring-2 ring-offset-2 ring-offset-slate-900 ring-blue-500' : ''
        }`}
    >
      <div className={`flex items-center gap-2 ${darkMode ? 'text-slate-400' : 'text-slate-600'} mb-2`}>
        {icon}
        <span className="text-xs font-medium">{label}</span>
        {trend && (
          trend === 'up'
            ? <TrendingUp className="w-3 h-3 text-red-400 ml-auto" />
            : <TrendingDown className="w-3 h-3 text-green-400 ml-auto" />
        )}
      </div>
      <p className={`text-xl font-bold ${darkMode ? 'text-white' : 'text-slate-900'}`}>{value}</p>
    </div>
  )
}

function CollapsibleCard({ title, icon, color, expanded, onToggle, children, darkMode }) {
  const colorClasses = {
    blue: 'bg-blue-500/20',
    purple: 'bg-purple-500/20',
    cyan: 'bg-cyan-500/20',
    green: 'bg-green-500/20',
    orange: 'bg-orange-500/20',
    slate: 'bg-slate-500/20',
    red: 'bg-red-500/20',
  }

  return (
    <div className={`rounded-2xl ${darkMode ? 'bg-slate-800/50' : 'bg-white shadow-lg'
      } border ${darkMode ? 'border-slate-700' : 'border-slate-200'} overflow-hidden transition-all`}>
      <div
        className="flex items-center justify-between p-4 cursor-pointer hover:bg-slate-700/30 transition-colors"
        onClick={onToggle}
      >
        <div className="flex items-center gap-3">
          <div className={`p-2 ${colorClasses[color]} rounded-lg`}>
            {icon}
          </div>
          <h2 className={`text-lg font-semibold ${darkMode ? 'text-white' : 'text-slate-900'}`}>
            {title}
          </h2>
        </div>
        {expanded ? <ChevronUp className="w-5 h-5 text-slate-400" /> : <ChevronDown className="w-5 h-5 text-slate-400" />}
      </div>
      {expanded && (
        <div className="p-4 pt-0">
          {children}
        </div>
      )}
    </div>
  )
}

function ProgressBar({ value, color, darkMode, showPercent }) {
  const colorClasses = {
    blue: 'bg-blue-500',
    purple: 'bg-purple-500',
    cyan: 'bg-cyan-500',
    green: 'bg-green-500',
    orange: 'bg-orange-500',
    red: 'bg-red-500',
    yellow: 'bg-yellow-500',
  }

  return (
    <div className="relative">
      <div className={`h-2 ${darkMode ? 'bg-slate-700' : 'bg-slate-200'} rounded-full overflow-hidden`}>
        <div
          className={`h-full ${colorClasses[color]} rounded-full transition-all duration-500`}
          style={{ width: `${Math.min(value, 100)}%` }}
        />
      </div>
      {showPercent && (
        <span className={`absolute right-0 -top-5 text-xs ${darkMode ? 'text-slate-400' : 'text-slate-600'}`}>
          {value}%
        </span>
      )}
    </div>
  )
}

function MiniStat({ label, value, darkMode }) {
  return (
    <div className={`p-2 ${darkMode ? 'bg-slate-700/50' : 'bg-slate-100'} rounded-lg text-center`}>
      <p className={`text-xs ${darkMode ? 'text-slate-400' : 'text-slate-600'} uppercase`}>{label}</p>
      <p className={`font-bold text-sm ${darkMode ? 'text-white' : 'text-slate-900'}`}>{value}</p>
    </div>
  )
}

function InfoCard({ label, value, darkMode }) {
  return (
    <div className={`p-3 ${darkMode ? 'bg-slate-700/30' : 'bg-slate-50'} rounded-lg`}>
      <p className={`text-xs ${darkMode ? 'text-slate-500' : 'text-slate-400'} uppercase mb-1`}>{label}</p>
      <p className={`text-sm font-medium truncate ${darkMode ? 'text-white' : 'text-slate-900'}`} title={value}>
        {value}
      </p>
    </div>
  )
}

function LegendItem({ color, label }) {
  return (
    <div className="flex items-center gap-2">
      <span className="w-3 h-3 rounded-full" style={{ backgroundColor: color }}></span>
      <span className="text-sm text-slate-400">{label}</span>
    </div>
  )
}

// Chart options
const liveChartOptions = (darkMode) => ({
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
  },
  scales: {
    y: {
      beginAtZero: true,
      max: 100,
      grid: { color: darkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)' },
      ticks: { color: darkMode ? 'rgba(255,255,255,0.5)' : 'rgba(0,0,0,0.5)' },
    },
    x: {
      display: false,
    },
  },
  animation: {
    duration: 300,
  },
})

// Demo data
function getDemoData() {
  return {
    timestamp: new Date().toISOString(),
    hostname: 'localhost',
    kernel: '5.15.0-generic',
    uptime: '2 days, 3 hours',
    load_avg: '0.52 0.48 0.45',
    health: 'Good',
    cpu: {
      current: Math.floor(Math.random() * 30) + 10,
      avg: 25,
      max: 85,
      min: 5,
      model: 'Intel Core i7',
      temperature: '45°C',
      cores: 8,
      history: Array(20).fill(0).map(() => Math.floor(Math.random() * 40) + 10),
      timestamps: Array(20).fill(0).map((_, i) => `${i}:00`),
    },
    memory: {
      total: 16,
      used: 8.5,
      available: 7.5,
      cached: 3.2,
      percent: 53,
      swap_used: 128,
    },
    disk: {
      total: '256G',
      used: '128G',
      percent: 50,
      read: 1024,
      written: 512,
      filesystems: [
        { mount: '/', percent: 50, used: '128G', total: '256G' },
        { mount: '/home', percent: 35, used: '175G', total: '500G' },
      ],
    },
    network: {
      rx_total: '1.5 GB',
      tx_total: '256 MB',
      rx_rate: '1.2',
      interfaces: [
        { name: 'eth0', status: 'up' },
        { name: 'wlan0', status: 'down' },
      ],
    },
    gpu: {
      available: false,
    },
    processes: {
      total: 245,
      running: 3,
    },
  }
}

export default App
