function string.split(str, delim)
    local ret = {}
    if not str then
        return ret
    end
    if not delim or delim == '' then
        for c in str:gmatch('.') do
            table.insert(ret, c)
        end
        return ret
    end
    local n = 1
    while true do
        local i, j = str:find(delim, n)
        if not i then break end
        table.insert(ret, str:sub(n, i - 1))
        n = j + 1
    end
    table.insert(ret, str:sub(n))
    return ret
end