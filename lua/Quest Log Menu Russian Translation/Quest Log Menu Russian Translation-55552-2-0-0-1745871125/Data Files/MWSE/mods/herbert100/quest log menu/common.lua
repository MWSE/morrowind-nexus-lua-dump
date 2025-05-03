local hlib = require("herbert100")
local log = Herbert_Logger()

-- log("starting common!")

-- so that switching to livecoding is easier
local register_event = event.register

---@class herbert.QLM.common
---@field get_actor_location_data fun(actor: tes3actor|string): herbert.QLM.Location_Data?
---@field format_cell_name_as_address fun(cell: tes3cell|string): string?
local common = {
    info_text_cache = {}, ---@type table<string, string> takes in id, spits out text
    actor_occupations = {} ---@type table<string, boolean> holds the different job suffixes that can appear on cells
}



-- a bunch of occupations, e.g. "Healer", "Bookseller", "Enchanter", etc.
-- doing it programatically means it will play more nicely with translations
local occupations = common.actor_occupations

local function update_occupations()
    for _, class in ipairs(tes3.dataHandler.nonDynamicData.classes) do
        if not class.playable then

            if class.bartersAlchemy
            or class.bartersApparatus
            or class.bartersArmor
            or class.bartersBooks
            or class.bartersClothing
            or class.bartersEnchantedItems
            or class.bartersIngredients
            or class.bartersLights
            or class.bartersLockpicks
            or class.bartersMiscItems
            or class.bartersProbes
            or class.bartersRepairTools
            or class.bartersWeapons
            or class.offersEnchanting
            then
                occupations[class.name] = true
            end
        end
    end
    log("loaded occupations as %s", function ()
        return json.encode(table.keys(occupations), {indent = true})
    end)
end
register_event(tes3.event.initialized, update_occupations)

-- if tes3.isInitialized() then update_occupations() end

local text_cache = common.info_text_cache

--- Loads the text of an info. This function caches the output.
-- This is important because accessing `info.text` involves reading from the disk,
-- so it can be quite slow.
-- This function is the reason that pretty much every part of this mod is considerably
-- faster after it's already been done once.
---@param info tes3dialogueInfo the info to load the text of
---@return string text
function common.get_text(info)
    local text = text_cache[info.id]
    if not text then
        text = info.text
        text_cache[info.id] = text
    end
    return text
end

-- Converts keybindings from their names in the `Text Defines` format, to their names in the 
-- `tes3.keybind` format.
---@type table<string, tes3.keybind>
local action_codes = {
    activate = tes3.keybind.activate,
    back = tes3.keybind.back,
    forward = tes3.keybind.forward,
    journal = tes3.keybind.journal,
    readyitem = tes3.keybind.readyWeapon,
    readymagic = tes3.keybind.readyMagic,
    restmenu = tes3.keybind.rest,
    slideleft = tes3.keybind.left,
    slideright = tes3.keybind.right,
    menumode = tes3.keybind.menuMode,
    use = tes3.keybind.use,
    crouch = tes3.keybind.sneak,
    run = tes3.keybind.run,
    togglerun = tes3.keybind.alwaysRun,
    jump = tes3.keybind.jump,
    nextweapon = tes3.keybind.nextWeapon,
    prevweapon = tes3.keybind.previousWeapon,
    nextspell = tes3.keybind.nextSpell,
    prevspell = tes3.keybind.previousSpell,
}
if tes3.hasCodePatchFeature(tes3.codePatchFeature.swiftCasting) then
    action_codes.readymagic = tes3.keybind.readyMagicMCP
end

