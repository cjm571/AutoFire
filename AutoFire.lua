_addon.name = 'AutoFire'
_addon.author = 'CJ McAllister'
_addon.version = '0.1'

local res = require 'resources'

--slots = {"main", "sub", "range", "ammo", "head", "neck", "left_ear", "right_ear", "body", "hands", "left_ring", "right_ring", "back", "waist", "legs", "feet"}
local debug = true

------------------
-- Magic Numbers
------------------
local tick_key = 41
local backspace = 14
local ranged_delay_factor = 110 -- Factor by which the ranged weapon's delay is divided to get delay in seconds
local sec_wpn_return = 1.9 -- Seconds required to return the ranged weapon after firing
local sec_free_phase = 1.1 -- Seconds required for the "Free" phase of ranged attacking

------------------
-- Globals
------------------
local sec_base_delay = 999
local sec_total_delay = 999
local autofire = false
local firing_time = 0
local fired_this_second = false
local first_firing_second = 0

------------------
-- Helper Functions
------------------
-- Calculate the total delay in seconds given the current ranged weapon
function determine_delay()
    -- Turn off autofire when target changes
    autofire = false
    fired_this_second = false

    -- Get equipment table for use in get_items() calls
    local equipment = windower.ffxi.get_items()['equipment']

    -- Retrieve info on user's ranged weapon\
    local rng_wpn_id = windower.ffxi.get_items(equipment['range_bag'], equipment['range']).id
    local rng_wpn = res.items:with('id', rng_wpn_id)

    -- Set delay globally
    sec_base_delay = rng_wpn.delay / ranged_delay_factor
    sec_total_delay = math.ceil(sec_base_delay + sec_wpn_return + sec_free_phase)

    if debug then
        print('Calculated delay:', sec_total_delay)
    end
end

------------------
-- Event Handlers
------------------
-- Addon Load event handler
windower.register_event('load', function()
    if debug then
        print('AutoFire event: Load')
    end

    determine_delay()
end)

-- Target Change event handler
windower.register_event('target change', function(index)
    if debug then
        print('AutoFire event: Target Change')
    end

    determine_delay()
end)

-- Catch the AutoFire hotkey and begin AutoFiring
windower.register_event('keyboard', function(key, pressed, flags, blocked)
    -- Enable AutoFire with `
    if key == tick_key and pressed and flags == 0 then
        if debug then
            print('AutoFire Enabled')
        end
        autofire = true

        -- Only set firing_time if it is at its initial value to avoid accidental key press issues
        if firing_time == 0 then
            firing_time = os.time()
        end
    end
    -- Disable AutoFire with Shift+`
    if key == tick_key and pressed and flags == 1 then
        if debug then
            print('AutoFire Disabled')
        end
        autofire = false
        fired_this_second = false
    end
end)

-- Leverage the postrender event to autofire at the desired rate
-- TODO: Calculate mob's relative position and turn towards them
windower.register_event('postrender', function()
    if autofire then
        -- If we have not yet fired this second, fire! and record the second
        if fired_this_second == false then
            if debug then
                print('Firing!')
            end
            windower.chat.input('/ra')
            fired_this_second = true
            firing_time = os.time()

        -- Reset firing gate in the next second
        elseif fired_this_second == true and os.time() == firing_time+sec_total_delay then
            if debug then
                print('Reset fired_this_second!')
            end
            fired_this_second = false
        end
    end
end)