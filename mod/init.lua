local layout = require("typist.mod.layout")

print(layout.tostring())

local debugplus_consoleHandleKey = require("debugplus.console")
  and require("debugplus.console").consoleHandleKey
if debugplus_consoleHandleKey then
  print("DebugPlus detected, moving it behind the `ctrl` key to avoid conflicts")
  local held_keys = G.CONTROLLER and G.CONTROLLER.held_keys
  local debugplus_consoleOpen = false
  require("debugplus.console").consoleHandleKey = function(key)
    if
      debugplus_consoleOpen
      or held_keys[layout.debug_leader_left]
      or held_keys[layout.debug_leader_right]
    then
      debugplus_consoleOpen = not debugplus_consoleHandleKey(key) or key == "/"
      return not debugplus_consoleOpen
    end
    return true
  end
end

if fhotkey then
  print("FlushHotkeys detected, unhooking it from the keyboard :)")
  Controller.key_press_update = assert(fhotkey.FUNCS.keyupdate_ref)
end

return function(Controller, key) -- order defines precedence
  -- if text input is active, skip over keybind handlers
  if G.CONTROLLER and G.CONTROLLER.text_input_hook then -- do nothing
  elseif layout.global_map[key] then
    layout.global_map[key]()
  elseif
    (function()
      for leader, area in pairs(layout.cardarea_map) do
        if Controller.held_keys[leader] then
          local a = area()
          return a and require("typist.mod.cardarea-handler")(a, key, Controller.held_keys)
        end
      end
    end)()
  then -- nothing :)
  elseif G.SETTINGS.paused then
    require("typist.mod.state-handlers")[G.STATES.MENU](key)
  elseif require("typist.mod.state-handlers")[G.STATE] then
    require("typist.mod.state-handlers")[G.STATE](key, Controller.held_keys)
  elseif key == "escape" then
    if not G.OVERLAY_MENU then G.FUNCS:options() end
  end

  -- can be invoked anywhere with no consideration for state or precedence
  if Controller.held_keys["d"] and key == "x" then
    debug.debug() -- start a lua console in the global context
  end
end
