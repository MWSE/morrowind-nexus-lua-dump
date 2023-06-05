local recipes = require("alchemyArt.potion.recipes")

local potionInterop = {}

local function validate(object, schema)
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
    assert(schema.fields, string.format("%s schema missing fields", schemaName) )
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
                validate(object[key], field.type)
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
                                    validate(tableValue, field.childType)
                                end
                                for _, tableValue in ipairs(object[key]) do
                                    validate(tableValue, field.childType)
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

local function isValidRecipe(recipe)

    local effectSchema = {
        name = "Effect",
        fields = {
            id = { type = "number", required = true },
            attribute = { type = "number", required = false },
            minPower = { type = "number", required = false },
            magnitude = { type = "number", required = true },
            duration = { type = "number", required = true },
        }
    }


    local recipeSchema = {
        name = "Recipe",
        fields = {
            name = { type = "string", required = true },
            isEpic = { type = "boolean", required = false },
            create = { type = "boolean", required = false },
            icon = { type = "string", required = false },
            mesh = { type = "string", required = false },
            value = { type = "number", required = false },
            weight = { type = "number", required = false },
            effects = { type = "table", childType = effectSchema, required = false, default = {} },
            components = { type = "table", childType = "string", required = false, default = {} },
            onConsumed = { type = "function", required = false }
        }
    }

    return validate(recipe, recipeSchema)
    
end

potionInterop.addRecipes = function(newRecipes)
    for id, newRecipe in ipairs(newRecipes) do
        if isValidRecipe(newRecipe) then
            if recipes[id] then
                mwse.log("[Art of Alchemy] Warning! Replacing recipe %s with a new one", id)
            end
            recipes[id] = newRecipe
        end
    end
end

return potionInterop