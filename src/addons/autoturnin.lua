local __namespace, __module = ...
local Addon = __module.Addon --- @class Addon
local Settings = __module.Settings --- @class Settings
local onLoad = Addon.onLoad
local useHook = Addon.useHook

onLoad(
  function()
    if not AutoTurnIn or not Settings.hookAutoTurnIn.value then
      return
    end

    Settings.autoStopRead.value = false

    local function deferAction(srcTable, oldFn)
      return function(...)
        local args = { ... }

        C_Timer.After(
          1, function()
            return oldFn(srcTable, unpack(args))
          end
        )
      end
    end

    local h1 = useHook("QUEST_GREETING", "function", AutoTurnIn)
    h1.apply(deferAction(h1.srcTable, h1.oldFn))

    local h2 = useHook("GOSSIP_SHOW", "function", AutoTurnIn)
    h2.apply(deferAction(h2.srcTable, h2.oldFn))

    local h3 = useHook("QUEST_DETAIL", "function", AutoTurnIn)
    h3.apply(deferAction(h3.srcTable, h3.oldFn))
  end
)
