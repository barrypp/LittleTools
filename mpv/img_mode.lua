package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

function remove_key_binding_if_middle()
    local playlist_pos = mp.get_property_native("playlist-pos")
    local playlist_count = mp.get_property_native("playlist-count")
    if (playlist_pos ~= 0 and (playlist_pos+1) ~= playlist_count) then
        remove_key_binding()
    end
end

function remove_key_binding()
    mp.remove_key_binding("WHEEL_UP")
    mp.remove_key_binding("WHEEL_DOWN")
    mp.remove_key_binding("MBTN_BACK")
    mp.remove_key_binding("HOME")
    mp.remove_key_binding("END")
end

local fit_to_width = false
local l = {
    zoom = 0,
    pan_y_max = 0,
    pan_y_min = 0,
}
function calc_pan_and_zoom() --"osd-dimensions"的scaled_width在on_playback_restart后才有效
    local width = mp.get_property_native("width")
    local height = mp.get_property_native("height")
    local osd_width = mp.get_property_native("osd-width")
    local osd_height = mp.get_property_native("osd-height")
    if (width/height >= 16/9) then
        l.zoom = 0
        l.pan_y_max = 0
        l.pan_y_min = -l.pan_y_max
    else
        t = height/osd_height*osd_width/width
        l.zoom = math.log(t)/math.log(2)
        l.pan_y_max = (1-1/t)/2
        l.pan_y_min = -l.pan_y_max
    end
end

local last_img_is_prev = true
function do_fit_to_width()
    calc_pan_and_zoom()
    mp.set_property_number("video-zoom",l.zoom)
    mp.set_property_number("video-pan-x",0)
    if (last_img_is_prev) then
        mp.set_property_number("video-pan-y",l.pan_y_max)
    else
        mp.set_property_number("video-pan-y",l.pan_y_min)
    end
end

function on_WHEEL_UP()
    local y = mp.get_property_native("video-pan-y")
    if (y >= l.pan_y_max or not fit_to_width) then
        last_img_is_prev = false
        remove_key_binding_if_middle() --在load done之前可能有多余操作
        mp.command("playlist-prev")
    else
        y = y + 0.02
        if (y > l.pan_y_max) then
            y = l.pan_y_max + 0.0001
        end
        mp.set_property_number("video-pan-y",y)
    end
end

function on_WHEEL_DOWN()
    local y = mp.get_property_native("video-pan-y")
    if (y <= l.pan_y_min or not fit_to_width) then
        last_img_is_prev = true
        remove_key_binding_if_middle() --在load done之前可能有多余操作
        mp.command("playlist-next")
    else
        y = y - 0.02
        if (y < l.pan_y_min) then
            y = l.pan_y_min - 0.0001
        end
        mp.set_property_number("video-pan-y",y)
    end
end

function on_MBTN_BACK()
    fit_to_width = not fit_to_width
    if (fit_to_width) then
        do_fit_to_width()
    else
        reset_pan_zoom()
    end
end

function on_start_file()
    mp.register_event("playback-restart", on_playback_restart) -- 若在on_file_loaded时才运行，可能收不到消息
end

function on_file_loaded()
    if (fit_to_width) then
        if (is_img()) then
            do_fit_to_width()
        else
            reset_pan_zoom()
        end
    end
end

function on_HOME()
    if (fit_to_width) then
        mp.set_property_number("video-pan-y",l.pan_y_max)
    end
end

function on_END()
    if (fit_to_width) then
        mp.set_property_number("video-pan-y",l.pan_y_min)
    end
end

function on_playback_restart()
    mp.unregister_event(on_playback_restart)
    if (is_img()) then
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",on_WHEEL_UP)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",on_WHEEL_DOWN)
        mp.add_forced_key_binding("MBTN_BACK","MBTN_BACK",on_MBTN_BACK)
        mp.add_forced_key_binding("HOME","HOME",on_HOME)
        mp.add_forced_key_binding("END","END",on_END)
    else
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",function () mp.command("seek -2 exact") end)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",function () mp.command("seek 2 exact") end)
        mp.add_forced_key_binding("HOME","HOME",function () mp.set_property_number("percent-pos",0) end)
        mp.add_forced_key_binding("END","END",function () mp.set_property_number("percent-pos",100) end)
    end
end

mp.register_event("start-file", on_start_file)
mp.register_event("file-loaded", on_file_loaded)