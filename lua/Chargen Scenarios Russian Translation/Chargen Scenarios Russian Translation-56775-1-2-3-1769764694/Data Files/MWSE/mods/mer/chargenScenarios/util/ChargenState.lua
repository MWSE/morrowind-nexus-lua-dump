---@class ChargenScenarios.ChargenState
local ChargenState = {}

ChargenState.COMPLETE = -1

---@param state number
---@return boolean
function ChargenState.set(state)
    tes3.findGlobal("CharGenState").value = state
end

---@return number?
function ChargenState.get()
    return tes3.getGlobal("ChargenState")
end

--Complete chargen
function ChargenState.complete()
    ChargenState.set(ChargenState.COMPLETE)
end

--Check if chargen is complete
---@return boolean
function ChargenState.isComplete()
    return ChargenState.get() == ChargenState.COMPLETE
end

return ChargenState