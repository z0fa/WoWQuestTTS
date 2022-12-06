local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon
local Settings = __module.Settings

local onLoad = Addon.onLoad
local useEffect = Addon.useEffect
local useHook = Addon.useHook


local module = {}

function module.init()
  local frame = AutoTurnIn

  if not frame or not Settings.hookAutoTurnIn.get() then
    return
  end



  Settings.autoStopRead.set(true)

  local function deferAction(self, ...)
    local args = { ... }

    C_Timer.After(
      1, function()
        self.__oldFn(self.__srcTable, unpack(args))
      end
    )
  end

  useHook("QUEST_GREETING", deferAction, "function", frame)
  useHook("GOSSIP_SHOW", deferAction, "function", frame)
  useHook("QUEST_DETAIL", deferAction, "function", frame)
  useHook("GOSSIP_SHOW", deferAction, "function", frame)
end



onLoad(
  function()
    module.init()
  end
)

__module.AutoTurnIn = module
