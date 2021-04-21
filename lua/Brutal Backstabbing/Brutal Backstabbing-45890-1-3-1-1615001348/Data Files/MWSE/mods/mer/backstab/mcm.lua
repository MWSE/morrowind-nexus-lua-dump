local config = require("mer.backstab.config")
local this = {}

this.weaponList = {
    ["Short Blades"] = { [tes3.weaponType.shortBladeOneHand] = true },
    ["Long Blades (One Handed)"] = {[tes3.weaponType.longBladeOneHand] = true},
    ["Long Blades (Two Handed)"] = {[tes3.weaponType.longBladeTwoClose] = true},
    ["Blunt Weapons (One Handed)"] = {[tes3.weaponType.bluntOneHand] = true},
    ["Blunt Weapons (Two Handed)"] ={
        [tes3.weaponType.bluntTwoClose] = true, 
        [tes3.weaponType.bluntTwoWide] = true
    },
    ["Spears"] = {[tes3.weaponType.spearTwoWide] = true},
    ["Axes (One Handed)"] = {[tes3.weaponType.axeOneHand] = true},
    ["Axes (Two Handed)"] = {[tes3.weaponType.axeTwoHand] = true},
    ["Marksman Weapons"] ={
        [tes3.weaponType.marksmanBow] = true, 
        [tes3.weaponType.marksmanCrossbow] = true, 
        [tes3.weaponType.marksmanThrown] = true, 
        [tes3.weaponType.arrow] = true, 
        [tes3.weaponType.bolt] = true
    },
}

local confTable = config:get()
if not confTable then
    confTable = {
        enableBrutalBackstabbing = true,
        enabledWeaponTypes = { 
            ["Short Blades"] = true,
            ["Marksman Weapons"] = true,
        },
        stabAttacksOnly = true,
        showBackStabMsg = true
    }
    config.save(confTable)
end



local function registerConfig()

    local template = mwse.mcm.createtemplate{ name = "Brutal Backstabbing" }
    template:saveOnClose( config.path, confTable )
    template:register()

    local settingsPage = template:createSideBarPage("Settings")
    settingsPage:createOnOffButton{
        label = "Enable Brutal Backstabbing",
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enableBrutalBackstabbing", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Enable backstabbing messagebox",
        description = "A message box will appear indicating a succesfull backstab (the critical hit sound will still play when this is disabled).",
        variable = mwse.mcm.createTableVariable{ id = "showBackStabMsg", table = confTable }
    }

    settingsPage:createOnOffButton{
        label = "Limit backstabs to stabbing attacks only",
        description = (
            "When enabled, slashing and chopping attacks can not trigger a backstab. " ..
            "This does not affect marksman weapons (to enable/disable these, use the weapon type filter page)."
        ),
        variable = mwse.mcm.createTableVariable{ id = "stabAttacksOnly", table = confTable }
    }

    template:createExclusionsPage{
        label = "Weapon Type Filter",
        description = "Choose which weapon types are able to land backstabbing attacks.",
        variable = mwse.mcm.createTableVariable{ id = "enabledWeaponTypes", table = confTable },
        leftListLabel = "Allowed",
        rightListLabel = "Blocked",
        filters = {
            {
                label = "Weapon Types",
                callback = (
                    function()
                        local list = {}
                        for weaponName, _ in pairs(this.weaponList) do
                            table.insert(list, weaponName)
                        end
                        return list
                    end
                )
            }
        }
    }
end

event.register("modConfigReady", registerConfig)

return this