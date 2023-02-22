local config = {}
local configDefault = {
	configVersion = 1,
    minTime = 24,
    maxTime = 2400
}
local configPath = "icarian_incident"

local timerKey = "icarian_incident:tarhiel_timer"
local tarhielID = "agronian guy"
local journalID = "bk_falljournal_unique"
local scriptID = "fallingScript"

local falling = false
local realTarhiel

local function tryBonkPlayer()
    --Safety (corpse could be disposed, etc)
    if realTarhiel == nil or realTarhiel.mobile == nil then
        event.unregister(tes3.event.simulate, tryBonkPlayer)
        return
    end

    if realTarhiel.mobile.velocity.z > -100 then
        if falling then
            tes3.dropItem{reference = realTarhiel, item = journalID}
        end
        return
    elseif tes3.player.mobile.position:distance(realTarhiel.mobile.position) < 150 then
        tes3.mobilePlayer:applyFatigueDamage(tes3.mobilePlayer.fatigue.current, 1, true)
        tes3.mobilePlayer:applyDamage{damage = (tes3.mobilePlayer.health.current * 0.5)}
        timer.start{
            type = timer.simulate,
            duration = 0.4,
            callback = function()
                tes3.dropItem{reference = realTarhiel, item = journalID}
            end
        }
        event.unregister(tes3.event.simulate, tryBonkPlayer)
    end
end

local function spawnTarhiel()
    falling = false
    realTarhiel = tes3.createReference{object = tarhielID, position = tes3.player.position}
    tes3.addItem{reference = realTarhiel, item = journalID}
    realTarhiel.sceneNode.appCulled = true

    local estimatedFallTime = 3.4
    local prevPlayerPosition = tes3.player.position:copy()

    timer.start{
        type = timer.simulate,
        duration = 0.5,
        callback = function()
            falling = true
            realTarhiel.sceneNode.appCulled = false
            realTarhiel.mobile:doJump{velocity = tes3vector3.new(0,0,8000)}
            local playerVelocity = tes3.player.position:copy()
            playerVelocity = playerVelocity - prevPlayerPosition
            realTarhiel.mobile.position = tes3.player.position + tes3vector3.new(0,0,3000) + (playerVelocity * estimatedFallTime)
            realTarhiel.mobile.velocity = tes3vector3.new(0,0,-1500)
            tes3.say{reference = tes3.player, soundPath = "Vo\\w\\m\\Hit_WM006.mp3", subtitle = "AAAAAAARRRRRRGGGGGGGGGGGGGGGGGGGG!!!!!!"}
            event.register(tes3.event.simulate, tryBonkPlayer)
        end
    }
    timer.start{
        type = timer.simulate,
        duration = 1.5,
        callback = function()
            realTarhiel.mobile:kill()
        end
    }
end

--event.register(tes3.event.keyDown, spawnTarhiel, {filter = tes3.scanCode.y})

local function trySpawnTarhiel()
    local retryTimer
    retryTimer = timer.start{
        type = timer.simulate,
        duration = 5,
        iterations = -1,
        callback = function()
            if tes3.mobilePlayer.restHoursRemaining > 0 then
                return
            end
            if not tes3.player.cell.isOrBehavesAsExterior then
                return
            end
            if tes3.mobilePlayer.isSwimming then
                return
            end
            if tes3.mobilePlayer.traveling then
                return
            end
            retryTimer:cancel()
            spawnTarhiel()
            tes3.player.data.icarian_incident = true
            --tes3.messageBox("tarhiel created, data = true")
        end
    }
end

--- @param e loadedEventData
local function loadedCallback(e)
    if tes3.player.data.icarian_incident == nil then
        --tes3.messageBox("data is nil, registering. tarhiel deleted")
        local time = math.random(config.minTime, config.maxTime)
        --tes3.messageBox("time: " .. time)
        timer.start{
            type = timer.game,
            persist = true,
            iterations = 1,
            duration = time,
            callback = timerKey
        }
        timer.register(timerKey, trySpawnTarhiel)

        tes3.getReference(tarhielID):disable()
        tes3.getReference(journalID):disable()
        tes3.player.data.icarian_incident = false
    elseif tes3.player.data.icarian_incident == false then
        timer.register(timerKey, trySpawnTarhiel)
        --tes3.messageBox("data was false, registering timer")
    else
        --tes3.messageBox("data was true, nothing to be done")
    end
end
event.register(tes3.event.loaded, loadedCallback)

event.register(tes3.event.initialized, function()
    mwse.overrideScript(scriptID, function()end)
end)

local function registerModConfig()
	table.copy(mwse.loadConfig(configPath, configDefault), config)

	local template = mwse.mcm.createTemplate("The Icarian Incident")
	template.onClose = function()
		mwse.saveConfig(configPath, config)
	end

	local refreshPage = function()
		local pageBlock = template.elements.pageBlock
		pageBlock:destroyChildren()
		template.currentPage:create(pageBlock)
	end

	template:createPage{
		components = {
			{
				class = "Info",
				label = "The Icarian Incident\nby Petethegoat, for Morrowind Modding Community Winter Modjam 2023",
				paddingBottom = 10
			},
			{
				class = "Category",
				label = "Number of in game hours until The Incident (will only take effect on a new game)",
				components = {
					{
						class = "Slider",
						label = "Minimum",
						min = 8, max = 2400, step = 8, jump = 24,
						variable = mwse.mcm:createTableVariable{ id = "minTime", table = config },
                        callback = function()
							if config.maxTime < config.minTime then
                                config.maxTime = config.minTime
                                refreshPage()
                            end
                        end
					},
					{
						class = "Slider",
						label = "Maximum",
						min = 8, max = 2400, step = 8, jump = 24,
						variable = mwse.mcm:createTableVariable{ id = "maxTime", table = config },
                        callback = function()
							if config.minTime > config.maxTime then
                                config.minTime = config.maxTime
                                refreshPage()
                            end
						end
					}
				}
			}
		}
	}

	template:register()
	mwse.log("[The Icarian Incident] 1.2 loaded successfully.")
end
event.register(tes3.event.modConfigReady, registerModConfig)