local core = require'openmw.core'

local M = {}

-- Sent to player from item script after its activation.
M.PlayerActivatedStack = {
    eventName = 'styxd.stackmaster.PlayerActivatedStack',
    sendEvent = function(props)
        local player = assert(props.player)
        local stackInfoProps = assert(props.stackInfoProps)

        player:sendEvent(M.PlayerActivatedStack.eventName, {
            stackInfoProps = stackInfoProps
        })
    end
}

-- Sent to global from player when returning the stack from player's inventory
-- to its original position in the world is requested.
M.ReturnStack = {
    eventName = 'styxd.stackmaster.ReturnStack',
    sendEvent = function(props)
        local player = assert(props.player)
        local stackInfoProps = assert(props.stackInfoProps)
        local keepOneItem = props.keepOneItem or false

        core.sendGlobalEvent(M.ReturnStack.eventName, {
            player = player,
            stackInfoProps = stackInfoProps,
            keepOneItem = keepOneItem
        })
    end
}

return M
