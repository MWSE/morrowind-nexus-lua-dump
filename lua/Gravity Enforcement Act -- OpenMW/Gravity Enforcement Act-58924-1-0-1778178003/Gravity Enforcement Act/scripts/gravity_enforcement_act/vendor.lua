local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')

local M = {}

local HARDCODED_VENDOR_MODES = {
    weak = {
        ['fanildil'] = true,
        ['nebia amphia'] = true,
        ['marayn dren'] = true,
    },
    telvanni = {
        ['fevyn ralen'] = true,
        ['arielle phiencel'] = true,
        ['heem_la'] = true,
    },
    master = {
        ['uvele berendas'] = true,
        ['salver lleran'] = true,
        ['namanian facian'] = true,
    },
}

local config = {
    enabled = true,
    interval = 2,
    debug = false,
    vanilla = {},
    weak = HARDCODED_VENDOR_MODES.weak,
    telvanni = HARDCODED_VENDOR_MODES.telvanni,
    master = HARDCODED_VENDOR_MODES.master,
    thinItems = true,
    maxPotions = 1,
    maxScrolls = 1,
    keepAtLeast = 1,
}

local patchTimer = 0
local removedLevitateSpellsByNpc = {}

local REPLACEMENT_SPELLS = {
    weak = 'pxm_gea_temp_levitate_010',
    telvanni = 'pxm_gea_temp_levitate_020',
    master = 'pxm_gea_temp_levitate_040',
}

local VANILLA_RESTORE_SPELLS = {
    'Levitate',
}

local function debugLog(msg)
    if config.debug then
        print('[GEA][Vendor] ' .. tostring(msg))
    end
end

local function normalizeId(value)
    if value == nil then
        return ''
    end
    return string.lower(tostring(value))
end

local function trim(s)
    return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function parseCsvSet(value)
    local result = {}
    if not value or value == '' then
        return result
    end

    for part in string.gmatch(tostring(value), '([^,]+)') do
        local v = trim(part)
        if v ~= '' then
            result[normalizeId(v)] = true
        end
    end

    return result
end

local function clampInterval(value)
    if type(value) ~= 'number' then
        value = tonumber(value) or 2
    end
    if value < 1 then return 1 end
    if value > 30 then return 30 end
    return value
end

function M.onUpdateConfig(data)
    data = data or {}

    config.enabled = data.enabled ~= false
    config.interval = clampInterval(data.interval or 2)
    config.debug = data.debug == true

    config.vanilla = parseCsvSet(data.vanillaNpcIds or '')
    config.weak = HARDCODED_VENDOR_MODES.weak
    config.telvanni = HARDCODED_VENDOR_MODES.telvanni
    config.master = HARDCODED_VENDOR_MODES.master
    config.thinItems = data.thinItems ~= false
    config.maxPotions = math.max(0, tonumber(data.maxPotions) or 1)
    config.maxScrolls = math.max(0, tonumber(data.maxScrolls) or 1)
    config.keepAtLeast = math.max(0, tonumber(data.keepAtLeast) or 1)

    -- Re-run quickly after settings change/update.
    patchTimer = 0

    debugLog('config updated: enabled=' .. tostring(config.enabled)
        .. ', interval=' .. tostring(config.interval)
        .. ', vanilla=' .. tostring(data.vanillaNpcIds or '')
        .. ', weak=hardcoded'
        .. ', telvanni=hardcoded'
        .. ', master=hardcoded')
end

local function extractRecordId(value)
    if value == nil then return '' end
    if type(value) == 'table' then
        if value.id ~= nil then return extractRecordId(value.id) end
        if value.recordId ~= nil then return extractRecordId(value.recordId) end
    end

    local s = tostring(value or '')
    local quoted = s:match('%["([^"]+)"%]')
    if quoted then return quoted end
    return s
end

local function getSpellRecord(spellOrId)
    local rawId = extractRecordId(spellOrId)
    local normalizedId = normalizeId(rawId)

    if normalizedId ~= '' and core.magic and core.magic.spells then
        if core.magic.spells.records then
            local ok, record = pcall(function() return core.magic.spells.records[rawId] end)
            if ok and record then return record, rawId end

            ok, record = pcall(function() return core.magic.spells.records[normalizedId] end)
            if ok and record then return record, rawId end
        end

        local ok, record = pcall(function() return core.magic.spells[rawId] end)
        if ok and record then return record, rawId end

        ok, record = pcall(function() return core.magic.spells[normalizedId] end)
        if ok and record then return record, rawId end
    end

    if type(spellOrId) == 'table' then
        return spellOrId, rawId
    end

    return nil, rawId
