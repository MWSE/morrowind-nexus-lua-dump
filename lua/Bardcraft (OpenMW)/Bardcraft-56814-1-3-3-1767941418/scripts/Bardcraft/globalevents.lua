local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local storage = require('openmw.storage')
local vfs = require('openmw.vfs')
local markup = require('openmw.markup')
local I = require('openmw.interfaces')

local time = require('openmw_aux.time')

local MIDI = require('scripts.Bardcraft.util.midi')
local Song = require('scripts.Bardcraft.util.song').Song
local Data = require('scripts.Bardcraft.data.common')
Data.BardNpcs = require('scripts.Bardcraft.data.bardNpcs')
local random = require('scripts.Bardcraft.util.random')
local Cell = require('scripts.Bardcraft.cell')
local Helpers = require('scripts.Bardcraft.util.helpers')

local function parseAllPreset()
    local metadataPath = 'midi/Bardcraft/preset/metadata.yaml'
    local exists = vfs.fileExists(metadataPath)
    local metadata = exists and markup.loadYaml(metadataPath) or {
        midiData = {}
    }
    if not exists then
        print("WARNING: metadata.yaml missing")
    end

    local bardData = storage.globalSection('Bardcraft')
    if bardData:get('version') ~= Data.Version then
        print("Bardcraft version mismatch: " .. tostring(bardData:get('version')) .. " => " .. tostring(Data.Version) .. ". Re-parsing preset songs.")
        bardData:set('version', Data.Version)
        bardData:set('songs/preset', nil) -- Clear the old data
    end
    local storedSongs = bardData:getCopy('songs/preset') or {}

    local midiSongs = {}
    for filePath in vfs.pathsWithPrefix(MIDI.MidiParser.presetFolder) do
        if filePath:sub(-4) == ".mid" then
            local fileName = string.match(filePath, "([^/]+)$")

            local alreadyParsed = false
            for _, song in pairs(storedSongs) do
                if song.sourceFile == fileName then
                    alreadyParsed = true
                    break
                end
            end

            if not alreadyParsed then
                local parser = MIDI.ParseMidiFile(filePath)
                if parser then
                    local song = Song.fromMidiParser(parser, metadata.midiData[fileName])
                    song.isPreset = true
                    midiSongs[fileName] = song
                end
            end
        end
    end
    for _, song in pairs(midiSongs) do
        table.insert(storedSongs, song)
    end
    bardData:set('songs/preset', storedSongs)

    local feedbackPath = 'scripts/Bardcraft/feedback.yaml'
    exists = vfs.fileExists(feedbackPath)
    local feedback = exists and markup.loadYaml(feedbackPath) or {}
    if not exists then
        print("WARNING: feedback.yaml missing")
    elseif feedback then
        bardData:set('feedback', feedback)
    end
end

local mwscriptQueue = {}

local function sendHome(actor)
    local bardInfo = Data.BardNpcs[actor.recordId]
    local home = bardInfo and bardInfo.home
    if home then
        -- Check for compat overrides
        local compatHome = nil
        if bardInfo.compat then
            local activeFiles = core.contentFiles.list
            for _, compat in ipairs(bardInfo.compat) do
                for _, fileStr in ipairs(compat.files or {}) do
                    for _, activeFile in ipairs(activeFiles) do
                        if string.find(string.lower(activeFile), string.lower(fileStr), 1, true) then
                            compatHome = compat
                            break
                        end
                    end
                    if compatHome then break end
                end
                if compatHome then break end
            end
        end
        if compatHome then
            actor:teleport(home.cell, compatHome.position, compatHome.rotation)
            return true
        else
            actor:teleport(home.cell, home.position, home.rotation)
            return true
        end
    end
    return false
end

I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
    if actor.type ~= types.Player then return true end
    local record = item.type.record(item)
    for instr, _ in pairs(Data.SheathableInstruments) do
        for recordId, _ in pairs(Data.InstrumentItems[instr]) do
            if record.id == recordId then
                actor:sendEvent('BC_SheatheInstrument', { recordId = recordId, })
                return true
            end
        end
    end
    return true
end)

local teleportProcessedThisFrame = false

-- ================= Merchants =================

