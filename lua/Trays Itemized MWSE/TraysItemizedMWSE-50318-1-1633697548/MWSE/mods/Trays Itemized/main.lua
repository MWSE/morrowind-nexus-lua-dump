local config = require("Trays Itemized.config")
local trayStatic = "furn_de_tray_01"
local trayMisc = "misc_de_tray"
local trayOwner = "a shady smuggler"
local pluginLoaded

local function onCellChange()
  if config.uninstall == false then
    if pluginLoaded then
      for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.static) do
        if not ref.disabled then
          if ref.object.id == trayStatic then
            mwscript.disable {reference = ref}
            local refCreated = tes3.createReference{
              object = trayMisc,
              cell = ref.cell,
              position = ref.position,
              orientation = ref.orientation,
              scale = ref.scale
            }
            tes3.setOwner({ reference = refCreated, owner = trayOwner })
          end
        end
      end
    end
  elseif config.uninstall == true then
    for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.static) do
      if ref.disabled then
        if ref.object.id == trayStatic then
          mwscript.enable {reference = ref}
        end
      end
    end
  end
end

local function onLoaded()
  event.register("cellChanged", onCellChange)
end

local function initialized()
  event.register("loaded", onLoaded)
  if tes3.isModActive("Trays Itemized-no cells.esp") then
    pluginLoaded = true
    config.uninstall = false
  else
    pluginLoaded = false
    config.uninstall = true
    tes3.messageBox("Trays Itemized plugin not active.\n Initiating uninstall mode")
    mwse.log ("Trays Itemized-no cells.esp not found")
  end
end

event.register("initialized", initialized)

local function registerModConfig()
  require("Trays Itemized.mcm")
end
event.register("modConfigReady", registerModConfig)