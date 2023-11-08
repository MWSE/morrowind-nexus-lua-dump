local icon = include("SSQN.interop")

local function init()
    -- Custom Icons for Skyrim Style Quest Notifications
    if (icon) then
      icon.registerQIcon("mdTemp","\\Icons\\SSQN\\TT.dds")
    end
end

event.register(tes3.event.initialized, init)
