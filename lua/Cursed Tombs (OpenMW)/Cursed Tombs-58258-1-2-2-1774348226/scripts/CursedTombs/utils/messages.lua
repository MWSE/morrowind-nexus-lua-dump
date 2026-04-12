MAXINT = 2^53 - 1

function CollectAllMessagesByPrefix(prefix, l10n, ctx)
    if not ctx then ctx = {} end
    local msgs = {}
    for i = 1, MAXINT do
        local key = prefix .. "_" .. tostring(i)
        local msg = l10n(key, ctx)
        if msg ~= key then
            table.insert(msgs, msg)
        else
            break
        end
    end
    return msgs
end