-- Substitution functions used in `common.substitute_info_text`
---@type table<string, fun(info: tes3dialogueInfo): string>
local subsitution_functions = {

    -- -----------------------------------------------------------------------------
    -- PLAYER SUBSITUTIONS
    -- -----------------------------------------------------------------------------


    PCName = function() return tes3.player.object.name end,
    PCClass = function() return tes3.player.object.class.name end,
    PCRace = function() return tes3.player.object.race.name end,
    
    PCRank = function(info)
        local faction = info.firstHeardFrom.faction
        return faction and faction:getRankName(faction.playerRank)
            or "<ERROR: PCRank, no faction found>"
    end,

    PCCrimeLevel = function() return tostring(tes3.mobilePlayer.bounty) end,

    CrimeGoldTurnIn = function()
        return tostring(tes3.mobilePlayer.bounty * tes3.findGMST(tes3.gmst.fCrimeGoldTurnInMult))
    end,
    CrimeGoldDiscount = function()
        return tostring(tes3.mobilePlayer.bounty * tes3.findGMST(tes3.gmst.fCrimeGoldDiscountMult))
    end,

    Cell = function() return tes3.player.cell.displayName end,
    

    -- -------------------------------------------------------------------------
    -- SPEAKER SUBSITUTIONS
    -- -------------------------------------------------------------------------

    Name = function (info) return info.firstHeardFrom.name end,
    Class = function (info) return info.firstHeardFrom.class.name end,
    Race = function (info) return info.firstHeardFrom.race.name end,

    Rank = function(info)
        local faction = info.firstHeardFrom.faction
        return faction and faction:getRankName(info.firstHeardFrom.factionRank)
            or "<ERROR: Rank, no faction found>"
    end,

    Faction = function (info)
        local faction = info.firstHeardFrom.faction
        return faction and faction.name
            or "<ERROR: Faction, no faction found>"
    end,

}

-- these are also used sometimes. it's weird
subsitution_functions.PCNextRank = subsitution_functions.PCRank
subsitution_functions.NextPCRank = subsitution_functions.PCRank

-- Substitution functions used in `common.substitute_info_text`
common.subsitution_functions = subsitution_functions

-- support lower case versions too
for k, f in pairs(table.copy(subsitution_functions)) do
    subsitution_functions[k:lower()] = f
end

-- return a constant function that evaluates `v`
---@generic V
---@param v V
---@return fun(): V
local function const(v)
    return function() return v end
end

setmetatable(subsitution_functions, {
    -- look up missing subsitution keys
    -- this will first try to lowercase `subs_key` and see if that matches anything
    -- if it does, return that
    -- next, it will see if it's supposed to be a keycode. if so, it will match that against
    -- the current keybindings
    -- lastly, it will return an error string
    -- this will make things look bad, but at least they won't be broken
    ---@param subs_key string
    ---@return fun(info: tes3dialogueInfo): string
    __index = function(_, subs_key)
        local f = subsitution_functions[subs_key:lower()]
        if f then return f end

        if subs_key:find("^[Aa]ction") then 
            local code = action_codes[subs_key:sub(7):lower()]
            local binding = code and tes3.getInputBinding(code)

            if binding then
                if binding.device == 0 then
                    return const(tes3.getKeyName(binding.code))
                elseif binding.device == 1 then
                    return const("Mouse " .. binding.code)
                end
            end
        end
        
        return const(string.format("<ERROR: %s>", subs_key))
    end
})

local gsub = string.gsub

