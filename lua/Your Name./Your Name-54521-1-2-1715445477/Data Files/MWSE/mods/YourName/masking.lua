local this = {}

local logger = require("YourName.logger")
local memo = require("YourName.memory")

this.unknown = nil

---@param name string
---@return integer
function this.CreateMask(name)
    local bit = require("bit")
    local mask = 0
    local count = 0
    local n = name
    -- bad algorithm of exclude filtering
    n = n:gsub("^[Tt]he ", " ")
    n = n:gsub(" [Tt]he ", " ")
    n = n:gsub(" [Oo]f ", " ")
    n = n:trim():gsub("%s+", " ") -- trim trailing white space
    -- detect splitter
    for i = 1, #n do
        if n:sub(i, i) == " " then
            mask = bit.bor(mask, bit.lshift(1, count))
            count = count + 1
        end
    end
    mask = bit.bor(mask, bit.lshift(1, count))
    logger:debug("Name '%s' to Mask 0x%x", name, mask)
    return mask
end

---@param name string
---@param mask integer
---@param config  Config.Masking
---@return string?
function this.CreateMaskedName(name, mask, config)
    local bit = require("bit")
    local n = name
    -- the, or combine after word
    n = n:gsub("^[Tt]he ", "The+")
    n = n:gsub(" The ", " The+")
    n = n:gsub(" the ", " the+")
    n = n:gsub(" Of ", " Of+")
    n = n:gsub(" of ", " of+")
    -- n = n:trim():gsub("%s+", " ") -- trim trailing white space
    local part = n:split(" ")
    local masked = ""
    local count = 0
    for i, _ in ipairs(part) do
        local b = bit.band(mask, bit.lshift(1, i - 1))
        if b == 0 then
            -- join with cut combine character
            masked = masked .. part[i]:gsub("%+", " ") .. " "
            count = count + 1
        elseif config.fillUnknowns then
            masked = masked .. "??? "
        end
    end
    masked = masked:trim()
    masked = masked:gsub("^%l", string.upper) -- first character lower to upper
    masked = masked:gsub("^Of ", "")          -- trim first Of
    --table.concat(part)
    logger:debug("Mask 0x%x to Name '%s' (%d)", mask, masked, count)
    if count == 0 then
        return nil
    end
    return masked
end

---@param name string
---@return string
function this.PreprocessName(name)
    local n = name
    --n = n:lower()
    n = n:gsub("^[\"']", "")  -- quate head
    n = n:gsub("[\"']$", "")  -- quate tail
    n = n:gsub(" [\"']", " ") -- quate middle
    n = n:gsub("[\"'] ", " ") -- quate middle
    n = n:gsub("^[Tt]he ", "")
    n = n:gsub(" [Tt]he ", " ")
    n = n:gsub(" [Oo]f ", " ")
    n = n:trim():gsub("%s+", " ") -- trim trailing white space
    -- <name>'s
    logger:trace("Preprocessed name: %s", n)
    return n
end

---@param text string
---@return string
function this.PreprocessText(text)
    local t = text
    t = t:gsub("[%c!#%$&%(%)=%^~\\|@`%[%{;%+:%*%]%},<%.>/%?_]", "") -- escape %c (control) and %p (punctuation) exclude ' %
    t = t:gsub("^[\"']", "")                                        -- quate head
    t = t:gsub("[\"']$", "")                                        -- quate tail
    t = t:gsub(" [\"']", " ")                                       -- quate middle
    t = t:gsub("[\"'] ", " ")                                       -- quate middle
    t = t:trim():gsub("%s+", " ")                                   -- trim trailing white space
    logger:trace("Preprocessed text: %s", t)
    return t
end

---@param actor tes3creature|tes3npc
---@param config Config.Masking
---@return string
function this.CreateUnknownName(actor, config)
    if actor.objectType == tes3.objectType.creature then
        -- return actor.name
    end
    if actor.objectType == tes3.objectType.npc then
        local names = {}
        if config.gender then
            if actor.female then
                table.insert(names, "Female")
            else
                table.insert(names, "Male")
            end
        end
        if config.race then
            table.insert(names, actor.race.name)
        end
        if not table.empty(names) then
            return table.concat(names, " ")
        end
    end
    return "Unknown" -- configuable?
end

---@param actor tes3creature|tes3npc
---@param config Config.Gameplay
---@param updateTimestamp boolean
---@return integer
function this.QueryUnknown(actor, config, updateTimestamp)
    local record = memo.ReadMemory(actor.id)
    if record ~= nil then
        -- test remember
        if config.skill and tes3.mobilePlayer and record.lastAccess then
            if memo.TryRemember(tes3.mobilePlayer, record) == false then
                logger:debug("Forget %s", actor.id)
                local mask = this.CreateMask(actor.name)
                record.mask = mask -- overwrite
                -- return record.mask
            end
        end
        if updateTimestamp then
            record.lastAccess = tes3.getSimulationTimestamp()
        end
        return record.mask
    end
    local mask = this.CreateMask(actor.name)
    memo.WriteMemory(actor.id, mask, tes3.getSimulationTimestamp())
    return mask
end

---@param id string
---@param mask integer
function this.RevealName(id, mask)
    memo.WriteMemory(id, mask, tes3.getSimulationTimestamp())
end

--- https://wiki.openmw.org/index.php?title=Research:Dialogue_and_Messages
--- In order to find it concisely, we do not consider case differences other than the initial letter.
---@param text string
---@return boolean
function this.FindMacroName(text)
    return text:find("%%[Nn]ame") ~= nil
end

function this.FindName(text, name)
    local filtered = this.PreprocessText(text):lower():split(" ")
    local set = {}
    for _, l in ipairs(filtered) do set[l] = true end

    -- part
    local mask = 0
    local part = this.PreprocessName(name):lower():split(" ")
    for i, n in ipairs(part) do
        if set[n] == nil then -- complete matching
            mask = bit.bor(mask, bit.lshift(1, i - 1))
        else
            logger:trace("Find part: %s", n)
        end
    end
    logger:trace("Find mask: 0x%x", mask)
    return mask
end

---@param text string
---@param fullname string
---@param unknown integer old mask
---@return integer mask new mask
function this.ContainName(text, fullname, unknown)
    if this.FindMacroName(text) then
        logger:debug("Contain macro name")
        return 0x0
    end
    local find = this.FindName(text, fullname)
    local bit = require("bit")
    local mask = bit.band(unknown, find)
    logger:debug("Unknown %x & Find %x = %x", unknown, find, mask)
    return mask
end

return this