local INSTRUMENT_TYPES = {
    Universal = {
        t_com_lute_01 = true,
        r_bc_ocarina = true,
        misc_de_drum_01 = true,
    },
    DunmerGeneric = {
        misc_de_lute_01 = true,
        misc_de_drum_02 = true,
        t_de_music_adun = true,
    },
    DunmerAshlander = {
        r_bc_bassflute = true,
    },
    DunmerShinathi = {
        t_de_music_shiratar = true,
    },
    ImperialGeneric = {
        t_imp_lute_01 = true,
        r_bc_fiddle = true,
        t_imp_drum_01 = true,
        t_imp_drum_02 = true,
        t_imp_drum_03 = true,
        t_imp_drum_04 = true,
    }
}

local REGION_FILTERS = {
    Universal = function() return true end,
    DunmerGeneric = function(_, hierarchy) return hierarchy.province == 'Morrowind' end,
    DunmerAshlander = function(_, hierarchy) return hierarchy.district == 'Vvardenfell Ashlands' or hierarchy.district == 'Eastern Vvardenfell' end,
    DunmerShinathi = function(_, hierarchy) return hierarchy.region == 'shipal-shin region' end,
    ImperialGeneric = function(cell, hierarchy) return hierarchy.province == 'Cyrodiil' or Cell.isImperialTown(cell) end,
}

-- NPC class must match one of these to be considered an instrument seller
local INSTRUMENT_SELLERS = {
    ['merchant'] = {
        minRestock = 2,
        maxRestock = 4,
    },
    ['pawnbroker'] = {
        minRestock = 1,
        maxRestock = 4,
    },
    ['trader'] = {
        minRestock = 3,
        maxRestock = 5,
    },
    ['trader service'] = {
        minRestock = 3,
        maxRestock = 5,
    },
    -- ['wise woman service'] = { -- wise women don't trade misc items :(
    --     minRestock = 1,
    --     maxRestock = 3,
    --     allowedTypes = {
    --         DunmerAshlander = true,
    --     }
    -- },
    ['t_glb_trader'] = {
        minRestock = 3,
        maxRestock = 5,
    },
    ['t_glb_traderservice'] = {
        minRestock = 3,
        maxRestock = 5,
    },
}

-- Cell name must match one of these patterns to be considered a valid instrument seller
local SELLER_CELL_FILTER = {
    'General',
    'Trader',
    'Tradehouse',
    'Outfitter',
    'Pawn',
    'Broker',
    'Music',
    'Instrument',
    'Miscellan',
    'Furnisher',
    'Sundries',
}

-- Manual list for NPCs in cells not matching a pattern, but who should still stock instruments
local EXEMPT_NPCS = Helpers.toLookup({
    -- TR
    'givesa feran',
    'miaren drothan',
    'tamas calisan',
    'dartha nandilos',
    'brelerun overin',
    'tumsa llethan',
    'aleni moryon',
    'caius milacio',
    'dareth rarales',
    'dravos turil',
    'ondres bethryon',
    'tirvel bethrano',
    'onnurdil',
    'kovan ralethran',
    'ruram salothran',
    'anjzhirra',
    'cirtiel',
    'emercius ludoviil',
    'zali-hunittu',
    'volene dorvaso',
    'milesi herethran',
    -- Cyrodiil
    'corethyn surano',
    'kulsora',
    'za\'taba',
    'alona',
    'caltierra sivus',
    'faustina cartia',
    'harrold',
    'mason',
    'swan',
    'varria arlusa',
    -- Skyrim
    'baorimac',
    'julas percio',
    'nirya',
})

local BOOK_SELLERS = Helpers.toLookup({
    'bookseller',
    't_glb_bookseller',
})

local RESTOCK_INTERVAL = 14 * time.day

