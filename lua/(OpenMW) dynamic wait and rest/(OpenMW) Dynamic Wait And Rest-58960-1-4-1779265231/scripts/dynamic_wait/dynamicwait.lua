local self_mod = require('openmw.self')
local anim     = require('openmw.animation')
local core     = require('openmw.core')
local input    = require('openmw.input')
local ui       = require('openmw.ui')
local util     = require('openmw.util')
local async    = require('openmw.async')
local I        = require('openmw.interfaces')
local types    = require('openmw.types')
local camera   = require('openmw.camera')
local storage  = require('openmw.storage')

local v2 = util.vector2

local POSE_TO_ANIM = {
    ["sitting"]              = "idle5",
    ["sitting cross-legged"] = "idle4",
    ["lay on right side"]    = "idle7",
    ["lay on left side"]     = "idle8",
    ["lay on back"]          = "idle9",
}

local CFG = {
    waitAnimGroup    = "idle5",
    restAnimGroup    = "idle5",
    loopCount        = 999999,
    maxHours         = 24,
    maxDays          = 30,
    secondsPerHour   = 0.3,
    maxTotalWaitTime = 15,
    bottleDistance   = 25,
    bottleSideOffset = 35,
    bottleHeight     = 15,
    campfireDistance = 150,
    cameraWaitZOffset = -50,
}

I.Settings.registerPage({
   key         = 'WAITREST',
   l10n        = 'wayrest',
   name        = 'Dynamic wait and rest',
   description = 'Dynamic wait and rest',
})

input.registerAction {
   key          = 'wayrestkey',
   type         = input.ACTION_TYPE.Boolean,
   l10n         = 'wayrest',
   name         = 'Wait/rest Key',
   description  = 'Key used to wait/rest',
   defaultValue = false,
}

I.Settings.registerGroup({
   key              = 'wayrest_group',
   page             = 'WAITREST',
   l10n             = 'wayrest',
   name             = 'Activation Key',
   permanentStorage = true,
   settings = {
        {
            key         = 'wayrestkey',
            renderer    = 'inputBinding',
            name        = 'Wait/rest Key',
            description = 'Key used to wait/rest',
            default     = 'T',
            argument    = { type = 'action', key = 'wayrestkey' },
        },
		{
			key = "waitpose",
			name = "Waiting pose",
			default = "sitting",
			renderer = "select",
			argument = { disabled = false,
			l10n = "wayrest", 
			items = { "sitting", "sitting cross-legged", "lay on right side", "lay on left side", "lay on back" }
			},
		},
		{
			key = "restpose",
			name = "Resting pose",
			default = "sitting",
			renderer = "select",
			argument = { disabled = false,
			l10n = "wayrest", 
			items = { "sitting", "sitting cross-legged", "lay on right side", "lay on left side", "lay on back" }
			},
		},
    },
})

local CITY_CELLS = {
    ["Seyda Neen"]     = true, ["Balmora"]       = true, ["Caldera"]      = true,
    ["Vivec"]          = true, ["Ald-ruhn"]       = true, ["Gnisis"]       = true,
    ["Maar Gan"]       = true, ["Molag Mar"]      = true, ["Suran"]        = true,
    ["Dagon Fel"]      = true, ["Vos"]            = true, ["Tel Mora"]     = true,
    ["Tel Aruhn"]      = true, ["Tel Branora"]    = true, ["Sadrith Mora"] = true,
    ["Ghostgate"]      = true, ["Pelagiad"]       = true, ["Ebonheart"]    = true,
    ["Tel Vos"]        = true, ["Ald Velothi"]    = true, ["Khuul"]        = true,
    ["Hla Oad"]        = true, ["Gnaar Mok"]      = true, ["Mournhold"]    = true,
    ["Raven Rock"]     = true, ["Fort Frostmoth"] = true, ["Skaal Village"]= true,
}

local MONTH_NAMES = {
    "Morning Star", "Sun's Dawn", "First Seed",  "Rain's Hand",
    "Second Seed",  "Midyear",    "Sun's Height", "Last Seed",
    "Hearthfire",   "Frostfall",  "Sun's Dusk",   "Evening Star",
}

local function isMenuActive()
    local mode = I.UI.getMode()
    return mode ~= nil and mode ~= 'Interface'
end

