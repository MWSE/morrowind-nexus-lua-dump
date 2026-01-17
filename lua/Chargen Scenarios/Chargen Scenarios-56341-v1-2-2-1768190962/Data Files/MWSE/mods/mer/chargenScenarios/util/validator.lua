local Validator = {}

local logger = require("logging.logger").new{
    moduleName = string.format("Validator"),
    logLevel = "INFO"
}

local FieldSchema = {
    name = "FieldSchema",
    fields = {
        type = { type = "table|string", required = true },
        required = { type = "boolean", required = true},
        childType = { type = "table", required = false },
        values = { type = "table", required = false },
        default = { type = "any", required = false }
    }
}
local SchemaSchema = {
    name = "Schema",
    fields = {
        name = { type = "string", required = false },
        fields = { type = "table", childType = FieldSchema, required = true }
    }
}

--splits a string along | to return list of available types
local function getTypeStrings(str)
    local pat = '|'
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t, cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


function Validator.validate(object, schema)
    assert(object, "Validation failed: No object provided.")
    assert(schema, "Validation failed: No schema provided.")


    if type(schema) == "string" then
        if schema == "any" then return end
        local matchesType = false
        for _, typeString in ipairs(getTypeStrings(schema)) do
            if type(object) == typeString then
                matchesType = true
            end
        end

        if not matchesType then
            assert(type(object) == schema,
            string.format('Validation failed: expected type "%s", got "%s"', schema, type(object)))
        end
        return
    end

    local schemaName = schema.name or "[unknown]"
    if not schema.fields then
        for k, v in pairs(schema) do
            mwse.log("key: %s, val: %s", k, v)
        end
    end
    assert(schema.fields, string.format("%s schema missing fields.", schemaName) )


    for key, field in pairs(schema.fields) do
        --check schema values
        assert(type(field) == "table", string.format('Validation failed: "%s" field data is not a table.', key))
        assert(field.type, string.format('Validation failed: "%s" field data missing type.', key))

        --check required field exists
        if field.required then
            assert(object[key] ~= nil, string.format('Validation failed for "%s": Missing required "%s" field.', schemaName, key))
        end

        if object[key] ~= nil then
            if field.type == "any" then
                --any let's whatever through
                return
            elseif type(field.type) == "table" then
                --Type is itself a schema
                Validator.validate(object[key], field.type)
            elseif type(field.type) == "string" then
                --standard lua types, might be separated by |
                --Split types and check each one
                local typeList = getTypeStrings(field.type)
                local matchesType = false
                for _, expectedTypeString in ipairs(typeList) do
                    if type(object[key]) == expectedTypeString then
                        matchesType = true
                        --table has child Type
                        if expectedTypeString == "table" then
                            --Child Type of table values
                            if field.childType then
                                for _, tableValue in pairs(object[key]) do
                                    Validator.validate(tableValue, field.childType)
                                end
                                for _, tableValue in ipairs(object[key]) do
                                    Validator.validate(tableValue, field.childType)
                                end
                            --Enums for table values
                            elseif field.values then
                                local valuesString = ""
                                for _, str in ipairs(field.values) do
                                    valuesString = string.format('%s, %s', valuesString, str)
                                end
                                for _, tableValue in ipairs(object[key]) do
                                    assert(field.values[tableValue],
                                        string.format('Validation failed for %s, expected one of the following values: [%s], got %s',
                                            schemaName, valuesString, tableValue
                                        )
                                    )
                                end
                                for _, tableValue in pairs(object[key]) do
                                    assert(field.values[tableValue],
                                        string.format('Validation failed for %s, expected one of the following values: [%s], got %s',
                                            schemaName, valuesString, tableValue
                                        )
                                    )
                                end
                            end
                        end
                        --table has values table

                    end
                end

                if not matchesType then
                    --We already know it should fail
                    --We assert with the unsplit string here,
                    --This will give a consistent error message
                    assert(type(object[key]) == field.type,
                        string.format(
                            'Validation failed for %s: %s must be of type "%s". Instead got "%s".',
                            schemaName, key, field.type, type(object[key])
                        )
                    )
                end
            end
        elseif field.default ~= nil then
            --nil, initialise default
            assert(type(object) == "table", string.format("Validation failed: %s is not a table.", object))
            object[key] = field.default
        end
    end
    return true
end

Validator.validate(SchemaSchema, SchemaSchema)

return Validator