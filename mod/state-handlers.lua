require("typist.mod.cardarea-ext")

local tu = require("typist.lib.tblutils")

local cardarea_handler = require("typist.mod.cardarea-handler")
local hand = require("typist.mod.hand")
local layout = require("typist.mod.layout")

local multiplayer_compat = require("typist.compat.multiplayer")

local M = {}

local cheat_layer
M[G.STATES.SELECTING_HAND] = function(key, held_keys)
  if held_keys[layout.preview_deck] and not G.deck_preview then
    G.deck_preview = UIBox {
      definition = G.UIDEF.deck_preview(),
      config = { align = "tm", offset = { x = 0, y = -0.8 }, major = G.hand, bond = "Weak" },
    }
    G.E_MANAGER:add_event(Event {
      blocking = false,
      blockable = false,
      func = function()
        if
          G.deck_preview and not (tu.dig(G, { "CONTROLLER", "held_keys", layout.preview_deck }))
        then
          G.deck_preview:remove()
          G.deck_preview = nil
          return true
        end
      end,
    })
  end

  if held_keys[layout.cheat.leader_right] or held_keys[layout.cheat.leader_left] then
    cheat_layer(key, held_keys)

  -- toggle card by position in hand
  elseif layout.free_select_map[key] then
    G.hand:__typist_toggle_card_by_index(layout.free_select_map[key])

  -- play hand
  elseif
    key == layout.proceed
    and G.buttons
    and G.buttons:get_UIE_by_ID("play_button").config.button
  then
    G.FUNCS.play_cards_from_highlighted()

  -- discard hand
  elseif
    key == layout.dismiss
    and G.buttons
    and G.buttons:get_UIE_by_ID("discard_button").config.button
  then
    G.FUNCS.discard_cards_from_highlighted()
  elseif key == layout.hand.invert_selection then
    hand.invert_selection()
  elseif key == layout.hand.deselect_all then
    G.hand:unhighlight_all()
    play_sound("cardSlide2", nil, 0.3)

  -- select the leftmost 5 cards
  elseif key == layout.hand.left5 then
    hand.left5()
  -- select the rightmost 5 cards
  elseif key == layout.hand.right5 then
    hand.right5()

  --
  elseif key == layout.hand.sort_by_rank then
    G.FUNCS.sort_hand_value(nil)
  elseif key == layout.hand.sort_by_suit then
    G.FUNCS.sort_hand_suit(nil)
  elseif key == layout.hand.reorder_by_enhancements then
    hand.reorder_by_enhancements()
  end
end

local best_hand = require("typist.compat.fhotkey").best_hand_impl()
cheat_layer = function(key, held_keys)
  -- best hand overall
  if key == layout.cheat.best_hand then
    best_hand(held_keys[layout.cheat.reverse_left] or held_keys[layout.cheat.reverse_right])
  -- best flush
  elseif key == layout.cheat.best_flush then
    hand.flush(hand.best_flush_suit())
  --[[ elseif key == layout.cheat.best_high_card then
    hand.best_high_card()
  elseif key == layout.cheat.worst_high_card then
    hand.worst_high_card() ]]
  -- select by suit
  elseif layout.cheat.suits_map[key] then
    hand.flush(layout.cheat.suits_map[key])
  -- select by rank - avoid conflict with leader keys when not being used as a shortcut
  elseif layout.cheat.ranks_map[key] then
    if -- only allow a leader key to pass when another leader key is held
      not (key == layout.cheat.leader_left or key == layout.cheat.leader_right)
      or (key == layout.cheat.leader_left and held_keys[layout.cheat.leader_right])
      or (key == layout.cheat.leader_right and held_keys[layout.cheat.leader_left])
    then
      hand.by_rank(layout.cheat.ranks_map[key])
    end
  -- because why not
  elseif
    key == layout.proceed
    and G.buttons
    and G.buttons:get_UIE_by_ID("play_button").config.button
  then
    G.FUNCS.play_cards_from_highlighted()
  elseif
    key == layout.dismiss
    and G.buttons
    and G.buttons:get_UIE_by_ID("discard_button").config.button
  then
    G.FUNCS.discard_cards_from_highlighted()
  end
end

M[G.STATES.ROUND_EVAL] = function(key)
  if key == layout.proceed or key == layout.enter then
    local cash_out_button
    for e, _ in pairs(G.__typist_ORPHANED_UIBOXES) do
      cash_out_button = e:get_UIE_by_ID("cash_out_button")
      if cash_out_button and cash_out_button.config.button then
        G.FUNCS.cash_out(cash_out_button)
        return
      end
    end
  end
end