local function getGameTimeString()
    local totalHours = core.getGameTime() / 3600.0
    local h = math.floor(totalHours % 24)
    local m = math.floor((totalHours % 1) * 60)
    return string.format("%02d:%02d", h, m)
end

local function getGameDateString()
    local totalHours = core.getGameTime() / 3600.0
    local totalDays  = math.floor(totalHours / 24)
    local day        = (totalDays % 30) + 1
    local monthIdx   = math.floor(totalDays / 30) % 12 + 1
    return string.format("Day %d, %s", day, MONTH_NAMES[monthIdx])
end

local isRest              = false
local animPlaying         = false
local wasWaiting          = false
local lastSimTime         = nil
local pendingAnimPlay     = false
local savedCameraOffsets  = {}
local cameraOffsetApplied = false
local savedEquipment      = {}

local waitRealStart           = nil
local cachedTotalRealDuration = 0
local lastProgressUpdate      = 0

local waitMenu    = nil
local menuOpen    = false
local hoursToWait = 1
local daysToWait  = 0

local waitingActive     = false
local hoursDone         = 0
local totalHoursWait    = 0
local hourRealTimeStart = nil
local progressElem      = nil

local stopWaiting
local suppressRestMenu = false
local currentDecay     = 1.0

local WEAPON_SLOT = types.Actor.EQUIPMENT_SLOT.CarriedRight
local SHIELD_SLOT = types.Actor.EQUIPMENT_SLOT.CarriedLeft
local HELMET_SLOT = types.Actor.EQUIPMENT_SLOT.Helmet

local function computeDecay(n, firstDur, targetTotal)
    if firstDur * n <= targetTotal then return 1.0 end
    local lo, hi = 1e-4, 1.0 - 1e-7
    for _ = 1, 64 do
        local mid = (lo + hi) * 0.5
        local s = firstDur * (1.0 - mid ^ n) / (1.0 - mid)
        if s > targetTotal then hi = mid else lo = mid end
    end
    return (lo + hi) * 0.5
end

local function currentHourDuration()
    return math.max(0.1, CFG.secondsPerHour * (currentDecay ^ hoursDone))
end

local function totalRealDuration()
    if math.abs(currentDecay - 1.0) < 1e-6 then
        return totalHoursWait * CFG.secondsPerHour
    end
    return CFG.secondsPerHour * (1.0 - currentDecay ^ totalHoursWait) / (1.0 - currentDecay)
end

local function unequipAndSave()
    savedEquipment = {}
    local eq = types.Actor.equipment(self_mod)

	local weaponItem = eq[WEAPON_SLOT]
	local shieldItem = eq[SHIELD_SLOT]
	local helmetItem = eq[HELMET_SLOT]

	if weaponItem then
		table.insert(savedEquipment, { slot = WEAPON_SLOT, object = weaponItem })
	end
	if helmetItem then
		table.insert(savedEquipment, { slot = HELMET_SLOT, object = helmetItem })
	end
	if shieldItem then
		table.insert(savedEquipment, { slot = SHIELD_SLOT, object = shieldItem })
	end

    if #savedEquipment > 0 then
        local newEq = {}
			for slot, item in pairs(eq) do
				if slot ~= WEAPON_SLOT and slot ~= HELMET_SLOT and slot ~= SHIELD_SLOT then
					newEq[slot] = item
				end
			end
        types.Actor.setEquipment(self_mod, newEq)
    end

    local rawFwd = self_mod.rotation:apply(util.vector3(0, 1, 0))
    local fwd    = util.vector3(rawFwd.x, rawFwd.y, 0)
    local right  = util.vector3(fwd.y, -fwd.x, 0)
    local base   = self_mod.position

	local fwdOffsets  = { 30, 40, 0 }   
	local sideOffsets = { 25, -40, -40 }
	local zOffsets    = { 8, 8, 8 }

	local items = {}
	for i, entry in ipairs(savedEquipment) do
		table.insert(items, {
			recordId = entry.object.recordId,
			pos      = base
					   + fwd   * fwdOffsets[i]
					   + right * sideOffsets[i]
					   + util.vector3(0, 0, zOffsets[i]),
			rot = i == 1 and self_mod.rotation:getYaw() + math.rad(25) or nil,
		})
	end
    core.sendGlobalEvent('DWR_SpawnEquipment', { items = items })
end

