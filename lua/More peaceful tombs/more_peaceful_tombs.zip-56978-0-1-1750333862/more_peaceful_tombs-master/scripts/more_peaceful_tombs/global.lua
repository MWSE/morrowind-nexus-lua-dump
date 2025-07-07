local types = require('openmw.types')
local NPC = types.NPC
local Door = types.Door
local core = require('openmw.core')
local storage = require('openmw.storage')
local aux_util = require('openmw_aux.util')
local I = require('openmw.interfaces')
local world = require('openmw.world')

local settings = storage.globalSection('Settings_more_peaceful_tombs')

local FACTIONS = {
    -- vanilla
    'temple',

    -- Join The Dissident Priests
    'dissident priests',
}
--local PLAYER_CACHE = {}
local TR_QUEST = 'TR_m3_TT_Speaker' -- Tamriel Rebuilt:Speaker for the Dead
local TR_QUEST_MIN = 30 -- I have performed the sacred ritual and received the title of "Speaker for the Dead" ...
local TR_QUEST_MAX = 100 -- My tenure as a Speaker for the Dead has ended. I no longer bear this sacred burden.
local TR_QUEST_NOPE = 150 -- Because of my conduct, Uvo Brin discharged me from the order of Speakers.
                          -- OR I banished Uvo Brin, the leader of the Speakers for the Dead. I have been expelled from the order.

local CREATURES_WHITELIST = {
}
local CREATURES_CACHE = {}

local CELL_WHITELIST = {
}
local CELL_BLACKLIST = {
}
local CELL_CACHE = {}

local help = [[
    add_creature(arg): Adds a creature regex to the list.

    display_creatures: Prints all registered creatures.

    add_cell_wl(arg): Adds a cell whitelist regex to the list.

    display_cell_wl: Prints cell whitelist.

    add_cell_bl(arg): Adds a cell blacklist regex to the list.

    display_cell_bl: Prints cell blacklist.
]]

local function check_creature(id)
    is_debug = settings:get('is_debug')

    if CREATURES_CACHE[id] ~= nil then
        return CREATURES_CACHE[id]
    end
    is_matched = false
    for i, c in ipairs(I.more_peaceful_tombs.get_creatures)
    do
        if id == string.match(id, c) then
            is_matched = true
            break
        end
    end
    CREATURES_CACHE[id] = is_matched

    if is_debug then
        if is_matched then
            print("creature " .. id .. " is whitelisted")
        end
    end

    return CREATURES_CACHE[id]
end

local function check_cell_interior(cell)
    cell_id = cell.id
    
    is_debug = settings:get('is_debug')

    -- additional cache check
    if CELL_CACHE[cell_id] ~= nil then
        return CELL_CACHE[cell_id]
    end

    blacklisted_cell = false
    for i, c in ipairs(I.more_peaceful_tombs.get_cell_bl)
    do
        if cell_id == string.match(cell_id, c) then
            blacklisted_cell = true
            break
        end
    end
    if blacklisted_cell then
        if is_debug then
            print("cell " .. cell_id .. " is blacklisted")
        end
        CELL_CACHE[cell_id] = false
        return false
    end

    whitelisted_cell = false
    for i, c in ipairs(I.more_peaceful_tombs.get_cell_wl) 
    do
        if cell_id == string.match(cell_id, c) then
            whitelisted_cell = true
            break
        end
    end
    CELL_CACHE[cell_id] = whitelisted_cell
    if whitelisted_cell then
        if is_debug then
            print("cell " .. cell_id .. " is whitelisted")
        end
        return true
    else
        return false
    end
end

local function check_cell_exterior(cell)
    -- finding a door leading to a suitable (interior) tomb, essentially

    is_debug = settings:get('is_debug')

    found_door = false

    for i, d in ipairs(cell:getAll(Door))
    do
        c = Door.destCell(d)
        if not c.isExterior then
            if check_cell_interior(c) then
                found_door = true
                break
            end
        end
    end

    return found_door
end

local function check_cell(cell)
    cell_id = cell.id
    if CELL_CACHE[cell_id] ~= nil then
        return CELL_CACHE[cell_id]
    end

    is_check = nil
    if cell.isExterior then
        is_check = check_cell_exterior(cell)
    else
        is_check = check_cell_interior(cell)
    end

    if true then
        CELL_CACHE[cell_id] = is_check
    end

    return is_check
end

local function check_player_rank(player)
    min_rank = settings:get('min_rank') + 1

    is_pacified = false
    for i, faction_string in ipairs(FACTIONS)
    do
        if is_pacified then
            break
        end
        for j, faction in ipairs(NPC.getFactions(player))
        do
            if faction == string.match(faction, faction_string) then
                if (not NPC.isExpelled(player, faction)) and (NPC.getFactionRank(player, faction) >= min_rank) then
                    is_pacified = true
                    break
                end
            end
        end
    end
    return is_pacified
end

