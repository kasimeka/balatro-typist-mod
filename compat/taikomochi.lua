local M = {}

M.zen_restart_ante = function()
  if G.OVERLAY_MENU:get_UIE_by_ID("zen_restart_ante") then
    G.FUNCS.zen_restart_ante()
    return true
  end
end

return M