local function doRestock(data)
    local currentTime = core.getGameTime()
    local lastRestockTime = data.lastRestockTime
    local lastRestockItems = data.lastRestockItems
    local self = data.actor
    if lastRestockTime and currentTime - lastRestockTime < RESTOCK_INTERVAL then
        return
    end

    for recordId, count in pairs(lastRestockItems) do
        for _, item in ipairs(self.type.inventory(self):findAll(recordId)) do
            if count <= 0 then break end
            item:remove(1)
            count = count - 1
        end
    end

    lastRestockTime = currentTime
    lastRestockItems = {}

    local cell = self.cell
    if not cell then return end
    local hierarchy = Cell.getRegionHierarchy(cell)
    if not hierarchy then return end

    local record = self.type.record(self)
    local class = record.class
    local merchantData = INSTRUMENT_SELLERS[class]
    if merchantData and record.servicesOffered['Misc'] and (EXEMPT_NPCS[string.lower(record.name)] or Helpers.matchesAny(cell.name, SELLER_CELL_FILTER)) then
        local possibleInstruments = {}
        for instrumentType, filterFunc in pairs(REGION_FILTERS) do
            if (not merchantData.allowedTypes) or merchantData.allowedTypes[instrumentType] then
                if filterFunc(cell, hierarchy) then
                    for recordId, _ in pairs(INSTRUMENT_TYPES[instrumentType]) do
                        if types.Miscellaneous.records[recordId] or types.Weapon.records[recordId] then
                            if not self.type.inventory(self):find(recordId) then
                                table.insert(possibleInstruments, recordId)
                            end
                        end
                    end
                end
            end
        end

        local numToRestock = math.random(merchantData.minRestock, merchantData.maxRestock)
        for i = 1, numToRestock do
            if #possibleInstruments == 0 then break end
            local choice = table.remove(possibleInstruments, math.random(#possibleInstruments))
            lastRestockItems[choice] = (lastRestockItems[choice] or 0) + 1
        end
    end

    if BOOK_SELLERS[class] and record.servicesOffered['Books'] then
        lastRestockItems['r_bc_sheetmusic_blank'] = 500
        lastRestockItems['r_bc_songbook_beg'] = 1
        if math.random() < 0.25 then
            lastRestockItems['r_bc_songbook_int'] = 1
        end
    end

    for recordId, count in pairs(lastRestockItems) do
        local item = world.createObject(recordId, count)
        item:moveInto(self.type.inventory(self))
        print(string.format("Restocked %d of %s to %s", count, recordId, self.recordId))
    end

    self:sendEvent('BC_RestockHandled', { lastRestockTime = lastRestockTime, lastRestockItems = lastRestockItems })
end

return {
    engineHandlers = {
        --onInit = parseAll,
        onUpdate = function(dt)
            if dt == 0 then return end

            if #mwscriptQueue > 0 then
                for _, data in ipairs(mwscriptQueue) do
                    local item = data.object
                    local mwscript = world.mwscript.getLocalScript(item)
                    if mwscript then
                        mwscript.variables.hasbeenplayed = data.hasBeenPlayed or 0
                        mwscript.variables.songid = data.songId or 0
                    end
                end
                mwscriptQueue = {}
            end
            if teleportProcessedThisFrame then
                core.sendGlobalEvent('BC_RecheckTroupe')
                teleportProcessedThisFrame = false
            end
        end
    },
    eventHandlers = {
        BC_ClearGlobalData = function()
            local bardData = storage.globalSection('Bardcraft')
            bardData:set('songs/preset', nil)
        end,
        BC_RecheckTroupe = function(data)
            local player = data and data.player or world.players[1]
            if not player then return end

            local troupeMembers = {}
            for _, actor in ipairs(world.activeActors) do
                if not actor.type.isDead(actor) then
                    local mwscript = world.mwscript.getLocalScript(actor)
                    if mwscript and mwscript.recordId == "_bchireablebard" then
                        if mwscript.variables.followplayer == 1 then
                            table.insert(troupeMembers, actor)
                        end
                        if mwscript.variables.tphome == 1 then
                            mwscript.variables.tphome = 0
                            if sendHome(actor) then
                                player:sendEvent('BC_TPFadeIn')
                                player:sendEvent('AttendMeFollowerStatus', { -- Attend Me compatibility
                                    actor = actor,
                                    status = false,
                                }) 
                            end
                        end
                    end
                end
            end

            player:sendEvent("BC_TroupeStatus", { members = troupeMembers })
        end,
        AttendMeTeleport = function()
            teleportProcessedThisFrame = true
        end,
        BC_SendHome = function(data)
            if not data or not data.actor then return end
            sendHome(data.actor)
        end,
        BC_GiveItem = function(data)
            if not data then return end
            local item = world.createObject(data.item, data.count or 1)
            item:moveInto(types.Actor.inventory(data.actor))
        end,
        BC_ConsumeItem = function(data)
            if not data then return end
            data.item:remove(data.count)
        end,
        BC_ParseMidis = function(data)
            if data and data.force then
                local bardData = storage.globalSection('Bardcraft')
                bardData:set('songs/preset', nil) -- Clear the old data
            end
            parseAllPreset()
            for _, player in ipairs(world.players) do
                player:sendEvent('BC_MidisParsed')
            end
        end,
        BC_Trespass = function(data)
            if not data then return end
            I.Crimes.commitCrime(data.player, {
                type = types.Player.OFFENSE_TYPE.Trespassing,
            })
        end,
        BC_BookRead = function(data)
            if not data then return end
            local book = data.book
            if not book then return end

            local mwscript = world.mwscript.getLocalScript(book)
            if not mwscript or mwscript.recordId ~= '_bcsheetmusic' then 
                data.player:sendEvent('BC_BookReadResult', { id = book.recordId, success = true })
                return 
            end
            if not mwscript.variables.hasbeenread or mwscript.variables.hasbeenread == 0 then
                mwscript.variables.hasbeenread = 1
                data.player:sendEvent('BC_BookReadResult', { id = book.recordId, success = true })
            else
                data.player:sendEvent('BC_BookReadResult', { success = false })
            end
        end,
        BC_ReplaceMusicBox = function(data)
            if not data then return end
            local object = data.object
            if not object or data.object.type ~= types.Miscellaneous then return end
            if data.object.count < 1 then return end
            if not object.cell then return end

            local mwscript = world.mwscript.getLocalScript(object)
            local hasBeenPlayed = mwscript.variables.hasbeenplayed or 0
            local songId = mwscript.variables.songid or 0

            local activatorId = object.recordId .. '_a'
            local activator = world.createObject(activatorId, 1)
            activator:teleport(object.cell, object.position, object.rotation)
            activator:sendEvent('BC_MusicBoxInit', { hasBeenPlayed = hasBeenPlayed, songId = songId, playerPlaced = true })
            object:remove()
        end,
        BC_PruneMusicBox = function(data)
            if not data then return end
            local object = data.object
            if not object or object.type ~= types.Activator then return end

            local globalVars = world.mwscript.getGlobalVariables()
            if not globalVars.bcInitTime or globalVars.bcInitTime == 0 then
                globalVars.bcInitTime = math.floor(core.getRealTime() * 1000)
                print("Bardcraft global seed set to: " .. globalVars.bcInitTime)
            end

            local cellName = object.cell and object.cell.name or "UnknownCell"
            local position = object.position
            local hashInput = string.format("%s_%.0f_%.0f_%.0f", cellName, position.x, position.y, position.z)
            local randomValue = random.hashStringToUnitFloat(globalVars.bcInitTime, hashInput)
            local record = Data.MusicBoxes[object.recordId]
            local spawnChance = record and record.spawnChance or 0.5

            if randomValue > spawnChance then
                object:remove()
            end
        end,
        BC_MusicBoxPickup = function(data)
            local object = data.object
            if object.type ~= types.Activator then return end

            local itemId = object.recordId:sub(1, -3)
            local item = world.createObject(itemId, 1)
            local value = item.type.record(item).value
            local owner = object.owner
            if owner.factionId or owner.recordId then
                I.Crimes.commitCrime(data.actor, {
                    arg = value,
                    type = types.Player.OFFENSE_TYPE.Theft,
                    faction = owner.factionId,
                })
            end
            item.owner.factionId = object.owner.factionId
            item.owner.factionRank = object.owner.factionRank
            item.owner.recordId = object.owner.recordId

            table.insert(mwscriptQueue, {
                object = item,
                hasBeenPlayed = data.hasBeenPlayed or 0,
                songId = data.songId or 0,
            })

            item:moveInto(types.Actor.inventory(data.actor))
            object:remove()
        end,
        BC_SetCreationTime = function()
            local globalVars = world.mwscript.getGlobalVariables()
            if not globalVars.bcInitTime or globalVars.bcInitTime == 0 then
                globalVars.bcInitTime = math.floor(core.getRealTime() * 1000)
                print("Bardcraft global seed set to: " .. globalVars.bcInitTime)
            end
        end,
        BC_HandleRestock = doRestock,
    }
}