local function check_player_faction(player)
    is_faction = false
    for i, faction_string in ipairs(FACTIONS)
    do
        if is_faction then
            break
        end
        for j, faction in ipairs(NPC.getFactions(player))
        do
            if faction == string.match(faction, faction_string) then
                if not NPC.isExpelled(player, faction) then
                    is_faction = true
                    break
                end
            end
        end
    end
    return is_faction
end

local function check_player_speaker_began(player)
    if not check_player_faction(player) then
        return false
    end
    if types.Player.quests(player)[TR_QUEST] == nil then
        return false
    end
    stage = types.Player.quests(player)[TR_QUEST].stage
    return (stage >= TR_QUEST_MIN) and (stage < TR_QUEST_NOPE)
end

local function check_player_speaker_during(player)
    if not check_player_faction(player) then
        return false
    end
    if types.Player.quests(player)[TR_QUEST] == nil then
        return false
    end
    stage = types.Player.quests(player)[TR_QUEST].stage
    return (stage >= TR_QUEST_MIN) and (stage < TR_QUEST_MAX)
end

local CHECK_PLAYER_DICT = {
    player_detect_rank = check_player_rank,
    player_detect_speaker_began = check_player_speaker_began,
    player_detect_speaker_during = check_player_speaker_during,
}

local function check_player(player)
    is_debug = settings:get('is_debug')
    
    player_detect = ''
    if core.contentFiles.has('TR_Mainland.esm') then
        player_detect = settings:get('player_detect')
    else -- default
        player_detect = 'player_detect_rank'
    end
    check_player_function = CHECK_PLAYER_DICT[player_detect]

    --if PLAYER_CACHE[player.id] ~= nil then
    --    return PLAYER_CACHE[player.id]
    --end

    is_pacified = check_player_function(player)
    --PLAYER_CACHE[player.id] = is_pacified
    if is_debug then
        if is_pacified then
            print("player " .. player.id .. " is eligible for pacification")
        else
            print("player " .. player.id .. " is not eligible for pacification")
        end
    end
    return is_pacified
end

local function get_nearby_players(actor)
    -- TODO: kinda implementing nearby here, need to be more elegant

    is_debug = settings:get('is_debug')

    cell = actor.cell

    if cell.isExterior then
        -- 3x3 square
        players = {}
        for x = -1, 1 do
            for y = -1, 1 do
                c = world.getExteriorCell(cell.gridX + x, cell.gridY + y, cell)
                for i, p in ipairs(c:getAll(types.Player))
                do
                    table.insert(players, p)
                end
            end
        end
        return players
    else
        return cell:getAll(types.Player)
    end
end

local function pacify(actor)
    is_debug = settings:get('is_debug')

    if not check_cell(actor.cell) then
        return
    end

    if not check_creature(actor.recordId) then
        return
    end

    found_player = false
    _player = nil
    for i, a in ipairs(get_nearby_players(actor))
    do
        if check_player(a) then
            found_player = true
            _player = a
            break
        end
    end

    if found_player then
        if is_debug then
            print("sending pacify signal to " .. actor.recordId .. " " .. actor.id)
        end
        actor:sendEvent('TombPacify', {source=_player})
    end
end

return {
    engineHandlers = {
        onActorActive = pacify,
    },

    interfaceName = 'more_peaceful_tombs',
    interface = setmetatable({}, {
        __index = function(_, key)
            if key == 'help' then
                return help
            end

            if key == 'display_creatures' then
                return aux_util.deepToString(CREATURES_WHITELIST, 2)
            end
            if key == 'get_creatures' then
                return CREATURES_WHITELIST
            end
            if key == 'add_creature' then
                return function(arg)
                    is_debug = settings:get('is_debug')
                    if is_debug then
                        print("adding creature " .. arg)
                    end
                    table.insert(CREATURES_WHITELIST, arg)
                    CREATURES_CACHE = {}
                end
            end

            if key == 'display_cell_wl' then
                return aux_util.deepToString(CELL_WHITELIST, 2)
            end
            if key == 'get_cell_wl' then
                return CELL_WHITELIST
            end
            if key == 'add_cell_wl' then
                return function(arg)
                    is_debug = settings:get('is_debug')
                    if is_debug then
                        print("adding whitelist cell pattern " .. arg)
                    end
                    table.insert(CELL_WHITELIST, arg)
                    CELL_CACHE = {}
                end
            end

            if key == 'display_cell_bl' then
                return aux_util.deepToString(CELL_BLACKLIST, 2)
            end
            if key == 'get_cell_bl' then
                return CELL_BLACKLIST
            end
            if key == 'add_cell_bl' then
                return function(arg)
                    is_debug = settings:get('is_debug')
                    if is_debug then
                        print("adding blacklist cell pattern " .. arg)
                    end
                    table.insert(CELL_BLACKLIST, arg)
                    CELL_CACHE = {}
                end
            end

        end
    }),
}
