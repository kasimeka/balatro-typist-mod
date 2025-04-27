local layout = require("typist.mod.layout")

local M = {}
M.init = function()
  if not pcall(require, "debugplus.console") then return end

  require("typist.lib.log")(
    "DebugPlus detected, moving it behind the `ctrl` key to avoid conflicts"
  )

  local held_keys = assert(
    G.CONTROLLER and G.CONTROLLER.held_keys,
    "you're loading me before the controls are initialized :("
  )

  local consoleOpen = false
  local consoleHandleKey = require("debugplus.console").consoleHandleKey
  require("debugplus.console").consoleHandleKey = function(key)
    if
      consoleOpen
      or held_keys[layout.debug_leader_left]
      or held_keys[layout.debug_leader_right]
    then
      --
      -- in DebugPlus v1.4.1, the thing™ is only true if the console is closed
      -- and we're signaling for another thing to open it :)
      local the_thing = consoleHandleKey(key)
      consoleOpen = (
        not the_thing -- so as long as the thing is false, we're in the console
        or key == "/" -- if the thing is true & key is "/", we're opening the console on the next frame
      )
        and key ~= "escape" -- if the thing is false and key is "escape", we've just closed the console
      -- NOTE: the addition of new keybinds that change the console's state will break this :)

      -- NOTE: `shift+/` to toggle console preview is now `ctrl+shift+/`,
      -- but backspace, arrows and other in-console thingies work as normal

      return the_thing
    end
    return true
  end
end
return M
