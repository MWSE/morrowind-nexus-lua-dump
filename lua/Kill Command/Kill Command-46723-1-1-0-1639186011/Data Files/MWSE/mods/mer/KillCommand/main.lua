local configPath = "kill_command"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = {
        attackKey = {
            keyCode = tes3.scanCode.k
        },
        blacklist = {},
        showMessage = true
    }
end

local function inBlackList(actor)
	local reference = actor.reference

	-- Get the ID. If we're looking at an instance, check against the base object instead.
	local id = reference.id
	if (reference.object.isInstance) then
		id = reference.object.baseObject.id
	end

	-- Is it in our blacklist?
    if config.blacklist[id] then
		return true
	end

    -- We didn't find it in the blacklist table above.
	return false
end

local function isKeyPressed(pressed, expected)
    return (
        pressed.keyCode == expected.keyCode and
        not not pressed.isShiftDown == not not expected.isShiftDown and
        not not pressed.isControlDown == not not expected.isControlDown and
        not not pressed.isAltDown == not not expected.isAltDown
    )
end

local function keyDown(e)
    if isKeyPressed(e, config.attackKey) and not tes3.menuMode() then

        local result = tes3.rayTest{
            position = tes3.getPlayerEyePosition(),
            direction = tes3.getPlayerEyeVector()
        }
        local lookingAtValidTarget = (
            result and
            result.reference and
            result.reference.mobile and
            result.reference.mobile.health.current > 0 and
            tes3.mobilePlayer.friendlyActors
        )
        local targetIsFriendly = false
        for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
            if actor.reference == result.reference then
                targetIsFriendly = true
            end
        end

        if lookingAtValidTarget and not targetIsFriendly then
            local companionCount = 0
            local companion = nil

            for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
                local validActor = (
                    actor ~= tes3.mobilePlayer and
                    actor.reference ~= result.reference and
                    not inBlackList(actor)
                )
                if validActor then
                    companionCount = companionCount + 1
                    companion = actor.reference.object.name
                    mwscript.startCombat({ reference = actor, target = result.reference })
                end
            end

            local enemy = result.reference.object.name
            if companionCount == 1 then
                tes3.messageBox("%s attacks %s", companion, enemy)

            elseif companionCount > 1 then
                tes3.messageBox("Everyone attacks %s", enemy)
            end
            local isNPC = (
                result.reference.object.isInstance and
                ( result.reference.baseObject.objectType == tes3.objectType.npc )
                or
                ( result.reference.object.objectType == tes3.objectType.npc  )
            )

            if companionCount > 0 and isNPC then
                local isHostile
                for actor in tes3.iterate(tes3.mobilePlayer.hostileActors) do
                    if actor.reference == result.reference then
                        --isHostile = true
                    end
                end
                if not isHostile then
                    tes3.triggerCrime{
                        victim = result.reference,
                        type = tes3.crimeType.attack
                    }
                end
            end

        end
    end
end
event.register("keyDown", keyDown)



----MCM
local function registerModConfig()
    local EasyMCM = require("easyMCM.EasyMCM")


    local template = EasyMCM.createTemplate({ name = "Kill Command" })
    template:saveOnClose(configPath, config)

    local page = template:createPage()
    page.noScroll = true
    page.indent = 0
    page.postCreate = function(self)
        self.elements.innerContainer.paddingAllSides = 10
    end

    page:createHyperLink{
        text = "Made by Merlord",
        exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
        postCreate = (
            function(self)
                self.elements.outerContainer.borderTop = self.indent
                self.elements.info.layoutOriginFractionX = 0.5
            end
        ),
    }

    local hotkey = page:createKeyBinder{
        label = "Assign Attack Command Key",
        allowCombinations = true,
        variable = EasyMCM:createTableVariable{
            id = "attackKey",
            table = config,
        }
    }

    local confirmMessageButton = page:createOnOffButton{
        label = "Show confirmation message",
        variable = EasyMCM.createTableVariable{
            id = "showMessage",
            table = config,
        }
    }

    local exclusionsList = page:createExclusionsPage{
        createOuterContainer = function(self, parent)
            local outerContainer = parent:createBlock()
            outerContainer.flowDirection = "top_to_bottom"
            outerContainer.widthProportional = 1.0
            outerContainer.heightProportional = 1.0
            self.elements.outerContainer = outerContainer
        end,
        label = "BlackList",
        showAllBlocked = true,
        variable = EasyMCM:createTableVariable{
            id = "blacklist",
            table = config,
        },
        filters = {
            {
                label = "Friendly Actors",
                callback = function()
                    local list = {}
                    local macp = tes3.mobilePlayer
                    if (macp) then
                        for actor in tes3.iterate(macp.friendlyActors) do
                            -- If the companion doesn't currently have a target, isn't the player, and isn't in a blacklist, start combat.
                            if (actor ~= macp) then
                                local reference = actor.reference
                                local id = reference.id
                                if (reference.object.isInstance) then
                                    id = reference.object.baseObject.id
                                end
                                table.insert(list, id)
                            end
                        end
                    end
                    return list
                end
            },
            {
                label = "NPCs",
                type = "Object",
                objectType = tes3.objectType.npc
            },
            {
                label = "Creatures",
                type = "Object",
                objectType = tes3.objectType.creature
            }
        }
    }


    EasyMCM.register(template)
end

event.register("modConfigReady", registerModConfig)