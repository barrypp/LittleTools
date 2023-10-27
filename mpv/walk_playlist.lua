local os_time_start = os.time()
local last_pos = 0
local next_pos_frac = -1
local is_key_down = false
local timer = nil
local ui_on = false

function print_time(...)
    print("+" .. os.time() - os_time_start .. "s", ...)
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

function on_start_file()
    mp.observe_property("estimated-vf-fps", "native", on_first_frame)
end

function on_file_loaded()
    if (next_pos_frac ~= -1) then
        mp.set_property_number("percent-pos",next_pos_frac*100)
        next_pos_frac = -1
    end
end

function on_first_frame(_,value)
    if (value == nil) then return end
    mp.unobserve_property(on_first_frame)
    mp.observe_property("mouse-pos", "native", on_mouse_move)
end

function on_fullscreen(_,value)
    if (not value) then
        is_key_down = false
    end
end

local assdraw = require 'mp.assdraw'
local ui = mp.create_osd_overlay("ass-events")
local ass = assdraw.ass_new()
function ui_update(name,value)
    if (value == nil) then return end
    if (not ui_on) then return end
    playlist_count = mp.get_property_native("playlist-count")
    playlist_pos = mp.get_property_native("playlist-pos")
    percent_pos = mp.get_property_native("percent-pos")
    local osd_width, osd_height, osd_par = mp.get_osd_size()
    if (percent_pos == nil or playlist_pos == nil or playlist_count == nil) then return end
    if (osd_width == nil or osd_height == nil) then return end
    --
    ass = assdraw.ass_new()
    ass:append("{\\pos(0,0)}{\\rDefault\\blur0\\bord0\\alpha&H00\\1c&H00CC00&}")
    ass:draw_start()
    pos = (playlist_pos+percent_pos/100)/playlist_count
    if (osd_width/osd_height > 854/720) then -- magic number
        ass:rect_cw(0,osd_height*(1-0.085),pos*osd_width,osd_height*(1-0.075))
    else
        ass:rect_cw(0,osd_height-osd_width*0.0730,pos*osd_width,osd_height-osd_width*0.0630)
    end
    ass:draw_stop()
    ui.res_x = osd_width
    ui.res_y = osd_height
    ui.data = ass.text
    ui:update()
end

function on_mouse_move(_,mouse)
    show_ui()
    if (is_key_down) then
        walk()
    end
end

function walk()
    playlist_count = mp.get_property_native("playlist-count")
    osd_width = mp.get_property_native("osd-width")
    osd_height = mp.get_property_native("osd-height")
    mouse = mp.get_property_native("mouse-pos")
    if (mouse.hover and mouse.y > 0.8*osd_height) then
        x = playlist_count*mouse.x/osd_width
        next_pos = math.floor(x)
        next_pos_frac = x - next_pos
        if (last_pos ~= next_pos) then
            mp.unobserve_property(on_mouse_move)
            mp.set_property_number("playlist-pos",next_pos)
            last_pos = next_pos
        else
            mp.set_property_number("percent-pos",next_pos_frac*100)
        end
    end
end

function show_ui()
    if (not ui_on) then
        ui_on = true
        mp.observe_property("playlist-count", "native", ui_update)
        mp.observe_property("playlist-pos", "native", ui_update)
        mp.observe_property("osd-dimensions", "native", ui_update)
        mp.observe_property("percent-pos", "native", ui_update)
    end
    timer = kill_and_add_timeout(timer, 0.5, hide_ui)
end

function hide_ui()
    mp.unobserve_property(ui_update)
    ui_on = false
    ui:remove()
end

function on_key(s)
    if (s.event == "down") then -- and mp.get_property_native("fullscreen")) then
        is_key_down = true
        walk()
        show_ui()
    elseif (s.event == "up") then
        is_key_down = false
    end
end

mp.register_event("start-file", on_start_file)
mp.register_event("file-loaded", on_file_loaded)
mp.observe_property("fullscreen", "native", on_fullscreen)
mp.add_forced_key_binding("/","/",on_key,{repeatable=false;complex=true})


