local debug = false

sdb = {}

function sdb:set_debug(v)
    v = v or true
    debug = v
end

function sdb:log_debug(...)
    if debug then
        print("|cff888888" .. ...)
    end
end

function sdb:log_info(...)
    print("|cff00ffff" .. ...)
end

function sdb:log_error(...)
    print("|cffff8888" .. ...)
end
