-- Where the player is, from Valheim's Player.log: the main menu, a world,
-- or unknown while no menu or world line was read. Unknown drives like a
-- world, so the button feels work without the log.

local M = {}
local s = bururu.state
s.place = "unknown"

-- the line rules of sensors.json that mean something in the game; the
-- others only mark names for redaction
local GAME_LINES = { menu = true, world = true, raid = true, sleep = true }

local CONTEXT = { menu = "main menu", world = "in a world", unknown = "playing" }
local SHOWN = { menu = "Main menu", world = "In a world", unknown = "Unknown" }

local function set_place(place)
  if s.place ~= place then
    s.place = place
    status.fact("place", SHOWN[place])
  end
end

-- on_line is the handler of every log line rule (log:<rule>)
function M.on_line(ev)
  local rule = string.sub(ev.input, 5)
  if not GAME_LINES[rule] then
    return
  end
  -- the menu and world lines say where the player is
  if rule == "menu" or rule == "world" then
    set_place(rule)
  end
  hook.run("state@1", { place = s.place, line = rule })
end

-- on_closed: Valheim ended; its next start writes a new Player.log
function M.on_closed()
  set_place("unknown")
end

-- on_status keeps the setup item of the log up to date
function M.on_status(ev)
  if ev.id ~= "log" then
    return
  end
  if ev.state == "ok" then
    setup.item("log", "ok")
  elseif ev.state == "unavailable" or ev.state == "error" then
    setup.item("log", "warn", ev.text)
  end
end

-- facts: in control everywhere but the main menu, while Valheim's window
-- is in front (its buttons then reach the game)
function M.facts(t)
  local place = s.place
  local game = sensors.game
  local in_front = game == nil or game.in_front ~= false
  return { active = place ~= "menu" and in_front, menu = place == "menu", context = CONTEXT[place] }
end

status.fact("place", SHOWN[s.place])

return M
