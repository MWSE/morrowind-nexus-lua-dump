local DropFramework = {}

DropFramework.scriptName = "DropFramework"

DropFramework.defaultData = {
    drops = {},
    stocks = {}
}

DropFramework.data = DataManager.loadData(DropFramework.scriptName, DropFramework.defaultData)

function DropFramework.saveData()
    DataManager.saveData(DropFramework.scriptName, DropFramework.data)
end


-- drop count distributions
function DropFramework.getDistribution(name)
    return DropFramework.distributions[name]()
end

function DropFramework.addDistribution(name, operation)
    DropFramework.distributions[name] = operation
end

function DropFramework.getUniform()
    math.randomseed(os.time())
    math.random()
    return math.random() * 2 - 1
end

-- drops
function DropFramework.createItem(refId, charge, echantmentCharge, soul)
    return {
        refId = refId,
        charge = charge,
        echantmentCharge = echantmentCharge,
        soul = soul
    }
end

function DropFramework.createDrop(item, min, max, distribution)
    if distribution == "uniform" then
        distribution = nil
    end

    local drop = {
        item = item,
        min = min,
        max = max,
        distribution = distribution
    }

    local dropId = #DropFramework.data.drops + 1
    DropFramework.data.drops[dropId] = drop

    return dropId
end

function DropFramework.getDrop(dropId)
    return DropFramework.data.drops[dropId]
end

function DropFramework.removeDrop(dropId)
    DropFramework.data.drops[dropId] = nil
end

function DropFramework.addDrop(name, dropId)
    return DropFramework.addRoll(name, {dropId}, {1.0})
end


function DropFramework.resolveItem(item, count)
    local t = {
        refId = item.refId,
        charge = item.charge,
        echantmentCharge = item.echantmentCharge,
        soul = item.soul,
        count = count
    }

    if t.charge == nil then
        t.charge = -1
    end
    if t.echantmentCharge == nil then
        t.echantmentCharge = -1
    end
    if t.soul == nil then
        t.soul = ""
    end

    return t
end

function DropFramework.resolveDrop(dropId)
    local drop = DropFramework.getDrop(dropId)

    local x = 0.5
    if drop.distribution == nil then
        x = DropFramework.getUniform()
    else
        x = DropFramework.getDistribution(drop.distribution)
    end
    
    local a = drop.min
    local b = drop.max
    count = math.floor(0.5 * (a + b + x * (a - b)) + 0.5)

    return DropFramework.resolveItem(drop.item, count)
end

-- rolls between a few drops
function DropFramework.addRoll(name, drops, chances)
    local stock = DropFramework.getStock(name)

    local roll = {}
    for i, dropId in ipairs(drops) do
        roll[dropId] = chances[i]
    end

    table.insert(stock, roll)
end

-- stocks that define an inventory
function DropFramework.addStock(name)
    DropFramework.data.stocks[name] = {}
end

function DropFramework.removeStock(name)
    DropFramework.data.stocks[name] = nil
end

function DropFramework.getStock(name)
    return DropFramework.data.stocks[name]
end


function DropFramework.getRandom()
    math.randomseed(os.time())
    math.random()
    math.random()
    return math.random()
end

function DropFramework.resolveStock(name)
    local stock = DropFramework.getStock(name)
    local inventory = {}

    local r = 0

    for _, roll in ipairs(stock) do
        r = DropFramework.getRandom()
        for dropId, chance in pairs(roll) do
            r = r - chance

            if r <= 0 then
                local item = DropFramework.resolveDrop(dropId)
                
                table.insert(inventory, item)
                break
            end
        end
    end

    return inventory
end

customEventHooks.registerHandler("OnServerExit", DropFramework.saveData)

return DropFramework