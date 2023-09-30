local os_time_start = os.time()
local fit_to_width = false
local last_img_is_prev = true
local file_type = ""
local l = {
    zoom = 0,
    pan_y_max = 0,
    pan_y_min = 0,
}

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
end

function Set (t) -- from autoload.lua
    local set = {}
    for _, v in pairs(t) do set[v] = true end
    return set
end

ext_img = Set { -- from autoload.lua with modify
    'avif', 'bmp', 'j2k', 'jp2', 'jpeg', 'jpg', 'jxl', 'png',
    'svg', 'tga', 'tif', 'tiff', 'webp', 'psd'
}

function get_extension(path) -- from autoload.lua
    match = string.match(path, "%.([^%.]+)$" )
    if match == nil then
        return "nomatch"
    else
        return match
    end
end

function remove_key_binding_if_not_first()
    playlist_pos = mp.get_property_native("playlist-pos")
    playlist_count = mp.get_property_native("playlist-count")
    if (playlist_pos ~= 0) then
        remove_key_binding()
    end
end

function remove_key_binding_if_not_last()
    playlist_pos = mp.get_property_native("playlist-pos")
    playlist_count = mp.get_property_native("playlist-count")
    if ((playlist_pos+1) ~= playlist_count) then
        remove_key_binding()
    end
end

function remove_key_binding()
    mp.remove_key_binding("WHEEL_UP")
    mp.remove_key_binding("WHEEL_DOWN")
    mp.remove_key_binding("MBTN_BACK")
end

function calc_pan_and_zoom()
    width = mp.get_property_native("width")
    height = mp.get_property_native("height")
    osd_width = mp.get_property_native("osd-width")
    osd_height = mp.get_property_native("osd-height")
    l.zoom = math.log(height/osd_height*osd_width/width)/math.log(2)
    l.pan_y_max = (1-osd_height/(osd_width/width*height))/2
    l.pan_y_min = -l.pan_y_max
end

function do_fit_to_width(f)
    if (f) then
        fit_to_width = true
        calc_pan_and_zoom()
        mp.set_property_number("video-zoom",l.zoom)
        if (last_img_is_prev) then
            mp.set_property_number("video-pan-y",l.pan_y_max)
        else
            mp.set_property_number("video-pan-y",l.pan_y_min)
        end
    else
        fit_to_width = false
        mp.set_property_number("video-zoom",0)
        mp.set_property_number("video-pan-y",0)
    end
end

function on_WHEEL_UP()
    if (fit_to_width) then
        y = mp.get_property_native("video-pan-y")
        if (y > l.pan_y_max) then
            last_img_is_prev = false
            remove_key_binding_if_not_first()
            mp.command("playlist-prev")
        end
        y = y + 0.02
        if (y > l.pan_y_max) then
            y = l.pan_y_max + 0.0001
        end
        mp.set_property_number("video-pan-y",y)
    else
        remove_key_binding_if_not_first()
        mp.command("playlist-prev")
    end
end

function on_WHEEL_DOWN()
    if (fit_to_width) then
        y = mp.get_property_native("video-pan-y")
        if (y < l.pan_y_min) then
            last_img_is_prev = true
            remove_key_binding_if_not_last()
            mp.command("playlist-next")
        end
        y = y - 0.02
        if (y < l.pan_y_min) then
            y = l.pan_y_min - 0.0001
        end
        mp.set_property_number("video-pan-y",y)
    else
        remove_key_binding_if_not_last() --在load done之前可能有多余操作
        mp.command("playlist-next")
    end    
end

function on_MBTN_BACK()
    if (fit_to_width) then
        do_fit_to_width(false)
    else
        do_fit_to_width(true)
    end
end

function on_start_file()
    ext = get_extension(mp.get_property_native("filename"))
    if (ext_img[string.lower(ext)] ~= nil) then
        file_type = "img"
        mp.set_property_bool("pause", true)
    elseif (ext == "gif") then
        file_type = "gif"
        mp.set_property_bool("pause", false)
    else
        file_type = ""
        mp.set_property_bool("pause", false)
        remove_key_binding()
    end
    mp.observe_property("estimated-vf-fps", "native", on_first_frame)
end

function on_file_loaded()
    if (file_type == "img") then
        do_fit_to_width(fit_to_width)
    else
        do_fit_to_width(false)
    end
end

function on_first_frame(_,value)
    if (value == nil) then return end
    mp.unobserve_property(on_first_frame)
    if (file_type == "img") then
        do_fit_to_width(fit_to_width)
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",on_WHEEL_UP)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",on_WHEEL_DOWN)
        mp.add_forced_key_binding("MBTN_BACK","MBTN_BACK",on_MBTN_BACK)
    elseif (file_type == "gif") then
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",function () mp.command("seek -1 exact") end)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",function () mp.command("seek 1 exact") end)
    else
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",function () mp.command("seek -2 exact") end)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",function () mp.command("seek 2 exact") end)
        do_fit_to_width(false)
    end
end

-- function on_var(_,value) 
--     print_time("on_var",value)
-- end
-- mp.observe_property("estimated-vf-fps", "native", on_var)

mp.register_event("start-file", on_start_file)
mp.register_event("file-loaded", on_file_loaded)

