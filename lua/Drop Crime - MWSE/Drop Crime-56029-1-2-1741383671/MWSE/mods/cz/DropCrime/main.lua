local config = require("cz.DropCrime.config")

local function isDwemer(item)
    if not config.contrabandDwemer then return false end
    if string.find(item.id, "dwrv")
    or string.find(item.id, "dwemer")
    or string.find(item.id, "dwarven")
    or string.find(item.id, "AB_*_dw")
    or string.startswith(item.id, "T_Dwe_") then
        if config.contrabandDwemerNoGear then
            if item.objectType == tes3.objectType.armor or item.objectType == tes3.objectType.weapon then
                return false
            end
        end
        return true
    end
    return false
end

local function isEbony(item)
    if not config.contrabandEbony then return false end
    if string.find(item.id, "raw_ebony") then return true end
    return false
end

local function isGlass(item)
    if not config.contrabandGlass then return false end
    if string.find(item.id, "raw_glass") then return true end
    return false
end

local function isContraband(item)
    if config.notContrabandList[item.id:lower()] then return false end
    if config.contrabandList[item.id:lower()] then return true end
    return false
end

local function isSkooma(item)
    if string.find(item.id, "skooma") or string.find(item.id, "sugar") then return true end
    return false
end

local function isSmuggler(actor)
    if config.smugglerList[actor.id:lower()] then return true end
    if actor.class.id == "Smuggler"
    or actor.class.id == "Necromancer"
    or (actor.faction and (actor.faction.id == "Thieves Guild"
                        or actor.faction.id == "Camonna Tong"
                        or actor.faction.id == "Ashlanders"
                        or actor.faction.id == "Telvanni"
                        or actor.faction.id == "T_Cyr_ThievesGuild"
                        or actor.faction.id == "T_Sky_ThievesGuild"
                        or actor.faction.id == "Twin Lamps")) then return true end
    return false
end

local function isGuard(actor)
    if not config.guardsOnly then return true end
    if actor.object.aiConfig.alarm < 100 then return false end     -- close enough
    return true
end

---@param actor tes3npc
local function isKhajiit(actor)
    if string.startswith(actor.race.id, "T_Els") or actor.race.id == "Khajiit" then return true end
    return false
end

-- Copied from abot smart companions
local function getRefVariable(ref, var)
    local script = ref.object.script
	if not script then
		return nil
	end
	local script_context = script['context']
	if not script_context then
		return nil
	end

	if ref.attachments then
		if ref.attachments.variables then
			if not ref.attachments.variables.script then
				return nil
			end
		else
			return nil
		end
	else
		return nil
	end

-- WARNING!!!
-- ref.object.script.context.variable is only safe to use to detect if variable exists,
-- not to get/set its value!!!

	local success, value = pcall(
		function ()
			return script_context[var]
		end
	)
	if not (success and value) then
		return nil
	end

	local ref_context = ref['context']
	if not ref_context then
		return value
	end

	-- need more safety
	local val = ref_context[var]
	if not val then
		return value
	end
end

-- Copied from abot smart companions
local function getCompanionVar(ref)
	local result = getRefVariable(ref, 'companion')
	return result
end

-- Copied from abot smart companions
local function isCompanion(ref)
	local result = false
	local companion = getCompanionVar(ref)
	if companion
	and (companion == 1) then
		result = true
	end
	return result
end

---@param e itemDroppedEventData
local function onItemDrop(e)
    if not config.enabled then return end

    local droppedItem = e.reference.object

    if isDwemer(droppedItem) or isEbony(droppedItem) or isGlass(droppedItem) or isContraband(droppedItem) then
        local witnesses = {}

        -- Splitting into multiple ifs because otherwise errors out??
        for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
            if not ref.isDead  then
                if not isSmuggler(ref.baseObject) then
                    if not isCompanion(ref) then
                        if isGuard(ref) then
                            if tes3.testLineOfSight { reference1 = ref, reference2 = tes3.player } then
                                if not isKhajiit(ref.object) or not isSkooma(droppedItem) then   -- khajiit shouldn't care if you grab it
                                    table.insert(witnesses, ref)
                                end
                            end
                        end
                    end
                end
            end
        end

        if #witnesses > 0 then
            timer.frame.delayOneFrame(
                function()
                    tes3.triggerCrime({ type = tes3.crimeType.theft, victim = witnesses[1], value = droppedItem.value })
                end
            )
        end
    end
end

---@param e activateEventData
local function onItemPickup(e)
    if e.activator ~= tes3.player then return end

    if not config.enabled then return end

    local pickedItem = e.target.object

    if pickedItem.objectType == tes3.objectType.activator
    or pickedItem.objectType == tes3.objectType.container
    or pickedItem.objectType == tes3.objectType.door
    or pickedItem.objectType == tes3.objectType.mobileActor
    then return end

    if isDwemer(pickedItem) or isEbony(pickedItem) or isGlass(pickedItem) or isContraband(pickedItem) then
        local witnesses = {}

        -- Splitting into multiple ifs because otherwise errors out??
        for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
            if not ref.isDead  then
                if not isSmuggler(ref.baseObject) then
                    if not isCompanion(ref) then
                        if isGuard(ref) then
                            if tes3.testLineOfSight { reference1 = ref, reference2 = tes3.player } then
                                if not isKhajiit(ref.object) or not isSkooma(pickedItem) then   -- khajiit shouldn't care if you grab it
                                    table.insert(witnesses, ref)
                                end
                            end
                        end
                    end
                end
            end
        end

        if #witnesses > 0 then
            timer.frame.delayOneFrame(
                function()
                    tes3.triggerCrime({ type = tes3.crimeType.theft, victim = witnesses[1], value = pickedItem.value })
                end
            )
        end
    end
end

local function onInitialized()
    event.register("itemDropped", onItemDrop)
    event.register("activate", onItemPickup)
    mwse.log("[Drop Crime] initialized")
end
event.register("initialized", onInitialized)
event.register("modConfigReady", function() mwse.mcm.register(require("cz.DropCrime.mcm")) end)