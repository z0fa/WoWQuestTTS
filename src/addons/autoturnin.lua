local __namespace, __module = ...
local Addon = __module.Addon --- @class Addon
local Settings = __module.Settings --- @class Settings
local onLoad = Addon.onLoad
local useHook = Addon.useHook

onLoad(
  function()
    local frame = AutoTurnIn

    if not frame or not Settings.hookAutoTurnIn.value then
      return
    end

    Settings.autoStopRead.value = false

    local function deferAction(self, ...)
      local args = { ... }

      C_Timer.After(
        1, function()
          self.__oldFn(self.__srcTable, unpack(args))
        end
      )
    end

    useHook(deferAction, "QUEST_GREETING", "function", frame)
    useHook(deferAction, "GOSSIP_SHOW", "function", frame)
    useHook(deferAction, "QUEST_DETAIL", "function", frame)
    useHook(deferAction, "GOSSIP_SHOW", "function", frame)
  end
)
