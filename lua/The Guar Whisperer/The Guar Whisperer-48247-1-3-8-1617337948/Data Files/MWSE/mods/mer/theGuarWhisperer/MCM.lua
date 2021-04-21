local common = require("mer.theGuarWhisperer.common")
local animalConfig = require("mer.theGuarWhisperer.animalConfig")
local config = common.getConfig()
local function registerMcm()

    local template = mwse.mcm.createTemplate{ name = "The Guar Whisperer"}
    template:saveOnClose(common.configPath, config)
    template:register()

    local settingsPage = template:createSideBarPage("Settings")
    do
        local descriptionCategory = settingsPage.sidebar:createCategory("The Guar Whisperer")
        local sidebarText = (
            "This mod allows you to tame and breed guars as companions.\n\n" ..

            "To begin: activate a guar to feed it something. You'll then get to give it a name, and the context menu will become available. " ..
            "At first, you won't have many commands available. Try petting it a few times or giving it some more food, until " ..
            "you recieve a notification that your guar trusts you enough to follow you. \n\n" ..

            "The only way to gain your guar's trust is to spend time with it and keep it happy. Play fetch, give it pets, " ..
            "and keep it well fed, and its trust will increase in no time. " .. 
            "The more your guar trusts you, the more commands will become available. Eventually your guar will be able to fetch, harvest or " ..
            "steal items for you, equip a pack (also available at traders) to unlock companion share, and eventually breed with other guars " ..
            "and make baby guars. \n\n" ..
            
            "If your guar gets lost, you can purchase a guar flute that, when played, will summon your guar back to you." ..
            "Flutes, packs, and toys can be purchased from Arrille, Ra'virr, as well as various other outfitters and traders. \n\n" ..

            "If you have Ashfall installed, camping gear will display on your guar's pack when added to its inventory. " ..
            "Ashfall is a camping survival mod currently in development. Go to the Morrowind Modding Community Discord to " ..
            "get the alpha version."
        )
        descriptionCategory:createInfo{
            text = sidebarText
        }

        --SETTINGS
    
        local settingsCategory = settingsPage:createCategory("Settings")

        settingsCategory:createYesNoButton{
            label = "Enable Mod",
            description = "Turn this mod on or off.",
            variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
        }

        settingsCategory:createKeyBinder{
            label = "Toggle Command Menu",
            description = "The key or key combination used to toggle the context command menu. Default: q",
            allowCombinations = true,
            variable = mwse.mcm.createTableVariable{ id = "commandToggleKey", table = config }
        }

        settingsCategory:createYesNoButton{
            label = "Display all Gear",
            description = "Enable this if you don't have Ashfall installed but want to see all the cool camping equipment on the back of your pack guar.",
            variable = mwse.mcm.createTableVariable{ id = "displayAllGear", table = config }
        }

        settingsCategory:createSlider{
            label = "Set Teleport Distance",
            description = "Set the minimum distance from the player that will trigger a teleport when a guar is following you.",
            variable = mwse.mcm.createTableVariable{ id = "teleportDistance", table = config },
            min = 500,
            max = 3000,
            jump = 100,
            step = 1
        }

        --DEBUG

        local debugCategory = settingsPage:createCategory("Debug Options")

        debugCategory:createDropDown{
            label = "Log Level",
            description = "Set the logging level for mwse.log. Keep on INFO unless you are debugging.",
            options = {
                { label = "TRACE", value = "TRACE"},
                { label = "DEBUG", value = "DEBUG"},
                { label = "INFO", value = "INFO"},
                { label = "ERROR", value = "ERROR"},
                { label = "NONE", value = "NONE"},
            },
            variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
            callback = function(self)
                common.log:setLogLevel(self.variable.value)
            end
        }

        --CREDITS

        local creditsCategory = settingsPage:createCategory("\nCredits: ")

        local credits = {
            {
                name = "Made by Merlord",
                description = "",
                link = "https://www.nexusmods.com/users/3040468?tab=user+files"
            },
            {
                name = "Alei3ter: ",
                description = "Pack guar model",
                link = "https://www.nexusmods.com/morrowind/users/20765944"
            },
            {
                name = "Remiros",
                description = "Ball retexture",
                link = "https://www.nexusmods.com/morrowind/users/899234"
            },
            {
                name = "R-zero: ",
                description = "Guar flute model",
                link = "https://www.nexusmods.com/morrowind/users/3241081"
            },
            {
                name = "RedFurryDemon and\nOperatorJack",
                description = "Code from Feed the Animals",
                link = "https://www.nexusmods.com/morrowind/mods/47894"
            },
            {
                name = "Greatness7: ",
                description = "Code borrowed from Graphic Herbalism",
                link = "https://www.nexusmods.com/morrowind/mods/46599"
            },
            {
                name = "NullCascade: ",
                description = "MWSE troubleshooting",
                link = "https://www.nexusmods.com/morrowind/users/26153919"
            },
            {
                name = "Tizzo: ",
                description = "Help with companion AI",
                link = "https://www.nexusmods.com/morrowind/users/302"
            },
        }
        for _, credit in ipairs(credits) do
            local block = creditsCategory:createSideBySideBlock()
            block:createHyperLink{
                text = credit.name,
                exec = "start" .. credit.link,
                postCreate = (
                    function(self)
                        self.elements.outerContainer.autoWidth = true
                        self.elements.outerContainer.widthProportional = nil
                        self.elements.outerContainer:updateLayout()
                    end
                ),
            }
            block:createInfo{ text = credit.description}
        end
    end

    template:createExclusionsPage{
        label = "Guar Equipment Merchants",
        description = "Move merchants into the left list to allow them to sell guar packs, flutes, etc. Changes won't take effect until the next time you enter the cell where the merchant is. Note that removing a merchant from the list won't remove the equipment if you have already visited the cell they are in.",
        variable = mwse.mcm.createTableVariable{ id = "merchants", table = config },
        leftListLabel = "Merchants who sell guar equipment",
        rightListLabel = "Merchants",
        filters = {
            {
                label = "Merchants",
                callback = function()
                    --Check if npc is able to sell any guar gear
                    local function canSellGear(obj)
                        if obj.class then
                            local bartersFields = {
                                "bartersMiscItems",
                                "bartersWeapons"
                            }
                            for _, field in ipairs(bartersFields) do
                                if obj.class[field] == true then
                                    return true
                                end
                            end
                        end
                        return false
                    end

                    local merchants = {}
                    for obj in tes3.iterateObjects(tes3.objectType.npc) do
                        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                            if canSellGear(obj) then
                                merchants[#merchants+1] = (obj.baseObject or obj).id:lower()
                            end
                        end
                    end
                    table.sort(merchants)
                    return merchants
                end
            }
        }
    }

    template:createExclusionsPage{
        label = "Scripted Guars",
        description = "By default, scripted guars can not be tamed, as the script will get overridden and could cause issues. However, if you have a mod that adds scripts to vanilla guars, or you really want to tame some other scripted guar, you can add them to the whitelist here. Be careful about whitelisting guar_white_unique, as you will not be able to complete the Dreams of a White Guar quest once you have done so.",
        variable = mwse.mcm.createTableVariable{ id = "exclusions", table = config },
        leftListLabel = "Whitelist",
        rightListLabel = "Blacklist",
        filters = {
            {
                label = "Scripted Creatures",
                callback = function()
                    local baseCreatures = {}
                    for obj in tes3.iterateObjects(tes3.objectType.creature) do
                        if not (obj.baseObject and obj.baseObject.id ~= obj.id ) then
                            if obj.script then
                                if animalConfig.meshes[obj.mesh:lower()] then
                                    baseCreatures[#baseCreatures+1] = (obj.baseObject or obj).id:lower()
                                end
                            end
                        end
                    end
                    table.sort(baseCreatures)
                    return baseCreatures
                end
            }
        }
    }
end

event.register("modConfigReady", registerMcm)