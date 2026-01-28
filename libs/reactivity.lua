local __namespace, __module = ...
local Array = __module.Array --- @class Array

local module = {} --- @class Reactivity

--- @class Ref
--- @field value unknown
--- @field sub fun(callbackFn: fun(newValue: unknown, oldValue: unknown)): fun()

--- @param initialValue unknown
--- @return Ref
function module.ref(initialValue)
  local value = initialValue
  local subs = Array.new()

  local function sub(callbackFn)
    subs:push(callbackFn)

    return function()
      subs = subs:filter(
        function(fn)
          return fn ~= callbackFn
        end
      )
    end
  end

  local function notify(newValue, oldValue)
    subs:forEach(
      function(callbackFn)
        callbackFn(newValue, oldValue)
      end
    )
  end

  return setmetatable(
    {}, {
      __index = function(_, key)
        if key == "value" then
          return value
        elseif key == "sub" then
          return sub
        elseif key == "__isRef" then
          return true
        end
      end,
      __newindex = function(_, key, newValue)
        if key == "value" then
          local oldValue = value

          if newValue ~= oldValue then
            value = newValue
            notify(newValue, oldValue)
          end
        end
      end,
    }
  )
end

--- @param source Ref | Ref[]
--- @param callbackFn fun(newValueOrValues: unknown | unknown[], oldValueOrValues: unknown | unknown[])
--- @param options? { immediate: boolean }
--- @return fun()
function module.watch(source, callbackFn, options)
  options = options or {}

  ---@diagnostic disable-next-line: undefined-field
  local isRef = source.__isRef
  local sources = isRef and Array.new({ source }) or Array.new(source)

  local oldValues = sources:map(
    function(ref)
      return ref.value
    end
  )

  local function notify()
    local newValues = sources:map(
      function(ref)
        return ref.value
      end
    )

    if isRef then
      callbackFn(newValues, oldValues)
    else
      callbackFn(newValues[1], oldValues[1])
    end

    oldValues = newValues
  end

  local subs = sources:map(
    function(ref)
      return ref.sub(
        function()
          notify()
        end
      )
    end
  )

  if options.immediate then
    notify()
  end

  return function()
    subs:forEach(
      function(unsub)
        unsub()
      end
    )
  end
end

__module.Reactivity = module
