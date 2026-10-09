-- The attack and block buttons. Valheim writes no sign of a swing, a draw
-- or a block anywhere the mod can read, so these feels follow the
-- controller: what plays depends on the attack feel the player picked.

local M = {}
local s = bururu.state
s.attack = { held = false, since = 0, full = false }
s.second_held = false
s.block_held = false

-- Valheim's buttons by the attack button: Classic and layout 2 attack
-- with R2, layout 1 with R1
local BUTTONS = {
  r2 = { attack = "r2", second = "r1", block = "l2" },
  r1 = { attack = "r1", second = "r2", block = "l1" },
}

-- a release sooner than this after the press is a tap, not a shot
local MIN_SHOT_MS = 150
-- the release of a short draw plays at least this strong
local MIN_SHOT_LEVEL = 0.4

local function down(p, name)
  if name == "r2" and p.r2_held then
    return true
  elseif name == "l2" and p.l2_held then
    return true
  end
  return p.held ~= nil and p.held[name] == true
end

-- play runs the attack hook point, then plays what it left
local function play(name, level, held_ms)
  local p = hook.run("attack@1", { feel = name, level = level, held_ms = held_ms, skip = false })
  if p.skip or type(p.feel) ~= "string" or not feel.exists(p.feel) then
    return
  end
  local scale = tonumber(p.level) or 0
  if scale > 0 then
    feel.play(p.feel, { scale = scale })
  end
end

-- on_pad: presses, holds and releases of the attack, second attack and
-- block buttons
function M.on_pad(t)
  local p = t.pad
  if p == nil or not p.ok then
    return
  end
  local set = t.settings
  local mode = set.attack_feel
  local b = BUTTONS[set.attack_button] or BUTTONS.r2
  local a = s.attack
  local draw_ns = (tonumber(set.bow_draw_ms) or 1200) * 1e6

  local attack = down(p, b.attack)
  if attack and not a.held then
    a.held, a.since, a.full = true, t.now, false
    if mode == "swing" then
      play("swing", 1, 0)
    elseif mode == "bow" then
      play("bow_nock", 1, 0)
    end
  elseif attack then
    if mode == "bow" and not a.full and t.now - a.since >= draw_ns then
      a.full = true
      play("bow_full", 1, (t.now - a.since) / 1e6)
    end
  elseif a.held then
    a.held = false
    local held_ms = (t.now - a.since) / 1e6
    if mode == "bow" and held_ms >= MIN_SHOT_MS then
      local draw = kit.clamp((t.now - a.since) / draw_ns, 0, 1)
      play("bow_release", MIN_SHOT_LEVEL + (1 - MIN_SHOT_LEVEL) * draw, held_ms)
    end
  end

  -- the second attack swings too; a bow has none
  local second = down(p, b.second)
  if second and not s.second_held and mode == "swing" then
    play("swing", 1, 0)
  end
  s.second_held = second

  local block = down(p, b.block)
  if block and not s.block_held then
    feel.play("block_raise")
  end
  s.block_held = block
end

-- silence: on idle ticks the buttons are forgotten, so a release after a
-- menu or alt-tab plays nothing
function M.silence(t)
  s.attack.held, s.attack.full = false, false
  s.second_held, s.block_held = false, false
end

return M
