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
end

local fit_to_width = false
local l = {
    zoom = 0,
    pan_y_max = 0,
    pan_y_min = 0,
}
function calc_pan_and_zoom()
    local width = mp.get_property_native("width")
    local height = mp.get_property_native("height")
    local osd_width = mp.get_property_native("osd-width")
    local osd_height = mp.get_property_native("osd-height")
    if (not fit_to_width or width/height >= 16/9) then
        l.zoom = 0
        l.pan_y_max = 0
        l.pan_y_min = -l.pan_y_max
    else
        l.zoom = math.log(height/osd_height*osd_width/width)/math.log(2)
        l.pan_y_max = (1-osd_height/(osd_width/width*height))/2
        l.pan_y_min = -l.pan_y_max
    end
end

local last_img_is_prev = true
function do_fit_to_width()
    calc_pan_and_zoom()
    mp.set_property_number("video-zoom",l.zoom)
    if (last_img_is_prev) then
        mp.set_property_number("video-pan-y",l.pan_y_max)
    else
        mp.set_property_number("video-pan-y",l.pan_y_min)
    end
end

function on_WHEEL_UP()
    local y = mp.get_property_native("video-pan-y")
    if (y >= l.pan_y_max) then
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
    if (y <= l.pan_y_min) then
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
    do_fit_to_width()
end

function on_file_loaded()
    if (not is_img()) then
        fit_to_width = false
    end
    do_fit_to_width()
    mp.observe_property("estimated-vf-fps", "native", on_first_frame)
end

function on_first_frame(_,value)
    if (value == nil) then return end
    mp.unobserve_property(on_first_frame)
    if (is_img()) then
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",on_WHEEL_UP)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",on_WHEEL_DOWN)
        mp.add_forced_key_binding("MBTN_BACK","MBTN_BACK",on_MBTN_BACK)
    else
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",function () mp.command("seek -2 exact") end)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",function () mp.command("seek 2 exact") end)
    end
end

-- function on_var(_,value) 
--     print_time("on_var",value)
-- end
-- mp.observe_property("estimated-vf-fps", "native", on_var)

mp.register_event("file-loaded", on_file_loaded)