-- pseudo-CardArea object to manipulate the shop as if it's one hand
local shop = setmetatable({}, { __index = { __typist_shop = true } })
-- stylua: ignore
local to_big = to_big or function(x) return x end -- talisman compat
M[G.STATES.SHOP] = function(key)
  -- reroll shop
  if
    key == layout.reroll
    and (
      to_big(G.GAME.dollars) - to_big(G.GAME.current_round.reroll_cost)
      >= to_big(G.GAME.bankrupt_at)
    )
  then
    G.FUNCS.reroll_shop()

  -- switch to blind select
  elseif key == layout.dismiss or key == layout.enter then
    G.FUNCS.toggle_shop()

  -- handle shop card actions
  elseif
    cardarea_handler(
      (function()
        shop.cards =
          tu.list_concat(G.shop_jokers.cards, G.shop_vouchers.cards, G.shop_booster.cards)
        shop.highlighted = tu.list_concat(
          G.shop_jokers.highlighted,
          G.shop_vouchers.highlighted,
          G.shop_booster.highlighted
        )
        return shop
      end)(),
      key
    )
  then -- do nothing
  end
end

M[G.STATES.BLIND_SELECT] = function(key)
  -- select blind
  if key == layout.proceed or key == layout.enter then
    local e =
      G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]:get_UIE_by_ID("select_blind_button")

    if not multiplayer_compat.pvp_toggle_ready(e) then G.FUNCS.select_blind(e) end

  -- skip blind
  elseif key == layout.skip then
    G.FUNCS.skip_blind(
      G.blind_select_opts[string.lower(G.GAME.blind_on_deck)]:get_UIE_by_ID("blind_extras")
    )

  -- reroll boss
  elseif key == layout.reroll then
    if
      (
        (G.GAME.used_vouchers["v_directors_cut"] and not G.GAME.round_resets.boss_rerolled)
        or G.GAME.used_vouchers["v_retcon"]
      ) and G.GAME.dollars - 10 >= G.GAME.bankrupt_at
    then
      G.FUNCS.reroll_boss()
    end
  else -- TODO: find and hover the current tag?
  end
end

-- close splash screen on any key press
M[G.STATES.SPLASH] = function()
  G:delete_run() -- this just deletes the run from global state, no save files affected
  G:main_menu()
end

M[G.STATES.MENU] = function(key)
  -- main menu
  if G.MAIN_MENU_UI and not G.SETTINGS.paused then
    -- the play button :)
    if key == layout.proceed then
      local the_play_button = G.MAIN_MENU_UI:get_UIE_by_ID("main_menu_play")
      if the_play_button then
        G.FUNCS.setup_run(the_play_button)
      else
        multiplayer_compat.lobby_start_game()
      end
    end
  elseif G.OVERLAY_MENU then
    -- if on game over screen
    local new_run_button = G.OVERLAY_MENU:get_UIE_by_ID("from_game_over")
      or G.OVERLAY_MENU:get_UIE_by_ID("from_game_won")
    local game_end_screen = not not new_run_button

    if key == layout.proceed then
      -- go to deck selection
      if game_end_screen then
        G.FUNCS.notify_then_setup_run(new_run_button)

      -- if a playable deck is in view
      elseif
        (
          G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. localize("b_continue"))
          or G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. localize("b_new_run"))
        ) and tu.dig(G.GAME, { "viewed_back", "effect", "center", "unlocked" })
      then
        G.FUNCS.start_setup_run { config = { id = {} } }
      end

    --
    elseif key == layout.escape or key == layout.dismiss then
      -- go to main menu
      if game_end_screen then
        G.FUNCS.go_to_menu()

      -- if an exitable menu is visible
      elseif not G.OVERLAY_MENU.config.no_esc then
        -- close it
        G.FUNCS:exit_overlay_menu()

      -- work around for a game bug that leaves you stuck on new run menu when triggered from the game over screen
      elseif G.OVERLAY_MENU:get_UIE_by_ID("tab_but_" .. localize("b_new_run")) then
        -- navigate to the main menu instead
        G.FUNCS.go_to_menu()
      end

    --
    elseif key == layout.enter then
      -- start endless mode
      if tu.dig(new_run_button, { "config", "id" }) == "from_game_won" then
        G.FUNCS:exit_overlay_menu()

      -- or if u lost and have Taikomochi, retry the ante
      elseif -- TODO: rely only on `get_UIE_by_ID`, needs a change to Taikomochi
        tu.dig(new_run_button, { "parent", "children", 1, "config", "button" })
          == "zen_restart_ante"
        or G.OVERLAY_MENU:get_UIE_by_ID("zen_restart_ante")
      then
        G.FUNCS.zen_restart_ante()
      end
    end
  end
end

local pack_event = { config = {} }
M[G.STATES.STANDARD_PACK] = function(key)
  if key == layout.dismiss then
    if G.FUNCS.can_skip_booster(pack_event) or pack_event.config.button then
      G.FUNCS.skip_booster(pack_event)
    end
  else
    cardarea_handler(G.pack_cards, key)
  end
end
M[G.STATES.PLANET_PACK] = M[G.STATES.STANDARD_PACK]
M[G.STATES.SPECTRAL_PACK] = M[G.STATES.STANDARD_PACK]
M[G.STATES.BUFFOON_PACK] = M[G.STATES.STANDARD_PACK]
M[G.STATES.TAROT_PACK] = M[G.STATES.STANDARD_PACK]
if G.STATES.SMODS_BOOSTER_OPENED then
  M[G.STATES.SMODS_BOOSTER_OPENED] = M[G.STATES.STANDARD_PACK]
end

return M
