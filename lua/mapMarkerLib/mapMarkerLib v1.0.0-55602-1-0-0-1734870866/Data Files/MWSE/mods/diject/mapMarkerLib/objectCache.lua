local this = {}

---@type table<string, table<tes3reference, boolean>>
this.refsByObjectId = {}

---@param ref tes3reference
function this.addRef(ref)
    if not ref then return end

    local refs = this.refsByObjectId[ref.baseObject.id]
    if not refs then
        this.refsByObjectId[ref.baseObject.id] = {[ref] = true}
    else
        refs[ref] = true
    end
end

---@param ref tes3reference
function this.removeRef(ref)
    if not ref or not ref.baseObject then return end
    local arr = this.refsByObjectId[ref.baseObject.id]
    if arr then
        arr[ref] = nil
    end
end

---@param objectId string
---@return table<tes3reference, boolean>
function this.getRefTable(objectId)
    return this.refsByObjectId[objectId] or {}
end

function this.clear()
    this.refsByObjectId = {}
end

return this