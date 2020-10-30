local debug = false

sdb = {}

function sdb:set_debug(v)
    v = v or true
    debug = v
end

function sdb:log_debug(...)
    if debug then
        print("|cff888888", ...)
    end
end

function sdb:log_info(...)
    print("|cff00ffff", ...)
end

function sdb:log_error(...)
    print("|cffff8888", ...)
end

function sdb:log_debug_table(tbl)
    table.foreach(tbl, function(k, v)
        sdb:log_debug(k .. ": ", v)
    end)
end

function sdb:count_table_pairs(tbl)
    local count = 0

    for _ in pairs(tbl) do
        count = count + 1
    end

    return count
end

function sdb:contains(tbl, key)
    for k in pairs(tbl) do
        if k == key then
            return true
        end
    end

    return false
end

function sdb:GetOptionDefaults(options)
    local defaults = {}

    for k, v in pairs(options) do
        defaults[k] = v.default    
    end

    return defaults
end