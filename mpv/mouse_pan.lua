package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

function on_WHEEL_UP()
    local zoom = mp.get_property_number("video-zoom")
    zoom = zoom + 0.1
    mp.set_property_number("video-zoom",zoom)
end

function on_WHEEL_DOWN()
    local zoom = mp.get_property_number("video-zoom")
    zoom = zoom - 0.1
    mp.set_property_number("video-zoom",zoom)
end

local last_mouse = nil
function on_mouse_move(_,v)
    local x = mp.get_property_native("video-pan-x")
    local y = mp.get_property_native("video-pan-y")
    local osd_dims = mp.get_property_native("osd-dimensions")
    local scaled_width = osd_dims.w - osd_dims.ml - osd_dims.mr
    local scaled_height = osd_dims.h - osd_dims.mt - osd_dims.mb
    mp.set_property_number("video-pan-x",(v.x-last_mouse.x)/scaled_width+x)
    mp.set_property_number("video-pan-y",(v.y-last_mouse.y)/scaled_height+y)
    last_mouse = v
end

local glsl_shaders = nil
function on_MBTN_FORWARD(s)
    if (s.event == "down") then
        last_mouse = mp.get_property_native("mouse-pos")
        mp.add_forced_key_binding("WHEEL_UP","WHEEL_UP",on_WHEEL_UP)
        mp.add_forced_key_binding("WHEEL_DOWN","WHEEL_DOWN",on_WHEEL_DOWN)
        mp.observe_property("mouse-pos", "native", on_mouse_move)
        glsl_shaders = mp.get_property_native("glsl-shaders") -- glsl_shaders cause lag when pan
        mp.set_property_native("glsl-shaders",{})
    elseif (s.event == "up") then
        mp.remove_key_binding("WHEEL_UP")
        mp.remove_key_binding("WHEEL_DOWN")
        mp.unobserve_property(on_mouse_move)
        mp.set_property_native("glsl-shaders",glsl_shaders)
    end
end

function on_file_loaded()
    if (is_img()) then
        mp.add_forced_key_binding("MBTN_FORWARD","MBTN_FORWARD",on_MBTN_FORWARD,{repeatable=false;complex=true})
    else
        mp.remove_key_binding("MBTN_FORWARD")
    end
end

mp.register_event("file-loaded", on_file_loaded)