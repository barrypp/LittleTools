package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

-- function on(name,value)
--     print_time(name)
--     print_table(value)
-- end
-- mp.observe_property("estimated-frame-count", "native", on)
-- mp.observe_property("container-fps", "native", on)

function on_file_loaded()
    local track_list = mp.get_property_native("track-list")
    local id = -1
    local channels = -1
    for i, v in pairs(track_list) do
        if (v.type == "audio") then
            if (v["demux-channel-count"] > channels) then
                channels = v["demux-channel-count"]
                id = v.id
            end
        end
    end
    mp.set_property_native("aid",id)

end
mp.register_event("file-loaded", on_file_loaded)







