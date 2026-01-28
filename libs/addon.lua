local __namespace, __module = ...
local Array = __module.Array --- @class Array
local Reactivity = __module.Reactivity --- @class Reactivity
local ref = Reactivity.ref
local watch = Reactivity.watch

local module = {} --- @class Addon

local frame = CreateFrame("Frame", nil)
local onLoadHooks = Array.new()
local onReadyHooks = Array.new()
local onUpdateHooks = Array.new()
local debugValues = {} --- @type table<string, any>
local listeners = {} --- @type table<WowEvent, Array>

--- @class SavedVariableRef
--- @field ref Ref
--- @field globalName string
--- @field varName string
--- @field defaultValue unknown

--- comment
--- @param globalName string
--- @param varName string
--- @param defaultValue unknown
--- @return SavedVariableRef
function module.useSavedVariable(globalName, varName, defaultValue)
  local state = ref(defaultValue)

  local toRet = setmetatable(
    {}, {
      __index = function(t, k)
        if k == "globalName" then
          return globalName
        elseif k == "varName" then
          return varName
        elseif k == "defaultValue" then
          return defaultValue
        else
          return state[k]
        end
      end,
      __newindex = function(t, k, v)
        state[k] = v
      end,
    }
  )

  module.onLoad(
    function()
      _G[globalName] = _G[globalName] or {}

      if (_G[globalName][varName] == nil) then
        _G[globalName][varName] = defaultValue
      end

      -- toRet.value = _G[globalName][varName]
      print(
        "globalName:", globalName, "varName:", varName, "value:",
        _G[globalName][varName]
      )
    end
  )

  watch(
    toRet, function(newValue, oldValue)
      _G[globalName][varName] = newValue
    end
  )

  return toRet
end

--- @class EventContext
--- @field unsub fun()

--- comment
--- @param fn fun(context: EventContext, eventName: string, ...)
--- @param events WowEvent[]
--- @return EventContext
function module.useEvent(fn, events)
  local eventsArray = Array.new(events or {})

  local context = {
    unsub = function()
    end,
  }

  local function handler(...)
    return fn(context, ...)
  end

  context.unsub = function()
    eventsArray:forEach(
      function(event)
        listeners[event] = listeners[event]:filter(
          function(h)
            return h ~= handler
          end
        )

        if listeners[event]:length() == 0 then
          frame:UnregisterEvent(event)
        end
      end
    )
  end

  eventsArray:forEach(
    function(event)
      if not listeners[event] then
        frame:RegisterEvent(event)
        listeners[event] = Array.new()
      end

      listeners[event]:push(handler)
    end
  )

  return context
end

--- comment
--- @param fn fun(arg1?: string, arg2?: string, arg3?: string)
--- @param aliases string[]
function module.useSlashCmd(fn, aliases)
  local cmdsArray = Array.new(aliases)
  local name = aliases[1]:upper()

  cmdsArray:forEach(
    function(cmd, index)
      _G["SLASH_" .. name .. index] = "/" .. cmd
    end
  )

  SlashCmdList[name] = function(msg)
    local args = {}

    for arg in msg:gmatch("%S+") do
      table.insert(args, arg)
    end

    fn(unpack(args))
  end
end

--- @class HookContext
--- @field unhook fun()

--- comment
--- @param fn fun(context: HookContext, ...)
--- @param fnName string
--- @param hookType? "function" | "secure-function" | "widget" | "secure-widget"
--- @param srcTable? table
--- @return HookContext
function module.useHook(fn, fnName, hookType, srcTable)
  hookType = hookType or "function"
  srcTable = srcTable or _G

  local enabled = true
  local oldFn = nil
  local hookProxy = {}

  local context = {
    unhook = function()
      enabled = false
    end,
  }

  local hookFn = function(...)
    return hookProxy(...)
  end

  setmetatable(
    hookProxy, {
      __call = function(...)
        if not enabled and oldFn then
          return oldFn(...)
        elseif not enabled then
          return
        end

        return fn(context, ...)
      end,
      __index = function(t, k)
        if k == "__enabled" then
          return enabled
        elseif k == "__oldFn" then
          return oldFn
        elseif k == "__srcTable" then
          return srcTable
        elseif type(srcTable[k]) == "function" then
          return function(_, ...)
            return srcTable[k](srcTable, ...)
          end
        else
          return srcTable[k]
        end
      end,
      __newindex = function(t, k, v)
        if k == "__enabled" then
          enabled = v
        elseif k == "__oldFn" then
          oldFn = v
        else
          srcTable[k] = v
        end
      end,
    }
  )

  if hookType == "function" then
    oldFn = srcTable[fnName]
    srcTable[fnName] = hookFn
  elseif hookType == "secure-function" and srcTable then
    hooksecurefunc(srcTable, fnName, hookFn)
  elseif hookType == "secure-function" then
    hooksecurefunc(fnName, hookFn)
  elseif hookType == "widget" then
    oldFn = srcTable:GetScript(fnName)
    srcTable:SetScript(fnName, hookFn)
  elseif hookType == "secure-widget" then
    srcTable:HookScript(fnName, hookFn)
  end

  return context
end

--- comment
--- @param label string
--- @param dep Ref
function module.useDebugValue(label, dep)
  watch(
    dep, function(newValue, debugValue)
      debugValues[label] = newValue
    end, { immediate = true }
  )
end

--- comment
--- @param fn function
function module.nextTick(fn)
  C_Timer.After(0, fn)
end

--- comment
--- @param msg any
function module.print(msg)
  print("|cffff8000" .. __namespace .. ": |r" .. tostring(msg))
end

--- comment
--- @param fn fun()
function module.onLoad(fn)
  onLoadHooks:push(fn)
end

--- comment
--- @param fn fun()
function module.onInit(fn)
  fn()
end

--- comment
--- @param fn fun(isLogin: boolean, isReload: boolean)
function module.onReady(fn)
  onReadyHooks:push(fn)
end

--- comment
--- @param fn fun(delta: number)
function module.onUpdate(fn)
  onUpdateHooks:push(fn)

  if not frame:GetScript("OnUpdate") then
    frame:SetScript(
      "OnUpdate", function(frame, delta)
        onUpdateHooks:forEach(
          function(fn)
            fn(delta)
          end
        )
      end
    )
  end
end

frame:SetScript(
  "OnEvent", function(frame, event, ...)
    local handlers = listeners[event] or Array.new()
    local args = { ... }

    handlers:forEach(
      function(handler)
        handler(event, unpack(args))
      end
    )
  end
)

module.useEvent(
  function(context, eventName, addonName)
    if addonName == __namespace then
      onLoadHooks:forEach(
        function(fn)
          fn()
        end
      )

      module.nextTick(
        function()
          if next(debugValues) == nil then
            return
          end

          if not IsAddOnLoaded("Blizzard_DebugTools") then
            UIParentLoadAddOn("Blizzard_DebugTools")
          end

          local inspector = DisplayTableInspectorWindow(debugValues)
          inspector:SetDynamicUpdates(true)
        end
      )
    end
  end, { "ADDON_LOADED" }
)

module.useEvent(
  function(context, eventName, ...)
    local args = { ... }

    onReadyHooks:forEach(
      function(fn)
        fn(unpack(args))
      end
    )
  end, { "PLAYER_ENTERING_WORLD" }
)

module.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
module.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
module.isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
module.isWOTLK = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
module.isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
module.isMoP = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC

__module.Addon = module
