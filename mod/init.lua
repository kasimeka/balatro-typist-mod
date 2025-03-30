local layout = require("typist.mod.layout")

print(layout.tostring())

G.SETTINGS.__typist = G.SETTINGS.__typist or {}

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
  elseif require("typist.mod.state-handlers")[G.STATE] and G.GAME.STOP_USE == 0 then
    require("typist.mod.state-handlers")[G.STATE](key, Controller.held_keys)
  end
end
