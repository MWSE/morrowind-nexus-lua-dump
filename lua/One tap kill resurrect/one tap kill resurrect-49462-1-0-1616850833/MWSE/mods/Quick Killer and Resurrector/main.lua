local skip = 0
local off = false
local str = ""


local function activatekiller()
if tes3.worldController.inputController:isKeyPressedThisFrame(tes3.scanCode.numpad0) == true then
if off == true then off = false str = "ON" else off = true str = "OFF" end
tes3.messageBox("Killing/Resurrect key is %s", str)
end
end
event.register("keyDown", activatekiller)







local function kill()
if off == true then return end
local ray = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector() })
local e = ray and ray.reference
if e == nil or (e.object.objectType ~= tes3.objectType.npc and e.object.objectType ~= tes3.objectType.creature) then return end
if tes3.worldController.inputController:isKeyPressedThisFrame(tes3.scanCode.z) == true then
if e.mobile.health.current ~= 0 then
e.mobile.health.current = 0
else
tes3.runLegacyScript{command = "resurrect", reference = e}
end
end
end
event.register("simulate", kill)


local function killconstant(t)
if off == true then return end
local ray = tes3.rayTest({ position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector() })
local e = ray and ray.reference
if e == nil or (e.object.objectType ~= tes3.objectType.npc and e.object.objectType ~= tes3.objectType.creature) then return end
if tes3.worldController.inputController:isKeyDown(tes3.scanCode.x) == true then
if skip > 0.15 then
skip = 0
else
skip = skip + t.delta
return
end
if e.mobile.health.current ~= 0 then
e.mobile.health.current = 0
else
tes3.runLegacyScript{command = "resurrect", reference = e}
end
end
end
event.register("simulate", killconstant)









local modConfig = {}
function modConfig.onCreate(container)
    local pane = container:createThinBorder {}
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"
    local header = pane:createLabel {}
    header.color = tes3ui.getPalette("header_color")
    header.borderBottom = 25
    header.text = "Quick Killer and Resurrector"
    local txtBlock = pane:createBlock()
    txtBlock.widthProportional = 1.0
    txtBlock.autoHeight = true
    txtBlock.borderBottom = 25
    local txt = txtBlock:createLabel {}
    txt.wrapText = true
    txt.text = "NUMPAD 0 to toggle ON or OFF\nTap Z key or Hold X key\nIf the target is dead it will be resurrected and vice versa\nUse at your own risk!"
end
local function registerModConfig()
    mwse.registerModConfig("Quick Killer and Resurrector", modConfig)
end
event.register("modConfigReady", registerModConfig)
