local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon

local useHook = Addon.useHook

local module = {}

-- useHook(
--   "QUEST_DETAIL", function(self)
--     C_Timer.After(2, self.__oldFnSelf)
--   end, "function", AutoTurnIn
-- )

-- local _QUEST_DETAIL = AutoTurnIn.QUEST_DETAIL
-- AutoTurnIn.QUEST_DETAIL = function(...)
--   local args = { ... }

--   useEvent(
--     function()
--       _QUEST_DETAIL(unpack(args))
--     end,
--     { "VOICE_CHAT_TTS_PLAYBACK_FINISHED", "VOICE_CHAT_TTS_PLAYBACK_FAILED" },
--     true
--   )
-- end

