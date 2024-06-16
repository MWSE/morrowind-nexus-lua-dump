---@meta

---@class AbstractState
local AbstractState = {
}

--- Enter the state, each state is responsible for ending itself
function AbstractState:enterState()

end

--- End the state, each state is responsible for pushing the next state
function AbstractState:endState()

end
