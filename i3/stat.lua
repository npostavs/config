local ox = require('posix')
--------------------------------------
---- stat gathering functions
--------------------------------------
local cpus = {}

local function cpu_stats(cpu_line)
   local id, stats = string.match(cpu_line, '^cpu(%d*)%s+(.+)$')
   local idle
   local total = 0
   local col = 1

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
local batt_pct = open_special(BATTERY .. 'capacity')

while true do

   stat:seek('set')
   cpu_stats(stat:read())       -- all cpus
   cpu_stats(stat:read())       -- cpu0
   cpu_stats(stat:read())       -- cpu1

   meminfo:seek('set')
   local mstats = memstats(meminfo)

   batt_pct:seek('set')
   local batt = tonumber(batt_pct:read()) / 100

   -- io.write(string.format('%d%%batt, ', batt *100))
   -- io.write(string.format('%d%%mem, %d%%swap, ',
   --                        mstats.usage *100, mstats.swap_usage *100))
   -- for id, cpu in pairs(cpus) do
   --    io.write(string.format('%d%%cpu%s ', cpu.usage *100, id))
   -- end

   io.write(dzen_graph('blue', mstats.usage))
   io.write(dzen_graph('purple', mstats.swap_usage))
   io.write(dzen_graph('green', cpus['0'].usage))
   io.write(dzen_graph('green', cpus['1'].usage))
   io.write(dzen_graph('orange', batt))
   io.write(os.date('%a %b %d, %r'))
   io.write('\n')
   io.flush()

   ox.sleep(1)
end
