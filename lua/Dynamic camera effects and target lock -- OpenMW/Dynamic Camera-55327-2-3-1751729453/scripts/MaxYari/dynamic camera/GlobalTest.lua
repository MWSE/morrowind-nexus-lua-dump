
local function onActivate(object, actor)
    print(object, "activated by",actor)
    actor:sendEvent("ObjectActivation", {object = object})
end

return { 
    engineHandlers = { 
        onActivate = onActivate
    }
}