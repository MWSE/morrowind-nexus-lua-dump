-- StateMachine.lua
-- Reusable state machine helper for ProceduralChatter.
-- Provides enter/update/exit semantics with pcall-wrapped safety.
--
-- Usage:
--   local sm = StateMachine.create({
--       idle = { enter = function(prev, data) ... end,
--                update = function(dt) ... end,
--                exit = function(next) ... end },
--       walking = { ... },
--   }, "idle")
--
--   sm:transition("walking", { target = pos })
--   sm:update(dt)
--   local state = sm:get()
--   local isWalking = sm:is("walking")

local StateMachine = {}

--- Create a new state machine.
-- @param statesTable  table mapping state string -> { enter=fn, update=fn, exit=fn }
-- @param initialState string initial state name
-- @param opts         optional table { onTransition = function(prev, new, data) end }
-- @return state machine object
function StateMachine.create(statesTable, initialState, opts)
    local sm = {}
    sm._states = statesTable or {}
    sm._current = initialState or "idle"
    sm._previous = nil
    sm._opts = opts or {}

    function sm:get()
        return sm._current
    end

    function sm:getPrevious()
        return sm._previous
    end

    function sm:is(state)
        return sm._current == state
    end

    function sm:transition(newState, data)
        if newState == sm._current then return end
        if not sm._states[newState] then
            print(string.format("[StateMachine] INVALID STATE: %s (current=%s)", tostring(newState), tostring(sm._current)))
            return
        end

        local prevState = sm._current
        local prevDef = sm._states[prevState]
        if prevDef and prevDef.exit then
            local ok, err = pcall(prevDef.exit, newState)
            if not ok then
                print(string.format("[StateMachine] ERROR in exit(%s -> %s): %s", tostring(prevState), newState, tostring(err)))
            end
        end

        sm._previous = prevState
        sm._current = newState

        local newDef = sm._states[newState]
        if newDef and newDef.enter then
            local ok, err = pcall(newDef.enter, prevState, data)
            if not ok then
                print(string.format("[StateMachine] ERROR in enter(%s): %s", newState, tostring(err)))
            end
        end

        if sm._opts.onTransition then
            local ok, err = pcall(sm._opts.onTransition, prevState, newState, data)
            if not ok then
                print(string.format("[StateMachine] ERROR in onTransition(%s -> %s): %s", tostring(prevState), newState, tostring(err)))
            end
        end
    end

    function sm:update(dt)
        local def = sm._states[sm._current]
        if def and def.update then
            local ok, err = pcall(def.update, dt)
            if not ok then
                print(string.format("[StateMachine] ERROR in update(%s): %s", sm._current, tostring(err)))
            end
        end
    end

    return sm
end

return StateMachine
