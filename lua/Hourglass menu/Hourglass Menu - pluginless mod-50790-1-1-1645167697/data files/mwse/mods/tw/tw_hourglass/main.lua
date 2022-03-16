--[[
Addon menu for my Hour Glass asset wherever it is used, in any mod by any modder as long as they are using the original id.
It adds a menu with the option to open the wait menu.
Nothing earth shattering but maybe a bit more immersive.
--]]

local messageBox = require("tw.MessageBox") 

mwse.log("[Hourglass Menu] Loaded successfully.")

local hourglasses = {
    ["tw_hourglass"] = true,
    ["wl_hourglass"] = true,
    ["ab_misc_hourglass"] = true,
}

local lOpen

local function Openwait()
  
  tes3.showRestMenu()

end

local function onActHourGlass(e)

if hourglasses[e.target.id:lower()] then

    if ( lOpen ) then
        lOpen = false  --  reset for next time.

    else
         messageBox{
                message = "What do you want to do?",
                buttons = {{ text = "Pick-up", callback = function() timer.delayOneFrame(function() AllowActivate = true; lOpen = true; tes3.player:activate(e.target) end) end },
                           { text = "Wait",    callback = function() Openwait() end }, 
                           { text = "Cancel",  callback = function() return false end }}             
                      }
                      
        return false
    end

  end
                  
end
event.register("activate", onActHourGlass )
 
 ----------------------------------------------------------------------------------------------------
local function onEquipHourglass(e)
  
    if hourglasses[e.item.id:lower()] then
      
        Openwait()
        
    end    
end
event.register("equip", onEquipHourglass)
