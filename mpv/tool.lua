local os_time_start = os.time()

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
end

function kill_timeout(timer)
    if (timer ~= nil and timer:is_enabled()) then
        timer:kill()
    end
end

function kill_and_add_timeout(timer,...)
    kill_timeout(timer)
    return mp.add_timeout(...)
end

function print_table(v,pre)
    if (type(v) == "table" ) then
        for i, v2 in pairs(v) do
            if (pre == nil) then
                print_table(v2,i)
            else
                print_table(v2,pre.."."..i)
            end
        end
    else
        if (pre == nil) then
            print_time(v)
        else
            print_time(pre,":",v)
        end
    end
end

function is_img()
    local count = mp.get_property_native("estimated-frame-count")
    local fps = mp.get_property_native("container-fps")
    if (count == nil or fps == nil) then return false end
    if (count == 0 and fps == 1) then return true end
    return false
end