end

local function effectId(effect)
    if not effect then return '' end

    local candidates = {
        effect.id,
        effect.effectId,
        effect.magicEffectId,
        effect.effect,
        effect.type,
        effect.name,
    }

    if effect.type and type(effect.type) == 'table' then
        candidates[#candidates + 1] = effect.type.id
        candidates[#candidates + 1] = effect.type.name
    end

    for _, candidate in ipairs(candidates) do
        if candidate ~= nil then
            local id = normalizeId(extractRecordId(candidate))
            if id ~= '' then return id end
        end
    end

    return ''
end

local function hasLevitateEffect(spell)
    if not spell then return false end

    local record, rawId = getSpellRecord(spell)
    local rawIdText = tostring(rawId or '')
    local normalizedRawId = normalizeId(rawIdText)

    if record and record.effects then
        local effectCount = 0
        for _, eff in pairs(record.effects) do
            effectCount = effectCount + 1
            local eid = effectId(eff)
            debugLog('    effect scan: spell=' .. rawIdText .. ', effectId=' .. tostring(eid))

            if eid == 'levitate' or eid:find('levitate', 1, true) then
                debugLog('Levitate detected via EFFECT on spell=' .. rawIdText)
                return true
            end
        end

        debugLog('NO levitate effect found via EFFECT on spell=' .. rawIdText .. ', effectCount=' .. tostring(effectCount))
    else
        debugLog('NO effects table on resolved spell=' .. rawIdText .. ', record=' .. tostring(record))
    end

    if normalizedRawId:find('levitate', 1, true) then
        debugLog('Levitate detected via ID fallback on spell=' .. rawIdText)
        return true
    end

    if record and record.name and normalizeId(record.name):find('levitate', 1, true) then
        debugLog('Levitate detected via NAME fallback on spell=' .. rawIdText .. ', name=' .. tostring(record.name))
        return true
    end

    return false
end

local function getActorSpellEntries(spells)
    local result = {}
    if not spells then
        return result
    end

    if spells.getAll then
        local ok, all = pcall(function() return spells:getAll() end)
        if ok and all then
            for _, spell in pairs(all) do
                result[#result + 1] = spell
            end
            return result
        end
    end

    for _, spell in pairs(spells) do
        result[#result + 1] = spell
    end

    return result
end

local function actorOffersSpells(actor)
    if not actor or not actor:isValid() then
        return false
    end

    if not types.NPC.objectIsInstance(actor) then
        return false
    end

    local ok, record = pcall(function() return types.NPC.record(actor) end)
    if not ok or not record then
        return false
    end

    local services = record.servicesOffered
    if not services then
        return false
    end

    return services.Spells == true
        or services.spells == true
        or services.Spell == true
        or services.spell == true
end

local function actorOffersTrade(actor)
    if not actor or not actor:isValid() then
        return false
    end

    if not types.NPC.objectIsInstance(actor) then
        return false
    end

    local ok, record = pcall(function() return types.NPC.record(actor) end)
    if not ok or not record or not record.servicesOffered then
        return false
    end

    local services = record.servicesOffered
    return services.Potions == true
        or services.potions == true
        or services.MagicItems == true
        or services.magicItems == true
        or services.Books == true
        or services.books == true
        or services.Apparatus == true
        or services.apparatus == true
        or services.Ingredients == true
        or services.ingredients == true
        or services.Misc == true
        or services.misc == true
        or actorOffersSpells(actor)
end

local function vendorModeForNpc(npcId)
    if config.vanilla[npcId] then return 'vanilla' end
    if config.weak[npcId] then return 'weak' end
    if config.telvanni[npcId] then return 'telvanni' end
    if config.master[npcId] then return 'master' end
    return 'remove'
end

local function spellListHas(spells, spellId)
    if not spells or not spellId then
        return false
    end

    if spells.has then
        local ok, hasSpell = pcall(function() return spells:has(spellId) end)
        if ok then
            return hasSpell == true
        end
    end

    for _, entry in pairs(getActorSpellEntries(spells)) do
        local _, id = getSpellRecord(entry)
        if normalizeId(id) == normalizeId(spellId) then
            return true
        end
    end

    return false
end

local function safeRemoveSpell(spells, spellId)
    if not spells or not spellId or spellId == '' then
        return false
    end

    local ok, err = pcall(function() spells:remove(spellId) end)
    if not ok then
        debugLog('remove ERROR: spell=' .. tostring(spellId) .. ', err=' .. tostring(err))
    end
    return ok == true
end

local function safeAddSpell(spells, spellId)
    if not spells or not spellId or spellId == '' then
        return false
    end

    if spellListHas(spells, spellId) then
        return false
    end

    local ok, err = pcall(function() spells:add(spellId) end)
    if not ok then
        debugLog('add ERROR: spell=' .. tostring(spellId) .. ', err=' .. tostring(err))
    end
    return ok == true
end

local function rememberRemovedLevitateSpell(npcId, spellId)
    if npcId == '' or spellId == '' then
        return
    end

    if not removedLevitateSpellsByNpc[npcId] then
        removedLevitateSpellsByNpc[npcId] = {}
    end

    removedLevitateSpellsByNpc[npcId][spellId] = true
end

local function actorCurrentlyHasLevitateSpell(spells)
    for _, entry in pairs(getActorSpellEntries(spells)) do
        if hasLevitateEffect(entry) then
            return true
        end
    end
    return false
end

local function restoreVanillaVendorLevitate(npcId, spells)
    local addedCount = 0

    local remembered = removedLevitateSpellsByNpc[npcId]
    if remembered then
        for spellId in pairs(remembered) do
            debugLog('restore remembered attempt: npc=' .. npcId .. ', spell=' .. tostring(spellId))
            if safeAddSpell(spells, spellId) then
                addedCount = addedCount + 1
                debugLog('restore remembered OK: npc=' .. npcId .. ', spell=' .. tostring(spellId))
            else
                debugLog('restore remembered skipped/FAILED: npc=' .. npcId .. ', spell=' .. tostring(spellId))
            end
        end
    end

    if not actorCurrentlyHasLevitateSpell(spells) then
        for _, spellId in ipairs(VANILLA_RESTORE_SPELLS) do
            debugLog('restore fallback attempt: npc=' .. npcId .. ', spell=' .. tostring(spellId))
            if safeAddSpell(spells, spellId) then
                addedCount = addedCount + 1
                debugLog('restore fallback OK: npc=' .. npcId .. ', spell=' .. tostring(spellId))
            else
                debugLog('restore fallback skipped/FAILED: npc=' .. npcId .. ', spell=' .. tostring(spellId))
            end
        end
    else
        debugLog('restore fallback not needed: npc=' .. npcId .. ' already has a Levitate-effect spell')
    end

    debugLog('restore complete: npc=' .. npcId .. ', restoredCount=' .. tostring(addedCount))
end

local function patchVendorLevitate(actor)
    if not actor then
        return
    end
	
    local actorValid = false
    local okValid, validResult = pcall(function() return actor:isValid() end)
    if okValid then
        actorValid = validResult == true
    end

    local npcIdRaw = actor.recordId or 'nil'
    local npcId = normalizeId(npcIdRaw)

    if not actorValid then
        return
    end

    if not types.NPC.objectIsInstance(actor) then
        return
    end

    local vendor = actorOffersSpells(actor)
    if not vendor then
        return
    end

    debugLog('---- vendor patch cycle entry ----')
    debugLog('processing spell vendor: rawId=' .. tostring(npcIdRaw) .. ', normalizedId=' .. tostring(npcId))

    if npcId == '' then
        debugLog('empty NPC id -> skip')
        return
    end

    local mode = vendorModeForNpc(npcId)
    debugLog('resolved vendor mode=' .. tostring(mode))
	
    local spells = types.Actor.spells(actor)
    if not spells then
        debugLog('types.Actor.spells(actor) returned nil -> skip')
        return
    end

    local beforeEntries = getActorSpellEntries(spells)
    debugLog('spells BEFORE count=' .. tostring(#beforeEntries))
    for _, entry in pairs(beforeEntries) do
        local _, spellId = getSpellRecord(entry)
        local hasLev = hasLevitateEffect(entry)
        debugLog('  BEFORE spell=' .. tostring(spellId) .. ', hasLevitateEffect=' .. tostring(hasLev))
    end

    local removedSpells = {}
    local addedSpells = {}

	if mode == 'vanilla' then
		debugLog('mode=vanilla -> removing GEA replacements, then restoring vanilla/remembered levitate spells')

		for _, entry in pairs(beforeEntries) do
			local _, spellId = getSpellRecord(entry)

			for _, replId in pairs(REPLACEMENT_SPELLS) do
				if normalizeId(spellId) == normalizeId(replId) then
					debugLog('removing replacement in vanilla mode: npc=' .. npcId .. ', spell=' .. tostring(spellId))
					if safeRemoveSpell(spells, spellId) then
						table.insert(removedSpells, spellId)
						debugLog('remove OK: npc=' .. npcId .. ', spell=' .. tostring(spellId))
					end
					break
				end
			end
		end

		restoreVanillaVendorLevitate(npcId, spells)
	else
		debugLog('mode=' .. tostring(mode) .. ' -> removing all non-selected Levitate/replacement spells')

		local replacement = REPLACEMENT_SPELLS[mode]
		local hasSelectedReplacement = replacement and spellListHas(spells, replacement)

		for _, entry in pairs(beforeEntries) do
			local _, spellId = getSpellRecord(entry)
			local hasLev = hasLevitateEffect(entry)

			local isReplacementSpell = false
			for _, replId in pairs(REPLACEMENT_SPELLS) do
				if normalizeId(spellId) == normalizeId(replId) then
					isReplacementSpell = true
					break
				end
			end

			local isSelectedReplacement =
				replacement ~= nil
				and normalizeId(spellId) == normalizeId(replacement)

			if spellId ~= '' and (hasLev or isReplacementSpell) and not isSelectedReplacement then
				debugLog('attempting remove: npc=' .. npcId .. ', spell=' .. tostring(spellId))
				if safeRemoveSpell(spells, spellId) then
					if hasLev then
						rememberRemovedLevitateSpell(npcId, spellId)
					end
					table.insert(removedSpells, spellId)
					debugLog('remove OK: npc=' .. npcId .. ', spell=' .. tostring(spellId))
				else
					debugLog('remove FAILED: npc=' .. npcId .. ', spell=' .. tostring(spellId))
				end
			elseif isSelectedReplacement then
				debugLog('keeping selected replacement spell: npc=' .. npcId .. ', spell=' .. tostring(spellId))
			end
		end

		debugLog('replacement for mode=' .. tostring(mode) .. ' is ' .. tostring(replacement))

		if replacement then
			if hasSelectedReplacement then
				debugLog('skip add: already has selected replacement, npc=' .. npcId .. ', spell=' .. tostring(replacement))
			else
				debugLog('attempting add replacement: npc=' .. npcId .. ', spell=' .. tostring(replacement))
				if safeAddSpell(spells, replacement) then
					table.insert(addedSpells, replacement)
					debugLog('add OK: npc=' .. npcId .. ', spell=' .. tostring(replacement))
				else
					debugLog('add skipped/FAILED: npc=' .. npcId .. ', spell=' .. tostring(replacement) .. ', alreadyHas=' .. tostring(spellListHas(spells, replacement)))
				end
			end
		end
	end

    local afterEntries = getActorSpellEntries(spells)
    debugLog('spells AFTER count=' .. tostring(#afterEntries))
    for _, entry in pairs(afterEntries) do
        local _, spellId = getSpellRecord(entry)
        local hasLev = hasLevitateEffect(entry)
        debugLog('  AFTER spell=' .. tostring(spellId) .. ', hasLevitateEffect=' .. tostring(hasLev))
    end

    debugLog(string.format(
        'summary: npc=%s mode=%s removed=[%s] added=[%s]',
        npcId,
        tostring(mode),
        table.concat(removedSpells, ', '),
        table.concat(addedSpells, ', ')
    ))
end


local function inventoryEntries(actor)
    local okInv, inv = pcall(function() return types.Actor.inventory(actor) end)
    if not okInv or not inv then
        return {}
    end

    local okAll, all = pcall(function() return inv:getAll() end)
    if okAll and all then
        return all
    end

    return {}
end

local function recordHasLevitateEffect(record)
    if not record or not record.effects then
        return false
    end

    for _, eff in pairs(record.effects) do
        local eid = effectId(eff)
        if eid == 'levitate' or eid:find('levitate', 1, true) then
            return true
        end
    end

    return false
end

local function inventoryEntryObject(entry)
    if not entry then
        return nil
    end

    -- OpenMW inventory entries may wrap the actual object here.
    return entry.object or entry.item or entry
end

local function inventoryItemKind(item)
    if not item then
        return nil
    end

    local obj = inventoryEntryObject(item)
    local rawId = (obj and obj.recordId) or item.recordId or ''
    local rawName = (obj and obj.name) or item.name or ''

    local id = normalizeId(rawId)
    local name = normalizeId(rawName)
	
	if id:find('levitation', 1, true) or id:find('levitat', 1, true) or id == 'p_levitation_s' then
		debugLog('LEVITATION ID SEEN BY CLASSIFIER: id=' .. tostring(id) .. ', name=' .. tostring(name))
	end	

    -- IMPORTANT:
    -- Do ID/name fallback BEFORE record lookup.
    -- OpenMW inventory entries can expose recordId even when type.record() fails.
    if id:match('^p_levitation_')
        or id:find('levitat', 1, true)
        or name:find('rising force', 1, true)
        or name:find('levitation', 1, true)
        or name:find('levitate', 1, true)
    then
        return 'potion'
    end

    if id:match('^sc_') and (
        id:find('levitat', 1, true)
        or name:find('levitation', 1, true)
        or name:find('levitate', 1, true)
        or name:find('icarian flight', 1, true)
    ) then
        return 'scroll'
    end

    local record = nil
    local ok = false

    if item.type and item.type.record then
        ok, record = pcall(function() return item.type.record(item) end)
    end

    if not ok or not record then
        local obj = inventoryEntryObject(item)
        if obj and obj.type and obj.type.record then
            ok, record = pcall(function() return obj.type.record(obj) end)
        end
    end

    if not ok or not record then
        debugLog('INV classify failed: no record for item=' .. tostring(item.recordId))
        return nil
    end

	id = normalizeId(record.id or rawId)
	name = normalizeId(record.name or rawName)

    -- Potions: vanilla ID/name fallback + modded effect fallback.
    if id:match('^p_') then
        if recordHasLevitateEffect(record)
            or id:match('^p_levitation_')
            or id:find('levitat', 1, true)
            or name:find('rising force', 1, true)
            or name:find('levitation', 1, true)
            or name:find('levitate', 1, true)
        then
            return 'potion'
        end
    end

    -- Scrolls: vanilla scroll ID/name fallback + modded effect fallback.
    if id:match('^sc_')
        or record.isScroll == true
        or record.scroll == true
        or record.type == 'Scroll'
    then
        if recordHasLevitateEffect(record)
            or id:find('levitat', 1, true)
            or name:find('levitation', 1, true)
            or name:find('levitate', 1, true)
            or name:find('icarian flight', 1, true)
        then
            return 'scroll'
        end
    end

    return nil
end

local function safeRemoveItemCount(item, count)
    if not item or not count or count <= 0 then
        return false
    end

    local obj = inventoryEntryObject(item)

    local ok = pcall(function() item:remove(count) end)
    if ok then return true end

    if obj and obj ~= item then
        ok = pcall(function() obj:remove(count) end)
        if ok then return true end
    end

    ok = pcall(function() item:remove() end)
    if ok then return true end

    if obj and obj ~= item then
        ok = pcall(function() obj:remove() end)
        if ok then return true end
    end

    return false
end

local function thinLevitationItemsForVendor(actor)
    if not config.thinItems then
        return
    end

    if not actorOffersTrade(actor) then
        return
    end
	
	local npcId = normalizeId(actor.recordId or '')
	debugLog('---- vendor item thinning entry: npc=' .. tostring(npcId) .. ' ----')

    local totals = { potion = 0, scroll = 0 }
    local entries = { potion = {}, scroll = {} }

    for _, item in pairs(inventoryEntries(actor)) do
        local kind = inventoryItemKind(item)
		
		local obj = inventoryEntryObject(item)
		local rid = obj and (obj.recordId or (obj.record and obj.record.id)) or 'nil'

		debugLog('INV scan: npc=' .. tostring(npcId)
			.. ', item=' .. tostring(rid)
			.. ', kind=' .. tostring(kind)
			.. ', count=' .. tostring(item.count or 1))	
		
        if kind then
            local count = item.count or 1
            totals[kind] = totals[kind] + count
            table.insert(entries[kind], item)
        end
    end

    local limits = {
        potion = math.max(config.keepAtLeast, config.maxPotions),
        scroll = math.max(config.keepAtLeast, config.maxScrolls),
    }

    for kind, list in pairs(entries) do
        local excess = totals[kind] - limits[kind]

        if excess > 0 then
            debugLog('thinning levitation ' .. kind .. ' inventory: excess=' .. tostring(excess))
            for _, item in ipairs(list) do
                if excess <= 0 then
                    break
                end

                local count = item.count or 1
                local removeCount = math.min(count, excess)
				
				local obj = inventoryEntryObject(item)
				local rid = obj and (obj.recordId or (obj.record and obj.record.id)) or 'nil'
				debugLog('REMOVING: item=' .. tostring(rid) .. ', removeCount=' .. tostring(removeCount))

                if safeRemoveItemCount(item, removeCount) then
                    excess = excess - removeCount
                end
            end
        end
    end
end

local function thinLevitationItemsInNearbyContainersForVendor(actor)
    if not config.thinItems then
        return
    end

    if not actor or not actor:isValid() or not actorOffersTrade(actor) then
        return
    end

    local npcId = normalizeId(actor.recordId or '')
    debugLog('container thinning entry: npc=' .. tostring(npcId))

    local cell = actor.cell
    if not cell then
        debugLog('container thinning skipped: no cell for npc=' .. tostring(npcId))
        return
    end

    local okObjects, objects = pcall(function()
        return cell:getAll()
    end)

    if not okObjects or not objects then
        debugLog('cell:getAll failed for npc=' .. tostring(npcId))
        return
    end

    local seen = 0
    local seenContainers = 0

    for _, obj in pairs(objects) do
        seen = seen + 1

        local isContainer =
            obj
            and obj:isValid()
            and types.Container
            and types.Container.objectIsInstance(obj)

        if isContainer then
            seenContainers = seenContainers + 1

            local containerId = normalizeId(obj.recordId or '')

            debugLog('scanning container: npc='
                .. tostring(npcId)
                .. ', container=' .. tostring(containerId))

            local okContent, content = pcall(function()
                return types.Container.inventory(obj) -- IMPORTANT FIX
            end)

            if not okContent or not content then
                debugLog('container inventory unavailable: ' .. tostring(containerId))
            else
                local okAll, all = pcall(function()
                    return content:getAll()
                end)

                if not okAll or not all then
                    debugLog('container getAll failed: ' .. tostring(containerId))
                else
                    for _, item in pairs(all) do
                        local kind = inventoryItemKind(item)
                        local objItem = inventoryEntryObject(item)
                        local itemId = objItem and objItem.recordId or item.recordId or 'nil'

                        debugLog('CONTAINER item: npc='
                            .. tostring(npcId)
                            .. ', container=' .. tostring(containerId)
                            .. ', item=' .. tostring(itemId)
                            .. ', kind=' .. tostring(kind)
                            .. ', count=' .. tostring(item.count or 1))

                        if kind == 'potion' or kind == 'scroll' then
                            debugLog('REMOVING from container: '
                                .. tostring(itemId))

                            safeRemoveItemCount(item, item.count or 1)
                        end
                    end
                end
            end
        end
    end

    debugLog('container thinning complete: npc=' .. tostring(npcId)
        .. ', objects=' .. tostring(seen)
        .. ', containers=' .. tostring(seenContainers))
end

local function patchActiveVendorLevitateSpells()
    if not config.enabled then
        return
    end

    if not world.activeActors then
        debugLog('world.activeActors is nil; cannot scan vendors')
        return
    end

	for _, actor in pairs(world.activeActors) do
		patchVendorLevitate(actor)
		thinLevitationItemsForVendor(actor)
		thinLevitationItemsInNearbyContainersForVendor(actor)
	end
end

function M.onUpdate(dt)
    patchTimer = patchTimer - dt
    if patchTimer > 0 then
        return
    end

    patchTimer = clampInterval(config.interval)
    debugLog('vendor scan tick')
    patchActiveVendorLevitateSpells()
end

return M