local function reequipSaved()
    core.sendGlobalEvent('DWR_RemoveEquipment', {})
    if #savedEquipment == 0 then return end

    local eq = types.Actor.equipment(self_mod)
    for _, entry in ipairs(savedEquipment) do
        eq[entry.slot] = entry.object
    end
    types.Actor.setEquipment(self_mod, eq)
    savedEquipment = {}
end

local function detectIsRest()
    local cellName = self_mod.cell.name or ""
    if CITY_CELLS[cellName] then return false end
    for cityName in pairs(CITY_CELLS) do
        if cellName:find(cityName, 1, true) then return false end
    end
    return true
end

local function applyRestRecovery()
    if not isRest then return end
    if not types.NPC.objectIsInstance(self_mod) then return end

    local endurance = types.NPC.stats.attributes.endurance(self_mod)
    local willpower = types.NPC.stats.attributes.willpower(self_mod)
    local strength  = types.NPC.stats.attributes.strength(self_mod)
    local agility   = types.NPC.stats.attributes.agility(self_mod)

    local END_v = endurance.modified
    local WIL_v = willpower.modified
    local STR_v = strength.modified
    local AGI_v = agility.modified

    local healthStat  = types.Actor.stats.dynamic.health(self_mod)
    local magickaStat = types.Actor.stats.dynamic.magicka(self_mod)
    local fatigueStat = types.Actor.stats.dynamic.fatigue(self_mod)

    local hpRegen  = math.max(1, math.floor(END_v / 20))
    local mpRegen  = math.max(0, math.floor(WIL_v / 5))
    local fatRegen = totalHoursWait > 0
                     and (fatigueStat.base / totalHoursWait)
                     or  math.floor((STR_v + WIL_v + AGI_v + END_v) / 4)

    healthStat.current  = math.min(healthStat.current  + hpRegen,  healthStat.base)
    magickaStat.current = math.min(magickaStat.current + mpRegen,  magickaStat.base)
    fatigueStat.current = math.min(fatigueStat.current + fatRegen, fatigueStat.base)
end

local function playWaitAnim(groupname)
    anim.cancel(self_mod, groupname)
    I.AnimationController.playBlendedAnimation(groupname, {
        priority = anim.PRIORITY.Scripted,
        loops    = 100,
    })
    animPlaying = true
end

local function stopWaitAnim(groupname)
    if not animPlaying then return end
    anim.cancel(self_mod, groupname)
    animPlaying = false
end

local function applyCameraWaitOffset()
    savedCameraOffsets = {}
    cameraOffsetApplied = false

    local ok1, res1 = pcall(function()
        local off = camera.getFirstPersonOffset()
        camera.setFirstPersonOffset(off + util.vector3(0, 0, CFG.cameraWaitZOffset))
        return off
    end)
    if ok1 and res1 ~= nil then savedCameraOffsets.fp = res1 end

    local ok2, res2 = pcall(function()
        local off = camera.getFocalPreferredOffset()
        camera.setFocalPreferredOffset(off + util.vector2(0, CFG.cameraWaitZOffset))
        return off
    end)
    if ok2 and res2 ~= nil then savedCameraOffsets.focal = res2 end

    cameraOffsetApplied = true
end

local function resetCameraWaitOffset()
    if not cameraOffsetApplied then return end
    if savedCameraOffsets.fp ~= nil then
        pcall(function() camera.setFirstPersonOffset(savedCameraOffsets.fp) end)
    end
    if savedCameraOffsets.focal ~= nil then
        pcall(function() camera.setFocalPreferredOffset(savedCameraOffsets.focal) end)
    end
    savedCameraOffsets = {}
    cameraOffsetApplied = false
end

local function destroyProgressUI()
    if progressElem then
        progressElem:destroy()
        progressElem = nil
    end
end

local function formatHours(h)
    local d = math.floor(h / 24)
    local r = h % 24
    if d > 0 and r > 0 then
        return string.format("%dd %dh", d, r)
    elseif d > 0 then
        return string.format("%dd", d)
    else
        return string.format("%dh", r)
    end
end

