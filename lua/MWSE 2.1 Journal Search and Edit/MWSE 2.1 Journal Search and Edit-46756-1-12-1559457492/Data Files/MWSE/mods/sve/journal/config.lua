local config = mwse.loadConfig("journal search and edit")
local base = {
      enabled = true,
      pageTurnDelay = 250, -- milliseconds
      searchIndicatorDuration = 250, -- milliseconds
      uiLatency = 50, -- milliseconds
      hideRedundantDateHeaders = true,
      topicSpaceCompression = 60,
      cursorUpDownJumpChar = 15, -- *10 text entry width
      newTextLine = ">",
      messageNoBookArt = "You have found no images to add to your journal.",
      messageNewBookArt = "You found a new image to add to your journal.",
      messageNewBookArts = "You found new images to add to your journal.",
      maxImageWidth = 338,
      closeKeyInfo = {
            keyCode = tes3.scanCode.tab,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    },
      exitKeyInfo = {
            keyCode = tes3.scanCode.backSlash,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    },
      contMatchKeyInfo = {
            keyCode = tes3.scanCode.enter,
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    },
      nextPageKeyInfo = {
            keyCode = tes3.scanCode["keyRight"],
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    },
      prevPageKeyInfo = {
            keyCode = tes3.scanCode["keyLeft"],
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    },
      nextImageKeyInfo = {
            keyCode = tes3.scanCode["keyRight"],
            isAltDown = true,
            isShiftDown = false,
            isControlDown = false,
	    },
      prevImageKeyInfo = {
            keyCode = tes3.scanCode["keyLeft"],
            isAltDown = true,
            isShiftDown = false,
            isControlDown = false,
	    },
      incrImageScaleStep = 5, -- %
      incrImageFineScaleStep = 5, -- 0.1%
      incrImageScaleKeyInfo = {
            keyCode = tes3.scanCode["+"],
            isAltDown = true,
            isShiftDown = false,
            isControlDown = false,
	    },
      decrImageScaleKeyInfo = {
            keyCode = tes3.scanCode["-"],
            isAltDown = true,
            isShiftDown = false,
            isControlDown = false,
	    },
      incrImageFineScaleKeyInfo = {
            keyCode = tes3.scanCode["]"],
            isAltDown = true,
            isShiftDown = false,
            isControlDown = false,
	    },
      decrImageFineScaleKeyInfo = {
            keyCode = tes3.scanCode["["],
            isAltDown = true,
            isShiftDown = false,
            isControlDown = false,
	    },
      stepImageScaleKeyInfo = 0.05,
      nextMatchKeyInfo = {
            keyCode = tes3.scanCode["]"],
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    },
      prevMatchKeyInfo = {
            keyCode = tes3.scanCode["["],
            isAltDown = false,
            isShiftDown = false,
            isControlDown = false,
	    },
      selectEditDownKeyInfo = {
            keyCode = tes3.scanCode["keyDown"],
            isAltDown = false,
            isShiftDown = true,
            isControlDown = false,
	    },
      selectEditUpKeyInfo = {
            keyCode = tes3.scanCode["keyUp"],
            isAltDown = false,
            isShiftDown = true,
            isControlDown = false,
	    },
      newPageInsertKeyInfo = {
            keyCode = tes3.scanCode["keyRight"],
            isAltDown = false,
            isShiftDown = true,
            isControlDown = false,
	    },
      deleteWordKeyInfo = {
            keyCode = tes3.scanCode.backspace,
            isAltDown = false,
            isShiftDown = true,
            isControlDown = false,
	    },
      deleteEntryKeyInfo = {
            keyCode = tes3.scanCode.delete,
            isAltDown = false,
            isShiftDown = true,
            isControlDown = false,
	    },
      saveEditKeyInfo = {
            keyCode = tes3.scanCode.enter,
            isAltDown = false,
            isShiftDown = true,
            isControlDown = false,
	    },
}

--[[
if config == nil then
----mwse.log("config.lua: journal search and edit.json file not found, returning base")
   config = {}
   for key, value in pairs(base) do
      if type(value) == "table" then
         for key2,value2 in pairs(value) do
            config[key][key2]=value2
         end
      else
         config[key] = value
      end
    end
end
]]--

-- this is to avoid missing entries during development
if config == nil then config = {} end
for key,value in pairs(base) do
   if config[key] == nil then
----mwse.log("config.lua: config[" .. tostring(key) .. "] MISSING, assign as base")
      if type(value) == "table" then
         config[key] = {}
         for key2,value2 in pairs(value) do
	    config[key][key2] = value2
	 end
      else
         config[key] = value
      end
   end
end

return { config, base }

