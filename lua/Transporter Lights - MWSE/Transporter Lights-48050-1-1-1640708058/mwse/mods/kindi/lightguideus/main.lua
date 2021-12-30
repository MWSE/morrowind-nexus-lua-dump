local torches = {
    sl = "light_com_lantern_02_INF",
    cl = "torch_infinite_time"
}

local noLights = false

--old mod folder remover
if lfs.dir("Data Files\\MWSE\\mods\\kne\\lightguideus") then
	lfs.rmdir("Data Files\\MWSE\\mods\\kne\\lightguideus", true)
	mwse.log("[Transporter Lights]: Old mod folder found and deleted.")
end


local function giveLights(e)
    local thisCell = e.cell

    if not thisCell then
        return
    end

    local function addLight(ref)
        if ref.object.objectType ~= tes3.objectType.npc then
            return
        end
        if ref.isDead then
            return
        end

        if ref.object.class.id == "Shipmaster" or ref.object.class.id == "Gondolier" then
            if tes3.getItemCount {reference = ref, item = torches.sl} <= 0 then
                tes3.addItem {reference = ref, item = torches.sl, updateGUI = false, playSound = false, limit = false}
            end
            if noLights then
                tes3.removeItem {reference = ref, item = torches.sl, updateGUI = false, playSound = false}
            end
        elseif ref.object.class.id == "Caravaner" then
            if mwscript.getItemCount {reference = ref, item = torches.cl} <= 0 then
                tes3.addItem {reference = ref, item = torches.cl, updateGUI = false, playSound = false, limit = false}
            end
            if noLights then
                tes3.removeItem {reference = ref, item = torches.cl, updateGUI = false, playSound = false}
            end
        end
        if tes3.worldController.hour.value >= 20 or tes3.worldController.hour.value <= 6 then
            for _, torch in pairs(torches) do
                if ref.mobile and ref.object.inventory:contains(torch) then
                    ref.mobile:equip {item = torch, addItem = false}
                end
            end
        end
    end

    for _, ref in pairs(thisCell.actors) do
        addLight(ref)
    end
end
event.register("cellChanged", giveLights)

local modConfig = {}
function modConfig.onCreate(container)
    local pane = container:createThinBorder {}
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom" --left_to_right
    local header = pane:createLabel {}
    header.color = tes3ui.getPalette("header_color")
    header.borderBottom = 25
    header.text = "Transporter Lights\nversion 1.1"
    local txtBlock = pane:createBlock()
    txtBlock.widthProportional = 1.0
    txtBlock.autoHeight = true
    txtBlock.borderBottom = 25
    local txt = txtBlock:createLabel {}
    txt.wrapText = true
    txt.text = "Caravaners, Gondoliers, and Shipmasters will equip light at night"

    local optionsBlock = pane:createBlock {}
    optionsBlock.widthProportional = 1.0
    optionsBlock.autoHeight = true
    optionsBlock.flowDirection = "left_to_right"

    local removeLightsLabel = optionsBlock:createLabel {}
    removeLightsLabel.wrapText = true
    removeLightsLabel.text = "Transporters have lights?"

    local removeLights = optionsBlock:createButton {}
    removeLights.borderLeft = 35
    removeLights.text = noLights and "No Lights" or "Lights"
    removeLights.widget.state = 1
    removeLights:register(
        "mouseClick",
        function(e)
            noLights = not noLights
            removeLights.text = noLights and "No Lights" or "Lights"
            if noLights then
                tes3.messageBox("Transporters will not have lights")
            else
                tes3.messageBox("Transporters have lights")
            end
            if tes3.player then
                giveLights(tes3.player)
            end
        end
    )
end
local function registerModConfig()
    mwse.registerModConfig("Transporter Lights", modConfig)
    mwse.log("Transporter Lights mod config registered")
end
event.register("modConfigReady", registerModConfig)
