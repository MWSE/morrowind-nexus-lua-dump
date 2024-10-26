local Property = {}

function Property.Create()
    local property = {}

    property.currentValue = nil
    property.previousValue = nil

    property.getPreviousValue = Property.getPreviousValue
    property.getValue = Property.getValue
    property.setValue = Property.setValue

    return property
end

function Property.getValue(self)
    return self.currentValue
end

function Property.getPreviousValue(self)
    return self.previousValue
end

function Property.setValue(self, value)
    if self.currentValue == value then
        return
    end

    self.previousValue = self.currentValue
    self.currentValue = value
end

return Property
