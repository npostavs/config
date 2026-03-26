local ox = require('posix')
--------------------------------------
---- stat gathering functions
--------------------------------------
local cpus = {}
local cpu_count = 0

local function cpu_stats(cpu_line)
   local id, stats = string.match(cpu_line, '^cpu(%d*)%s+(.+)$')
   local idle
   local total = 0
   local col = 1

   if id == nil then
      return false
   elseif id == '' then
      id = 0
   else
      id = tonumber(id)
      if id > cpu_count then
         cpu_count = id
      end
   end

   for s in string.gmatch(stats, '(%d+)%s+') do
      local n = tonumber(s)
      total = total + n
      if col == 4 then idle = n end
      col = col + 1
   end

   if cpus[id] then
      local dtotal = total - cpus[id].total
      local didle = idle - cpus[id].idle
      cpus[id].usage = 1 - (didle / dtotal)
   else
      cpus[id] = { usage = 0 }
   end

   cpus[id].total = total
   cpus[id].idle = idle

   return true
end

local function memstats(meminfo)
   local stats = {}
   for line in meminfo:lines() do
      local field, value = string.match(line, '^([^%s:]+):%s*(%d+)')
      if field and value then
         stats[field] = tonumber(value)
      else
         io.stderr:write(line, '\n')
      end
   end
   local free = stats.MemFree + stats.Buffers + stats.Cached
   local usage = 1 - free / stats.MemTotal
   local swap_usage
   if stats.SwapTotal > 0 then
      swap_usage = 1 - stats.SwapFree / stats.SwapTotal
   else
      swap_usage = 0
   end
   return { usage = usage, swap_usage = swap_usage }
end

local BATTERY
local POWER_SUPPLY = '/sys/class/power_supply/'
for batt in ox.files(POWER_SUPPLY)
do
   if string.find(batt, '^BAT') then
      BATTERY = POWER_SUPPLY .. batt .. '/'
      break
   end
end

--------------------------------------
---- meter drawing functions
--------------------------------------

local W = 6
local H = 18
local function dzen_graph(colour, percent)
   local h = math.floor(H*percent + 0.5)
   if percent > 0 and h < H then h = h + 1 end
   return string.format(
      '^ib(1)^fg(white)^r(%dx%d)^p(-%d)^fg(%s)^r(%dx%d)^fg()^ib(0)',
      W,H,W,
      colour, W, h
      --, math.ceil(H/2 + h/2)
   )
end

--------------------------------------
---- main loop
--------------------------------------

-- we keep these files open, so we don't have to keep reopening them
-- every second
local function open_special(filename)
   local file = io.open(filename)
   if file then
      file:setvbuf('no')
   end
   return file
end

local stat = open_special('/proc/stat')
local meminfo = open_special('/proc/meminfo')
if BATTERY then
   local batt_pct = open_special(BATTERY .. 'capacity')
end

while true do

   stat:seek('set')
   while cpu_stats(stat:read())
   do ;
   end

   meminfo:seek('set')
   local mstats = memstats(meminfo)

   if batt_pct then
      batt_pct:seek('set')
      local batt = tonumber(batt_pct:read()) / 100
   end

   io.write(dzen_graph('blue', mstats.usage))
   io.write(dzen_graph('purple', mstats.swap_usage))
   for i = 1, cpu_count do
      io.write(dzen_graph('green', cpus[i].usage))
   end
   if batt then
      io.write(dzen_graph('orange', batt))
   end
   io.write(os.date('%a %b %d, %r'))
   io.write('\n')
   io.flush()

   ox.sleep(1)
end
