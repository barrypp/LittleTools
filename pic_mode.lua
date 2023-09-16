local os_time_start = os.time()
local fit_to_width = false
local last_pic_is_prev = true
local file_load_done = false
local l = {
    zoom = 0,
    pan_y_max = 0,
    pan_y_min = 0,
}

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
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

function on_my_WHEEL_UP()
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

function on_my_WHEEL_DOWN()
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

function on_my_MBTN_LEFT_DBL()
    if (fit_to_width) then
        do_fit_to_width(false)
    else
        do_fit_to_width(true)
    end
end

function on_start_file()
    file_load_done = false
    name = mp.get_property_native("filename")
    if (name:match("%.png$") or name:match("%.jpg$")) then
        print_time("pic_mode on")
        mp.set_property_bool("pause", true)
        mp.add_forced_key_binding("WHEEL_UP","my_WHEEL_UP",on_my_WHEEL_UP)
        mp.add_forced_key_binding("WHEEL_DOWN","my_WHEEL_DOWN",on_my_WHEEL_DOWN)
        mp.add_forced_key_binding("MBTN_LEFT_DBL","my_MBTN_LEFT_DBL",on_my_MBTN_LEFT_DBL)
    elseif (name:match("%.gif$")) then
        mp.set_property_bool("pause", false)
        mp.add_forced_key_binding("WHEEL_UP","seek_1s_prev",function () mp.command("seek -1 exact") end)
        mp.add_forced_key_binding("WHEEL_DOWN","seek_1s_next",function () mp.command("seek 1 exact") end)
    else
        print_time("pic_mode off")
        mp.set_property_bool("pause", false)
        mp.remove_key_binding("my_WHEEL_UP")
        mp.remove_key_binding("my_WHEEL_DOWN")
        mp.remove_key_binding("my_MBTN_LEFT_DBL")        
        mp.remove_key_binding("seek_1s_next")
        mp.remove_key_binding("seek_1s_prev")
    end
end

function on_file_loaded()
    name = mp.get_property_native("filename")
    if (name:match("%.png$") or name:match("%.jpg$")) then
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

