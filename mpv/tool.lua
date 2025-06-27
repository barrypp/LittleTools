local utils = require("mp.utils")
local os_time_start = os.time()

function print_time(...)
    print(mp.get_time() .. "s", ...)
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
            print(pre,":",v)
        end
    end
end

function print_table_str(v)
    print_time(utils.to_string(v))
end

function print_table_json(v)
    print_time(utils.format_json(v))
end

function is_img() -- after file-loaded
    local count = mp.get_property_native("estimated-frame-count")
    local fps = mp.get_property_native("container-fps")
    if (count == nil or fps == nil) then return false end
    if ((count == 0 or count == 1) and fps == 1) then return true end
    return false
end

function reset_pan_zoom()
    mp.set_property_number("video-zoom",0)
    mp.set_property_number("video-pan-x",0)
    mp.set_property_number("video-pan-y",0)
end

function set_table_default(t, d)
    setmetatable(t, {__index = function () return d end})
end

function is_middle()
    local playlist_pos = mp.get_property_native("playlist-pos")
    local playlist_count = mp.get_property_native("playlist-count")
    if (playlist_pos ~= 0 and (playlist_pos+1) ~= playlist_count) then
        return true
    else
        return false
    end
end