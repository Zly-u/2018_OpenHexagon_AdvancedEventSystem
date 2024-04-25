local function deepcopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            if orig_value ~= orig then
                copy[deepcopy(orig_key)] = deepcopy(orig_value)
            end
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

return deepcopy