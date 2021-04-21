local config = mwse.loadConfig("main menu quick keys")
local base = {
      mainMenuQuickKeysEnabled = true,
      continueKeyInfo = {
            index = 1,
            keyCode = tes3.scanCode.c,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "Continue",
	    container = "Pete_ContinueButton",
	    },
      returnKeyInfo = {
            index = 2,
            keyCode = tes3.scanCode.r,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "Return",
	    container = "MenuOptions_Return_container",
	    },
      newKeyInfo = {
            index = 4,
            keyCode = tes3.scanCode.n,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "New",
	    container = "MenuOptions_New_container",
	    },
      saveKeyInfo = {
            index = 5,
            keyCode = tes3.scanCode.s,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "Save",
	    container = "MenuOptions_Save_container",
	    },
      loadKeyInfo = {
            index = 6,
            keyCode = tes3.scanCode.l,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "Load",
	    container = "MenuOptions_Load_container",
	    },
      optionsKeyInfo = {
            index = 7,
            keyCode = tes3.scanCode.o,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "Options",
	    container = "MenuOptions_Options_container",
	    },
      mcmKeyInfo = {
            index = 8,
            keyCode = tes3.scanCode.m,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "MCM",
	    container = "MenuOptions_MCM_container",
	    },
      exitKeyInfo = {
            index = 9,
            keyCode = tes3.scanCode.e,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "Exit",
	    container = "MenuOptions_Exit_container",
	    },
      exit2KeyInfo = {
            index = 10,
            keyCode = tes3.scanCode.x,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    text = "Exit",
	    container = "MenuOptions_Exit_container",
	    },
}

if config == nil then
--mwse.log("config.lua: tooltip notes.json file not found, returning base")
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