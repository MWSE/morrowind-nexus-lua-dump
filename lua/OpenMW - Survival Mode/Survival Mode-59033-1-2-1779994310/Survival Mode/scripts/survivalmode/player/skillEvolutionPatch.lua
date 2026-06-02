local M = {}

function M.create(deps)
    local interfaces = assert(deps.interfaces)
    local stageHelpersApi = assert(deps.stageHelpersApi)

    local api = {}
    local registrationAttempted = false
    local registeredSkillGainHandler = false

    local function findSkillEvolutionInterfaceByShape()
        local ok, result = pcall(function()
            for key, value in pairs(interfaces) do
                local addSkillUsedHandler = value ~= nil
                    and (value.addSkillUsedHandler or value.AddSkillUsedHandler)
                    or nil

                if type(addSkillUsedHandler) == 'function'
                    and type(value.addOnHitHandler) == 'function'
                    and type(value.getState) == 'function' then
                    return { key = key, interface = value }
                end
            end

            return nil
        end)

        if not ok then
            return nil
        end

        if type(result) == 'table' then
            return result.interface
        end

        return nil
    end

    local function getSkillEvolutionInterface()
        if interfaces.SkillEvolution ~= nil then
            return interfaces.SkillEvolution
        end

        if interfaces.skillevolution ~= nil then
            return interfaces.skillevolution
        end

        return findSkillEvolutionInterfaceByShape()
    end

    local function registerWithSkillEvolution(skillEvolutionInterface)
        if skillEvolutionInterface == nil then
            return false
        end

        local addHandler = skillEvolutionInterface.addSkillUsedHandler
            or skillEvolutionInterface.AddSkillUsedHandler

        if type(addHandler) ~= 'function' then
            return false
        end

        return stageHelpersApi.registerExternalSkillGainHandler(addHandler) == true
    end

    function api.ensureRegistered()
        if registrationAttempted then
            if registeredSkillGainHandler then
                return true, 'SkillEvolution'
            end

            return false, nil
        end

        registrationAttempted = true
        registeredSkillGainHandler =
            registerWithSkillEvolution(getSkillEvolutionInterface())

        if registeredSkillGainHandler then
            return true, 'SkillEvolution'
        end

        return false, nil
    end

    return api
end

return M