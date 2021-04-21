sl = "light_com_lantern_02_INF"
cl = "torch_infinite_time"	
local function lighter()
for npc in tes3.iterateObjects(tes3.objectType.npc) do
if npc.class.id == "Shipmaster" or npc.class.id == "Gondolier"  then
npcid = npc.id
ref = tes3.getReference(npcid)
if ref and ref.mobile then
if mwscript.getItemCount{reference = ref, item = sl} == 0 and ref.mobile.health.current > 0 then
tes3.addItem{ reference = ref, item = sl }
end
end	
elseif npc.class.id == "Caravaner" then
npcid = npc.id
ref = tes3.getReference(npcid)
if ref and ref.mobile then
if mwscript.getItemCount{reference = ref, item = cl} == 0 and ref.mobile.health.current > 0 then
tes3.addItem{ reference = ref, item = cl }
end
end
end	
end
end
event.register("cellChanged", lighter) --what's a good event here? timer?










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
    header.text = "Transporter Lights\nversion 1.0"
    local txtBlock = pane:createBlock()
    txtBlock.widthProportional = 1.0
    txtBlock.autoHeight = true
    txtBlock.borderBottom = 25
    local txt = txtBlock:createLabel {}
    txt.wrapText = true
    txt.text = "Caravaners, Gondoliers, and Shipmasters will equip light at night"
end
local function registerModConfig()
    mwse.registerModConfig("Transporter Lights", modConfig)
end
event.register("modConfigReady", registerModConfig)