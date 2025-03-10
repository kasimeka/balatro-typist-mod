function CardArea:__typist_toggle_card_by_index(index)
  local target = self.cards[index]
  if not target then
    play_sound("cancel")
    return
  end

  for _, c in ipairs(self.cards) do
    c:stop_hover()
  end

  target:click()

  target:hover()
  if G.E_MANAGER then
    G.E_MANAGER:add_event(Event {
      trigger = "after",
      delay = 6, -- seconds
      blockable = false,
      blocking = false,
      func = function()
        target:stop_hover()
        return true
      end,
    })
  end

  return true
end

return CardArea