-- Takes in an info and then substitues the special [Text_Defines](https://en.uesp.net/wiki/Morrowind_Mod:Text_Defines)
-- patterns with the appropriate values.
-- e.g., `"%PCName"` -> `tes3.player.object.name`
---@param info tes3dialogueInfo
---@param text string? A substring of `info.text`, if substitution doesn't need to happen on all of `info.text`
-- Default: `info.text`
---@return string substituted_text
function common.substitute_info_text(info, text)
    -- the extra parentheses are to stop `gsub` from returning 2 values
    return (gsub(
        text or common.get_text(info),
         "%%(%w+)",
         function(subsitution_key)
            return subsitution_functions[subsitution_key](info)
        end
    ))
end



---@alias herbert.QLM.cell_path tes3cell[]

---@param cell tes3cell cell to find the region of
---@return tes3cell[]? path
function common.get_first_exterior_cell(cell)
    if cell.region then 
        return {cell}
    end

    local seen_cells = {[cell.id] = true}
    -- first index = `cell`, second index = `depth`
    local queue = {{cell}} ---@type tes3cell[][]
    local i = 1

    while queue[i] ~= nil do
        local entry = queue[i]

        for door_ref in entry[#entry]:iterateReferences(tes3.objectType.door) do
            cell = door_ref.destination and door_ref.destination.cell

            if cell and not seen_cells[cell.id] then

                local next_entry = {} ---@type tes3cell[]
                for j, v in ipairs(entry) do
                    next_entry[j] = v
                end
                table.insert(next_entry, cell)
                if cell.region then 
                    return next_entry
                end
                seen_cells[cell.id] = true
                table.insert(queue, next_entry)
            end
        end
        -- go to next entry
        i = i + 1
    end
end



-- =============================================================================
-- SSQN ICON COMPATIBILITY
-- =============================================================================

local ssqn_icon_paths = include("SSQN.iconlist") ---@type table<string, string>?
if ssqn_icon_paths then
    local ssqn_logger = Herbert_Logger.new{module_name="SSQN interop"}
    
    common.ssqn_interop = {}

    -- Retrieves the path to the quest icon, given the id of a `tes3dialogue`.
    -- If no icon is found, the default icon path will be returned.
    ---@param dialogue_id string
    ---@return string icon_path if it could be found
    function common.ssqn_interop.get_dialogue_id_icon_path(dialogue_id)
        return ssqn_icon_paths[dialogue_id]
            or ssqn_icon_paths[dialogue_id:match("([^_]+)$")]
            or "\\Icons\\SSQN\\DEFAULT.dds"
    end

    -- Retrieves the icon path for a given `tes3quest` or `herbert.QLM.Quest`
    ---@param quest tes3quest
    ---@return string icon_path_or_default
    function common.ssqn_interop.get_quest_icon_path(quest)
        -- some quests have multiple dialogues, and only one of those dialogues has an icon
        -- e.g., "Gateway Ghost" only has an icon for `quest.dialogue[2].id`
        for _, d in ipairs(quest.dialogue) do
            -- try to get the icon path using the whole id, 
            -- and then try again using the last `_` delimited part of the id.
            local path = ssqn_icon_paths[d.id] or ssqn_icon_paths[d.id:match("([^_]+)$")]

            if path then return path end
        end

        ssqn_logger:trace("icon path for quest \"%s\" not found! returning default icon path", quest.id)

        return "\\Icons\\SSQN\\DEFAULT.dds"
    end


    do -- Update incorrect SSQN icon paths
        -- this is necessary to ensure the UI code doesn't break
        -- i.e., the icon path getter functions should never return an icon path that does not exist


        -- patch the file by correcting the invalid icon paths
        local bad_paths = {} -- array for things that don't exist, and cannot be fixed
        local updated_paths = {} -- table for things that don't exist, but can be fixed
        ---@param v string
        for k, v in pairs(ssqn_icon_paths)  do
            if not lfs.fileexists("data files" .. v) then

                local new_path, _, f, s, parts
                -- couldn't figure out a pattern for these ones
                local overrides = {
                    ["\\Icons\\SSQN\\MG_Sabotage.dds"] = "\\Icons\\SSQN\\MG_sg.dds",
                    ["\\Icons\\SSQN\\HH_DestroyIndarysManor.dds"] = "\\Icons\\SSQN\\HH_DestroyIndarysManorV2.dds",
                }
                if overrides[v] then
                    new_path = overrides[v]
                    goto record_changes
                end

                -- sometimes the file exstension is ".dd" or ".dss" instead of ".dds"
                if not v:endswith(".dds") then
                    local _, _, head, tail = v:find("^([^.]+)%.?(%w*)$")
                    new_path = head .. ".dds"
                    goto record_changes
                end

                -- sometimes there's a superflous "MW_" before the icon path
                _, _, f, s = v:find("^(.*)MW_(.+)$")
                if f and s then
                    new_path = f .. s
                    goto record_changes
                end

                -- sometimes the icon paths don't say they're in the "SSQN" folder
                if not v:find("SSQN", 1, true) then
                    local _, _, head, tail = v:find("([^\\]+)\\(.+)")
                    new_path = head .. "\\SSQN\\" .. tail
                    goto record_changes
                end

                -- sometimes the icons paths say they're in subfolders when they aren't
                parts = v:sub(2):split("\\")
                if #parts > 3 then
                    new_path = table.concat({"", parts[1], parts[2], parts[#parts]}, "\\")
                    goto record_changes
                end
                

                ::record_changes::

                -- if we were able to fix the filepath, then we should fix it
                if new_path and lfs.fileexists("data files" .. new_path) then
                    updated_paths[k] = new_path
                else
                    -- if we couldn't fix the file path, then we should disable it
                    table.insert(bad_paths, k)
                end
            end
        end

        if log.level >= 2 and (next(updated_paths) or next(bad_paths)) then
            ssqn_logger:warn 'Some SSQN icon paths were incorrectly labeled in "Data Files/MWSE/mods/SSQN/iconlist.lua".'
            ssqn_logger:warn 'This mod will try to temporarily fix all the paths it can, but some paths may not be fixable.'
            ssqn_logger:warn '(This process will be repeated each time the game is launched.)'
        end
        local fmt = string.format
        local function add_quotes(str) return fmt('"%s"', str) end

        -- update paths and print the logging message
        if next(updated_paths) then
            ssqn_logger:info('The following SSQN icon paths will be updated:\n\t%s', function ()
                local key_header = " SSQN iconlist.lua key "
                local old_path_header = " Old file path "
                local new_path_header = " New file path "

                local old_max_path_len = old_path_header:len()
                local max_key_len = key_header:len()

                for k in pairs(updated_paths) do
                    max_key_len = math.max(k:len(), max_key_len)
                    old_max_path_len = math.max(ssqn_icon_paths[k]:len(), old_max_path_len)
                end

                
                local fmt_str = fmt('%%%is | %%%is | %%s', 4 + max_key_len, 4 + old_max_path_len)
                

                local strs = hlib.tbl_ext{ fmt(fmt_str, key_header, old_path_header, new_path_header)}


                for k, v in pairs(updated_paths) do
                    strs:insert(fmt(fmt_str, add_quotes(k), add_quotes(ssqn_icon_paths[k]), add_quotes(v)))
                end

                -- add a line underneath the header
                local max_str_len = hlib.tbl_ext.max(strs, string.len):len()
                table.insert(strs, 2, string.rep("-", max_str_len))


                return table.concat(strs, '\n\t')
            end)

            -- fix stuff
            for k, new_path in pairs(updated_paths) do
                ssqn_icon_paths[k] = new_path
            end
        end

        -- delete bad paths and print the logging message
        if next(bad_paths) then
            ssqn_logger:error('The following SSQN icon paths could not be fixed and have been removed:\n\t%s', function ()
                local key_header = " SSQN iconlist.lua key "
                local old_path_header = " Bad file path "

                local max_key_len = hlib.tbl_ext.max({key_header, table.unpack(bad_paths)}, string.len):len()
                
                local fmt_str = fmt('%%%is : %%s', 4 + max_key_len)
                
                local strs = hlib.tbl_ext{ fmt(fmt_str, key_header, old_path_header), "" }

                for _, k in ipairs(bad_paths) do
                    strs:insert(fmt(fmt_str, add_quotes(k), add_quotes(ssqn_icon_paths[k])))
                end
                return table.concat(strs, "\n\t")
            end)
            
            -- delete stuff
            for _, k in ipairs(bad_paths) do
                ssqn_icon_paths[k] = nil
            end
        end
        
    end
end


return common