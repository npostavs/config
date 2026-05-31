-- Usage: lua adjust_brightness.lua [incr]

local MIN_BRIGHT = 0.2
local MAX_BRIGHT = 2

local step = tonumber(arg[1]) or 0.1

-- Read xrandr output once
local xrhandle = io.popen("xrandr --verbose")
local xrandr_output = xrhandle:read("*a")
xrhandle:close()

local function fail(errmsg)
   print(errmsg)
   os.exit(1)
end

-- Function to find the first connected display
local function get_active_display(output)
   return output:match("([%w-]+) connected")
end

-- Function to get brightness of a display using string.find
local function get_brightness(output)
    -- Find where the display section starts
    local start_pos, end_pos, display = output:find("\n([%w-]+) connected")
    if not start_pos then
       fail("Couldn't find connected display!")
    end

    -- Find where the next display section starts (or end of string)
    local next_conn_start, _ = output:find("\n[%w-]+ connected", end_pos + 1)
    local next_dcon_start, _ = output:find("\n[%w-]+ disconnected", end_pos + 1)
    local next_start = math.min(next_conn_start or string.len(output),
                                next_dcon_start or string.len(output))
    local section = output:sub(start_pos, next_start - 1)

    -- Look for Brightness: inside this section
    local brightness = section:match("Brightness:%s*(%d*%.?%d+)")
    if not brightness then
       fail("Failed to read brightness for display: " .. display)
    end
    return display, tonumber(brightness)
end

-- Function to set brightness
local function set_brightness(display, value)
   value = math.min(math.max(value, MIN_BRIGHT), MAX_BRIGHT)
   os.execute("xrandr --output " .. display .. " --brightness " .. value)
end

-- Main
local display, brightness = get_brightness(xrandr_output)
set_brightness(display, brightness + step)
