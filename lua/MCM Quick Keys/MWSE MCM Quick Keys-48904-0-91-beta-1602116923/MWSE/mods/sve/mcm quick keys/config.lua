local config = mwse.loadConfig("mcm quick keys")
local base = {
      MCMquickKeysEnabled = true,
      selectModRequiresShiftKey = false,
      selectModRequiresAltKey = false,
      selectModRequiresCtrlKey = true,
      openSelectedModMCMkeyInfo = {
            keyCode = tes3.scanCode.enter,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = true,
	    },
      selectNextModKeyInfo = {
            keyCode = tes3.scanCode.keyDown,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = true,
	    },
      selectPrevModKeyInfo = {
            keyCode = tes3.scanCode.keyUp,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = true,
	    },
      enableMouseScrollWheelAsArrowKeys =  true,
      autoOpenAsSelected = true,
      autoOpenLastPage = true,
}

if config == nil then
   return base
end

-- this is to avoid missing entries during development
for key,_ in pairs(base) do
   if config[key] == nil then
      config[key] = base[key]
--mwse.log("config.lua: config[" .. tostring(key) .. "] MISSING, assign as base")
   end
end
return config