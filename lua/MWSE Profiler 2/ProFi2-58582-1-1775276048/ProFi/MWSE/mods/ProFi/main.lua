local profiler = require("ProFi.Profi")
local active = false

local function showMessge()
    tes3ui.showNotifyMenu("ProFi is installed. Press Z to profile (by duration), or Shift+Z to profile with garbage tracking (by GC allocation). Press again to stop and export.")
end
event.register(tes3.event.initialized, showMessge)

local function startProfiling(trackGarbage)
    if active then return end
    profiler:setTrackGarbage(trackGarbage)
    profiler:start()
    active = true
end

local function stopProfiling()
    if not active then return end
    profiler:stop()
    local date = os.date("*t") ---@cast date osdate
    local name = string.format("Profile Report %s %s %s %s %s.txt", date.year, date.month, date.day, date.hour, date.min)
    profiler:writeReport(name)
    active = false
end

local function onZ(e)
    if e.isShiftDown then return end
    if active then stopProfiling() else startProfiling(false) end
end

local function onShiftZ(e)
    if not e.isShiftDown then return end
    if active then stopProfiling() else startProfiling(true) end
end

event.register("keyDown", onZ, { filter = tes3.scanCode.z })
event.register("keyDown", onShiftZ, { filter = tes3.scanCode.z })