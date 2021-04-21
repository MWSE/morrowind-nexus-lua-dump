local modName = "Accidental Theft Prevention"
local configPath = "noAccidentalTheft"
local config = mwse.loadConfig(configPath, {
    enabled = true,
    blacklist = {}
})

local function isBlacklisted(ref)
    return config.blacklist[string.lower(ref.object.id)]
end

local function onActivate(e)
    if config.enabled then
        if not tes3.hasOwnershipAccess{target = e.target} then
            if not tes3.player.mobile.isSneaking then
                if not isBlacklisted(e.target) then
                    return false
                end
            end
        end
    end
end

event.register("activate", onActivate)

local function registerMCM()
    local template = mwse.mcm.createTemplate(modName)
    template:saveOnClose(configPath, config)
    template:register()

    local settingsDescription = (
        "This mod prevents you from stealing items unless you are sneaking."
    )
    local settingsPage = template:createPage{
        label = "Settings",
        --description = settingsDescription
        noScroll = true,
        indent = 0,
        postCreate = function(self)
            self.elements.innerContainer.paddingAllSides = 10
        end
    }

    do 
        local category = settingsPage:createCategory(modName)
        category:createInfo{ text = settingsDescription }

        settingsPage:createYesNoButton{
            label = "Enable mod",
            variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
        }

        settingsPage:createExclusionsPage{
            createOuterContainer = function(self, parent)
                local outerContainer = parent:createBlock()
                outerContainer.flowDirection = "top_to_bottom"
                outerContainer.widthProportional = 1.0
                outerContainer.heightProportional = 1.0
                self.elements.outerContainer = outerContainer
            end,
            label = "Blacklist",
            variable = mwse.mcm.createTableVariable{ id = "blacklist", table = config },
            filters = {
                {
                    label = "Alchemy",
                    type = "Object",
                    objectType = tes3.objectType.alchemy,
                },
                {
                    label = "Ammunition",
                    type = "Object",
                    objectType = tes3.objectType.ammunition,
                },
                {
                    label = "Apparatus",
                    type = "Object",
                    objectType = tes3.objectType.apparatus,
                },
                {
                    label = "Armor",
                    type = "Object",
                    objectType = tes3.objectType.armor,
                },
                {
                    label = "Books",
                    type = "Object",
                    objectType = tes3.objectType.book,
                },
                {
                    label = "Container",
                    type = "Object",
                    objectType = tes3.objectType.container,
                },
                {
                    label = "Clothing",
                    type = "Object",
                    objectType = tes3.objectType.clothing,
                },
                {
                    label = "Doors",
                    type = "Object",
                    objectType = tes3.objectType.door
                },
                {
                    label = "Ingredients",
                    type = "Object",
                    objectType = tes3.objectType.ingredient,
                },
                {
                    label = "Lights",
                    callback = function()
                        local list = {}
                        for obj in tes3.iterateObjects(tes3.objectType.light) do
                            if obj.canCarry then
                                list[#list+1] = (obj.baseObject or obj).id:lower()
                            end
                            table.sort(list)
                        end
                        return list
                    end
                },
                {
                    label = "Lockpicks",
                    type = "Object",
                    objectType = tes3.objectType.lockpick,
                },
                {
                    label = "Misc Items",
                    type = "Object",
                    objectType = tes3.objectType.miscItem,
                },
                {
                    label = "Probes",
                    type = "Object",
                    objectType = tes3.objectType.probe,
                },
                {
                    label = "Repair Items",
                    type = "Object",
                    objectType = tes3.objectType.repairItem,
                },
                {
                    label = "Weapons",
                    type = "Object",
                    objectType = tes3.objectType.weapon,
                },
            }
        }
    end

   

end
event.register("modConfigReady", registerMCM)
