package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

-- function on(name,value)
--     print_time(name)
-- end
-- mp.observe_property("video-params", "native", on)
-- mp.register_event("playback-restart", function() print_time("playback-restart") end)

local lang_map = {ja=10,jpn=5,eng=9,en=9,kor=3}
set_table_default(lang_map,0)

local t_file_loaded = nil
local could_set_fullscreen = true
function on_file_loaded()
    t_file_loaded = mp.get_time() * 1000

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

    -- fullscreen
    if (could_set_fullscreen) then
        could_set_fullscreen = false
        mp.set_property_native("fullscreen",true)
    end
end
mp.register_event("file-loaded", on_file_loaded)

local t_start_file = nil
local could_set_visibility = true
function on_playback_restart()
    local now = mp.get_time() * 1000
    mp.unregister_event(on_playback_restart)

    -- show play_delay time
    local width = mp.get_property_native("width")
    local height = mp.get_property_native("height")
    local video_format = mp.get_property_native("video-format")
    local time = string.format("%.0f+%.0f=%.0fms", t_file_loaded-t_start_file, now-t_file_loaded, now-t_start_file)
    local p_size = string.format(width .. "*" .. height .. "=%.1fM", width*height/1e6)
    local f_size = nil
    if (mp.get_property_native("file-size")) then
        f_size = string.format("%.2fMB", mp.get_property_native("file-size")/1024/1024)
    else
        f_size = "-MB"
    end
    print_time("play_delay",p_size,f_size,video_format,time)

    -- sub-color
    local primaries = mp.get_property_native("video-target-params/primaries")
    if (primaries == "bt.2020") then
        mp.set_property("sub-color",'#FF007700')
    else
        mp.set_property("sub-color",'#FF009900')--FF00CC00
    end

    -- save-position-on-quit
    -- mp.set_property_native("save-position-on-quit",mp.get_property_native("working-directory"):match('E:\\T') ~= nil)

    -- user-data/osc/visibility
    -- if (could_set_visibility) then
    --     could_set_visibility = false
    --     if (is_img()) then
    --         mp.commandv("script-message-to","osc","osc-visibility","never","false")
    --     else
    --         mp.commandv("script-message-to","osc","osc-visibility","auto","false")
    --     end        
    -- end 
end

function on_eof_reached(_,v)
    if (v) then
        mp.set_property_native("fullscreen",false)
        -- mp.set_property_native("save-position-on-quit",false)
    end
end
mp.observe_property("eof-reached", "native", on_eof_reached)

function on_start_file()
    t_start_file = mp.get_time() * 1000
    mp.register_event("playback-restart", on_playback_restart) -- 若在on_file_loaded时才运行，可能收不到消息
end
mp.register_event("start-file", on_start_file)