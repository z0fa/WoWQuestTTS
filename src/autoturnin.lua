local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon

local useEffect = Addon.useEffect
local useHook = Addon.useHook
local onLoad = Addon.onLoad

local module = {}
local hook = false

function module.init()
  local Main = __module.Main
  local isPlaying = Main.getState().isPlaying

  local frame = AutoTurnIn
  local nop = function()
  end
  local nextAction = nop

  if not frame or not hook then
    return
  end

  local function deferAction(self, ...)
    local args = { ... }

    nextAction = function()
      self.__oldFn(self.__srcTable, unpack(args))
    end
  end

  useHook("QUEST_GREETING", deferAction, "function", frame)
  useHook("GOSSIP_SHOW", deferAction, "function", frame)
  useHook("QUEST_DETAIL", deferAction, "function", frame)
  useHook("GOSSIP_SHOW", deferAction, "function", frame)

  useEffect(
    function()
      if isPlaying.get() then
        return
      end

      nextAction()
      nextAction = nop
    end, { isPlaying }
  )
end

onLoad(
  function()
    module.init()
  end
)

__module.AutoTurnIn = module