local function createProgressUI(ratio)
    destroyProgressUI()
    ratio = ratio or 0

    local label   = isRest and "Resting..." or "Waiting..."
    local counter = string.format("%s / %s",
        formatHours(hoursDone), formatHours(totalHoursWait))
    local gap     = { type = ui.TYPE.Widget, props = { size = v2(220, 6) } }

    local TOTAL_BLOCKS = 48
    local filled = math.floor(ratio * TOTAL_BLOCKS)
    local empty  = TOTAL_BLOCKS - filled

    progressElem = ui.create({
        type     = ui.TYPE.Container,
        layer    = 'Windows',
        template = I.MWUI.templates.boxTransparentThick,
        props    = {
            relativePosition = v2(.5, .07),
            anchor           = v2(.5, 0),
            propagateEvents  = false,
        },
        content = ui.content({
            {
                type  = ui.TYPE.Flex,
                props = { horizontal = false, align = ui.ALIGNMENT.Center,
                          arrange = ui.ALIGNMENT.Center },
                content = ui.content({
                    { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
                      props = { text = label, textSize = 17 } },
                    gap,
                    { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
                      props = { text = counter, textSize = 20 } },
                    { type = ui.TYPE.Widget, props = { size = v2(10, 5) } },
                    {
                        type  = ui.TYPE.Flex,
                        props = { horizontal = true, align = ui.ALIGNMENT.Center,
                                  arrange = ui.ALIGNMENT.Center },
                        content = ui.content({
                            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
                              props = { text = string.rep("|", filled), textSize = 18,
                                        textColor = util.color.rgba(0.3, 0.65, 1.0, 1.0) } },
                            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
                              props = { text = string.rep("|", empty), textSize = 18,
                                        textColor = util.color.rgba(0.2, 0.2, 0.3, 1.0) } },
                        }),
                    },
                    gap,
                    { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
                      props = { text = "[RMB]  stop", textSize = 13,
                                textColor = util.color.rgba(0.55, 0.55, 0.55, 1) } },
                }),
            },
        }),
    })
end

local function startWaiting(hours, rest)
    local s        = storage.playerSection('wayrest_group')
    local waitPose = s:get('waitpose') or "sitting"
    local restPose = s:get('restpose') or "sitting"
    CFG.waitAnimGroup = POSE_TO_ANIM[waitPose] or "idle5"
    CFG.restAnimGroup = POSE_TO_ANIM[restPose] or "idle5"
    isRest         = rest
    waitingActive  = true
    hoursDone      = 0
    totalHoursWait = hours
    wasWaiting     = false
    lastSimTime    = nil

    local totalNaive = totalHoursWait * CFG.secondsPerHour
    if totalNaive > CFG.maxTotalWaitTime then
        currentDecay = computeDecay(totalHoursWait, CFG.secondsPerHour, CFG.maxTotalWaitTime)
    else
        currentDecay = 1.0
    end

    waitRealStart           = core.getRealTime()
    cachedTotalRealDuration = totalRealDuration()
    playWaitAnim(isRest and CFG.restAnimGroup or CFG.waitAnimGroup)
    hourRealTimeStart = core.getRealTime()
    createProgressUI()

    core.sendGlobalEvent('DWR_StartProgress', {
        startReal = core.getRealTime(),
        totalSec  = totalRealDuration(),
    })

    local rawFwd  = self_mod.rotation:apply(util.vector3(0, 1, 0))
    local fwd     = util.vector3(rawFwd.x, rawFwd.y, 0)
    local right   = util.vector3(fwd.y, -fwd.x, 0)
    local basePos = self_mod.position

    local bottlePos   = basePos
                      + fwd   * CFG.bottleDistance
                      + right * CFG.bottleSideOffset
                      + util.vector3(0, 0, CFG.bottleHeight)
    local campfirePos = basePos + fwd * CFG.campfireDistance

	local lightRecordId = nil
	local inv = types.Actor.inventory(self_mod)
	if inv then
		for _, item in ipairs(inv:getAll()) do
			local rid = (item.recordId or ""):lower()
			if rid:find("lantern") or rid:find("candle") or rid:find("torch") then
				lightRecordId = item.recordId:lower()
				break
			end
		end
	end

	core.sendGlobalEvent('DWR_SpawnBottles', {
		isRest        = isRest,
		bottlePos     = bottlePos,
		campfirePos   = campfirePos,
		playerFwd     = fwd,
		lightRecordId = lightRecordId,  
	})

    applyCameraWaitOffset()
    self_mod.object:sendEvent('FPV_SetEyeDropOverride', { offset = -70 })
    unequipAndSave()
end

