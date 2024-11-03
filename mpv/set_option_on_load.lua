package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

-- function on(name,value)
--     print_time(name)
-- end
-- mp.observe_property("video-params", "native", on)
-- mp.register_event("playback-restart", function() print_time("playback-restart") end)

local lang_map = {ja=5,jpn=1,eng=2,en=2,kor=3}
set_table_default(lang_map,0)

function on_file_loaded()

    -- aid, audio_track
    local track_list = mp.get_property_native("track-list")
    local id = -1
    local lang_p = -1
    local channels = -1
    for i, v in pairs(track_list) do
        if (v.type == "audio") then
            if ((lang_map[v.lang] > lang_p) or 
                (lang_map[v.lang] == lang_p and v["demux-channel-count"] > channels)
            ) then
                channels = v["demux-channel-count"]
                id = v.id
                lang_p = lang_map[v.lang]
            end
        end
    end
    mp.set_property_native("aid",id)

    -- af
    if (channels > 2) then
        af = "sofalizer=gain=24:sofa=\"" .. mp.command_native({"expand-path", "~~/sofalizer/ClubFritz4.sofa"}) .. "\""
        mp.set_property_native("af", af)
    end

end
mp.register_event("file-loaded", on_file_loaded)

function on_playback_restart()
    mp.unregister_event(on_playback_restart)

    -- sub-color
    local primaries = mp.get_property_native("video-params/primaries")
    if (primaries == "bt.2020") then
        mp.set_property("sub-color",'#FF007700')
    else
        mp.set_property("sub-color",'#FF00CC00')--FF00CC00
    end
end

function on_start_file()
    mp.register_event("playback-restart", on_playback_restart) -- 若在on_file_loaded时才运行，可能收不到消息
end
mp.register_event("start-file", on_start_file)