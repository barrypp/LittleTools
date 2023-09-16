local os_time_start = os.time()
local fit_to_width = false
local last_pic_is_prev = true
local file_load_done = false
local is_pic = false
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
        if (last_pic_is_prev) then
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
    if (not file_load_done) then
        return
    end
    if (fit_to_width) then
        y = mp.get_property_native("video-pan-y")
        if (y > l.pan_y_max) then
            last_pic_is_prev = false
            mp.command("playlist-prev")
        end
        y = y + 0.02
        if (y > l.pan_y_max) then
            y = l.pan_y_max + 0.0001
        end
        mp.set_property_number("video-pan-y",y)
    else
        mp.command("playlist-prev")
    end
end

function on_WHEEL_DOWN()
    if (not file_load_done) then --在load done之前可能有多余操作
        return
    end    
    if (fit_to_width) then
        y = mp.get_property_native("video-pan-y")
        if (y < l.pan_y_min) then
            last_pic_is_prev = true
            mp.command("playlist-next")
        end
        y = y - 0.02
        if (y < l.pan_y_min) then
            y = l.pan_y_min - 0.0001
        end
        mp.set_property_number("video-pan-y",y)
    else
        mp.command("playlist-next")
    end    
end

function on_MBTN_LEFT_DBL()
    if (fit_to_width) then
        do_fit_to_width(false)
    else
        do_fit_to_width(true)
    end
end

function on_start_file()
    file_load_done = false
    ext = get_extension(mp.get_property_native("filename"))
    if (ext_img[string.lower(ext)] ~= nil) then
        is_pic = true
        mp.set_property_bool("pause", true)
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",on_WHEEL_UP)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",on_WHEEL_DOWN)
        mp.add_forced_key_binding("MBTN_LEFT_DBL","MBTN_LEFT_DBL",on_MBTN_LEFT_DBL)
    elseif (ext == "gif") then
        is_pic = false
        mp.set_property_bool("pause", false)
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",function () mp.command("seek -1 exact") end)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",function () mp.command("seek 1 exact") end)
    else
        is_pic = false
        mp.set_property_bool("pause", false)
        mp.remove_key_binding("WHEEL_UP")
        mp.remove_key_binding("WHEEL_DOWN")
        mp.remove_key_binding("MBTN_LEFT_DBL")
    end
end

function on_file_loaded()
    name = mp.get_property_native("filename")
    if (is_pic) then
        do_fit_to_width(fit_to_width)
    else
        do_fit_to_width(false)
    end
    file_load_done = true
end

-- function on_var(_,value) 
--     print_time("on_var",value)
-- end
-- mp.observe_property("video-pan-y", "native", on_var)

mp.register_event("start-file", on_start_file)
mp.register_event("file-loaded", on_file_loaded)