stopWaiting = function()
    if not waitingActive then return end
    reequipSaved()
    waitingActive     = false
    hourRealTimeStart = nil
    hoursDone         = 0
    totalHoursWait    = 0
    currentDecay      = 1.0
    lastProgressUpdate = 0
    wasWaiting        = false
    lastSimTime       = core.getSimulationTime()
    waitRealStart           = nil
    cachedTotalRealDuration = 0

    stopWaitAnim(isRest and CFG.restAnimGroup or CFG.waitAnimGroup)
    destroyProgressUI()
    isRest = false
    core.sendGlobalEvent('DWR_StopProgress', {})
    resetCameraWaitOffset()
    self_mod.object:sendEvent('FPV_SetEyeDropOverride', { offset = 0 })
    core.sendGlobalEvent('DWR_RemoveBottles', {})
end

local function closeWaitMenu()
    if waitMenu then
        waitMenu:destroy()
        waitMenu = nil
    end
    if menuOpen then
        I.UI.removeMode('Interface')
        menuOpen = false
    end
end

local function openWaitUI(rest)
    if waitMenu then
        waitMenu:destroy()
        waitMenu = nil
    end

    if rest ~= nil then
        isRest      = rest
        hoursToWait = 1
        daysToWait  = 0
        if not menuOpen then
            I.UI.setMode('Interface', { windows = {} })
            menuOpen = true
        end
    end

    local gap    = { type = ui.TYPE.Widget, props = { size = v2(240, 8) } }
    local spacer = { type = ui.TYPE.Widget, props = { size = v2(12, 36) } }

    local timeRow = {
        type  = ui.TYPE.Flex,
        props = { horizontal = false, align = ui.ALIGNMENT.Center,
                  arrange = ui.ALIGNMENT.Center },
        content = ui.content({
            {
                type     = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props    = {
                    text      = getGameTimeString(),
                    textSize  = 22,
                    textColor = util.color.rgba(0.85, 0.85, 0.55, 1.0),
                },
            },
            {
                type     = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props    = {
                    text      = getGameDateString(),
                    textSize  = 13,
                    textColor = util.color.rgba(0.85, 0.85, 0.55, 1.0),
                },
            },
        }),
    }

    local titleBox = {
        type  = ui.TYPE.Widget,
        props = { size = v2(240, 28) },
        content = ui.content({
            {
                type     = ui.TYPE.Text,
                template = I.MWUI.templates.textNormal,
                props    = {
                    text             = isRest and "Rest" or "Wait",
                    relativePosition = v2(.5, .5),
                    anchor           = v2(.5, .5),
                    textSize         = 18,
                },
            },
        }),
    }

    local hoursLabel = {
        type     = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props    = { text = "Hours", textSize = 14,
                     textColor = util.color.rgba(0.7, 0.7, 0.7, 1.0) },
    }

    local btnMinusH = {
        type     = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props    = { size = v2(36, 36), propagateEvents = false },
        content  = ui.content({
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
              props = { text = "-", relativePosition = v2(.5,.5), anchor = v2(.5,.5), textSize = 22 } },
        }),
        events = {
            mousePress = async:callback(function()
                hoursToWait = math.max(1, hoursToWait - 1)
                openWaitUI(nil)
            end),
        },
    }

    local counterBoxH = {
        type  = ui.TYPE.Widget,
        props = { size = v2(48, 36) },
        content = ui.content({
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
              props = { text = tostring(hoursToWait),
                        relativePosition = v2(.5,.5), anchor = v2(.5,.5), textSize = 18 } },
        }),
    }

    local btnPlusH = {
        type     = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props    = { size = v2(36, 36), propagateEvents = false },
        content  = ui.content({
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
              props = { text = "+", relativePosition = v2(.5,.5), anchor = v2(.5,.5), textSize = 22 } },
        }),
        events = {
            mousePress = async:callback(function()
                hoursToWait = math.min(CFG.maxHours, hoursToWait + 1)
                openWaitUI(nil)
            end),
        },
    }

    local counterRowH = {
        type  = ui.TYPE.Flex,
        props = { horizontal = true, align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
        content = ui.content({ btnMinusH, counterBoxH, btnPlusH }),
    }

    local daysLabel = {
        type     = ui.TYPE.Text,
        template = I.MWUI.templates.textNormal,
        props    = { text = "Days", textSize = 14,
                     textColor = util.color.rgba(0.7, 0.7, 0.7, 1.0) },
    }

    local btnMinusD = {
        type     = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props    = { size = v2(36, 36), propagateEvents = false },
        content  = ui.content({
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
              props = { text = "-", relativePosition = v2(.5,.5), anchor = v2(.5,.5), textSize = 22 } },
        }),
        events = {
            mousePress = async:callback(function()
                daysToWait = math.max(0, daysToWait - 1)
                openWaitUI(nil)
            end),
        },
    }

    local counterBoxD = {
        type  = ui.TYPE.Widget,
        props = { size = v2(48, 36) },
        content = ui.content({
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
              props = { text = tostring(daysToWait),
                        relativePosition = v2(.5,.5), anchor = v2(.5,.5), textSize = 18 } },
        }),
    }

    local btnPlusD = {
        type     = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props    = { size = v2(36, 36), propagateEvents = false },
        content  = ui.content({
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
              props = { text = "+", relativePosition = v2(.5,.5), anchor = v2(.5,.5), textSize = 22 } },
        }),
        events = {
            mousePress = async:callback(function()
                daysToWait = math.min(CFG.maxDays, daysToWait + 1)
                openWaitUI(nil)
            end),
        },
    }

    local counterRowD = {
        type  = ui.TYPE.Flex,
        props = { horizontal = true, align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
        content = ui.content({ btnMinusD, counterBoxD, btnPlusD }),
    }

    local btnWait = {
        type     = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props    = { size = v2(110, 36), propagateEvents = false },
        content  = ui.content({
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
              props = { text = isRest and "Rest" or "Wait",
                        relativePosition = v2(.5,.5), anchor = v2(.5,.5), textSize = 16 } },
        }),
        events = {
            mousePress = async:callback(function()
                local h = daysToWait * 24 + hoursToWait
                local r = isRest
                closeWaitMenu()
                startWaiting(h, r)
            end),
        },
    }

    local btnCancel = {
        type     = ui.TYPE.Widget,
        template = I.MWUI.templates.borders,
        props    = { size = v2(110, 36), propagateEvents = false },
        content  = ui.content({
            { type = ui.TYPE.Text, template = I.MWUI.templates.textNormal,
              props = { text = "Cancel",
                        relativePosition = v2(.5,.5), anchor = v2(.5,.5), textSize = 16 } },
        }),
        events = {
            mousePress = async:callback(function()
                closeWaitMenu()
            end),
        },
    }

    local buttonsRow = {
        type  = ui.TYPE.Flex,
        props = { horizontal = true, align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
        content = ui.content({ btnWait, spacer, btnCancel }),
    }

    waitMenu = ui.create({
        type     = ui.TYPE.Container,
        layer    = 'Windows',
        template = I.MWUI.templates.boxTransparentThick,
        props    = {
            relativePosition = v2(.5, .5),
            anchor           = v2(.5, .5),
            propagateEvents  = false,
        },
        content = ui.content({
            {
                type  = ui.TYPE.Flex,
                props = { horizontal = false, align = ui.ALIGNMENT.Center,
                          arrange = ui.ALIGNMENT.Center },
                content = ui.content({
                    titleBox,
                    gap,
                    timeRow,
                    gap,
                    hoursLabel,
                    counterRowH,
                    gap,
                    daysLabel,
                    counterRowD,
                    gap,
                    buttonsRow,
                }),
            },
        }),
    })
end

local function onMouseButtonPress(button)
    if waitingActive and button == 3 then
        stopWaiting()
    end
end

local function onInputAction(id)
    if waitingActive then
        if id == input.ACTION.Inventory or id == input.ACTION.Journal then
            stopWaiting()
        end
		if id == input.ACTION.GameMenu then
			stopWaiting() end
        return
    end
    if menuOpen then
        if id == input.ACTION.Inventory or id == input.ACTION.Journal then
            closeWaitMenu()
        end	
		if id == input.ACTION.GameMenu then
			closeWaitMenu() end		
        return
    end

    if id == input.ACTION.Rest or id == input.ACTION.GameMenu then
        suppressRestMenu = true
        return
    end
end

local prevWayrestKey = false

local function onUpdate(dt)
    local mode = I.UI.getMode()
    if suppressRestMenu and mode == 'Rest' then
        I.UI.removeMode('Rest')
        suppressRestMenu = false
        openWaitUI(detectIsRest())
        prevWayrestKey = input.getBooleanActionValue('wayrestkey')
        return
    end
    if suppressRestMenu and mode ~= 'Rest' then
        prevWayrestKey = input.getBooleanActionValue('wayrestkey')
        return
    end

    local keyNow = input.getBooleanActionValue('wayrestkey')
    if keyNow and not prevWayrestKey then
        if waitingActive then
            stopWaiting()
        elseif menuOpen then
            closeWaitMenu()
        elseif not isMenuActive() then
            openWaitUI(detectIsRest())
        end
    end
    prevWayrestKey = keyNow

    if pendingAnimPlay then
        pendingAnimPlay = false
        playWaitAnim(isRest and CFG.restAnimGroup or CFG.waitAnimGroup)
    end

    if waitingActive then
        local realNow = core.getRealTime()
        local dur = currentHourDuration()
        if hourRealTimeStart and (realNow - hourRealTimeStart) >= dur then
            hourRealTimeStart = hourRealTimeStart + dur
            core.sendGlobalEvent('DWR_AdvanceOneHour', {})
            applyRestRecovery()
            hoursDone = hoursDone + 1
            if hoursDone >= totalHoursWait then
                stopWaiting()
            end
        end

        if cameraOffsetApplied then
            if savedCameraOffsets.fp ~= nil then
                local ok, cur = pcall(function() return camera.getFirstPersonOffset() end)
                if ok and cur then
                    local expected = savedCameraOffsets.fp + util.vector3(0, 0, CFG.cameraWaitZOffset)
                    if (cur - expected):length() > 1 then
                        pcall(function() camera.setFirstPersonOffset(expected) end)
                    end
                end
            end
            if savedCameraOffsets.focal ~= nil then
                local ok, cur = pcall(function() return camera.getFocalPreferredOffset() end)
                if ok and cur then
                    local expected = savedCameraOffsets.focal + util.vector2(0, CFG.cameraWaitZOffset * 13)
                    if (cur - expected):length() > 1 then
                        pcall(function() camera.setFocalPreferredOffset(expected) end)
                    end
                end
            end
        end

        if progressElem and waitingActive then
            local now = core.getRealTime()
            if (now - lastProgressUpdate) >= 0.1 then
                lastProgressUpdate = now
                local hourProgress = 0
                local d = currentHourDuration()
                if d > 0 then
                    hourProgress = math.min(1.0, (now - hourRealTimeStart) / d)
                end
                local ratio = math.min(1.0, (hoursDone + hourProgress) / totalHoursWait)
                createProgressUI(ratio)
            end
        end
        return
    end

    local simNow = core.getSimulationTime()
    if lastSimTime == nil then
        lastSimTime = simNow
        return
    end
    local simDelta = simNow - lastSimTime
    if dt > 0 and simDelta < dt * 0.1 then
        if not wasWaiting then
            wasWaiting = true
            playWaitAnim(isRest and CFG.restAnimGroup or CFG.waitAnimGroup)
        end
    else
        if wasWaiting then
            stopWaitAnim(isRest and CFG.restAnimGroup or CFG.waitAnimGroup)
            isRest     = false
            wasWaiting = false
        end
        lastSimTime = simNow
    end
end

local function onLoad()
    waitingActive         = false
    animPlaying           = false
    wasWaiting            = false
    menuOpen              = false
    isRest                = false
    hoursDone             = 0
    totalHoursWait        = 0
    currentDecay          = 1.0
    lastSimTime           = nil
    hourRealTimeStart     = nil
    waitRealStart         = nil
    cachedTotalRealDuration = 0
    lastProgressUpdate    = 0
    cameraOffsetApplied   = false
    savedCameraOffsets    = {}
    savedEquipment        = {}
    suppressRestMenu      = false
    pendingAnimPlay       = false
    destroyProgressUI()
    closeWaitMenu()
end

return {
    engineHandlers = {
        onKeyPress         = onKeyPress,
        onMouseButtonPress = onMouseButtonPress,
        onInputAction      = onInputAction,
        onUpdate           = onUpdate,
        onLoad             = onLoad,
    },

    eventHandlers = {
        DWR_ShowWaitUI = function(data)
            if isMenuActive() then return end
            local rest = (data and data.isRest ~= nil)
                         and data.isRest
                         or  detectIsRest()
            openWaitUI(rest)
        end,
        DWR_StopWaiting = function()
            stopWaiting()
        end,
        DWR_StopWaitAnim = function()
            stopWaitAnim(isRest and CFG.restAnimGroup or CFG.waitAnimGroup)
        end,
    },
}
