package.path = package.path .. ";" .. debug.getinfo(1).source:match("@?(.*/)") .. "?.lua"
require 'tool'

function on_start_file()
    mp.register_event("playback-restart", on_playback_restart)
end

local next_pos_frac = -1
function on_file_loaded()
    if (next_pos_frac ~= -1) then
        mp.set_property_number("percent-pos",next_pos_frac*100)
        next_pos_frac = -1
    end
end

local is_first_frame_done = false
function on_playback_restart()
    mp.unregister_event(on_playback_restart)
    is_first_frame_done = true
end

local is_key_down = false
function on_fullscreen(_,value)
    if (not value) then
        is_key_down = false
    end
end

local assdraw = require 'mp.assdraw'
local ui = mp.create_osd_overlay("ass-events")
local ass = assdraw.ass_new()
local ui_on = false
function ui_update(name,value)
    if (value == nil) then return end
    if (not ui_on) then return end
    local playlist_count = mp.get_property_native("playlist-count")
    local playlist_pos = mp.get_property_native("playlist-pos")
    local percent_pos = mp.get_property_native("percent-pos")
    local osd_width, osd_height, _ = mp.get_osd_size()
    if (percent_pos == nil or playlist_pos == nil or playlist_count == nil) then return end
    if (osd_width == nil or osd_height == nil) then return end
    if (is_img()) then percent_pos = 100 end
    --
    local ass = assdraw.ass_new()
    ass:append("{\\pos(0,0)}{\\rDefault\\blur0\\bord0\\alpha&H00\\1c&H00CC00&}")
    ass:draw_start()
    local pos = (playlist_pos+percent_pos/100)/playlist_count
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
    if (is_key_down and is_first_frame_done) then
        walk()
    end
end

local last_pos = 0
function walk()
    local playlist_count = mp.get_property_native("playlist-count")
    local osd_width = mp.get_property_native("osd-width")
    local osd_height = mp.get_property_native("osd-height")
    local mouse = mp.get_property_native("mouse-pos")
    if (mouse.hover and mouse.y > 0.8*osd_height) then
        local x = playlist_count*mouse.x/osd_width
        next_pos = math.floor(x)
        next_pos_frac = x - next_pos
        if (last_pos ~= next_pos) then
            is_first_frame_done = false
            mp.set_property_number("playlist-pos",next_pos)
            last_pos = next_pos
        else
            mp.set_property_number("percent-pos",next_pos_frac*100)
        end
    end
end

local timer = nil
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
mp.observe_property("mouse-pos", "native", on_mouse_move)
mp.add_forced_key_binding("ENTER","ENTER",on_key,{repeatable=false;complex=true})
--mp.add_key_binding("MOUSE_LEAVE","MOUSE_LEAVE",function () print_time("MOUSE_LEAVE") end) won't work

