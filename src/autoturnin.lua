local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon

local onLoad = Addon.onLoad
local useHook = Addon.useHook
local useEvent = Addon.useEvent

local module = {}

local hook = false
local nop = function()
end
local nextAction = nop

function module.getFrame()
  return AutoTurnIn
end

function module.continue()
  nextAction()
  nextAction = nop
end

onLoad(
  function()
    if not module.getFrame() or not hook then
      return
    end

    useHook(
      "QUEST_DETAIL", function(self, ...)
        local args = { ... }

        nextAction = function()
          self.__oldFn(self.__srcTable, unpack(args))
        end
      end, "function", AutoTurnIn
    )

  end
)

__module.AutoTurnIn = module
