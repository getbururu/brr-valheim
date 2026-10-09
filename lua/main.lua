-- Valheim as a mod: every handler, in the order a tick runs them.
-- Handlers of one kind run in the order they are registered.

local session = require("session") -- where the player is, from Player.log
local combat  = require("combat")  -- the attack and block buttons

-- Reading: the log, then the facts
bururu.on("log:*", session.on_line)            -- every line rule of the log
bururu.on("game:closed", session.on_closed)    -- the next start writes a new log
bururu.on("sensor:status", session.on_status)  -- the setup item: is the log there
bururu.facts(session.facts)                    -- active, menu, context

-- Idle ticks: the game is not in front, or haptics are off
bururu.on_idle(combat.silence)                 -- forget the buttons held

-- Driving: the buttons, each tick
bururu.on_pad(combat.on_pad)                   -- swing, bow and block feels
