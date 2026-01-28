local __namespace, __module = ...
local Array = __module.Array --- @class Array
local Reactivity = __module.Reactivity --- @class Reactivity
local Addon = __module.Addon --- @class Addon
local CrossExp = __module.CrossExp --- @class Addon
local Settings = __module.Settings
local GameSettings = _G["Settings"]

local ref = Reactivity.ref
local watch = Reactivity.watch
local onInit = Addon.onInit
local onLoad = Addon.onLoad
local useEvent = Addon.useEvent
local useSlashCmd = Addon.useSlashCmd
local useHook = Addon.useHook
local print = Addon.print
local useGossipUpdateHook = CrossExp.useGossipUpdateHook

local module = {}

local isPlaying = ref(false)
local textHistory = Array.new()
local alertVersion = 1
-- Some variables to use for narrated text
local narratorTag = "narrator" -- tag to distinguish normal text from narrated one [narratorTag]nareted text[/narratorTag]
local speechQueue = {} -- queue of text segments, segment is structured as { text: string, voiceID: integer}

onInit(
  function()
    QuestTTSAddon = {}
    QuestTTSAddon.name = __namespace

    QuestTTSAddon.keybindReadQuest = function(...)
      module.ttsToggle()
    end
  end
)

onLoad(
  function()
    module.initPlayButton(module.ttsToggle, module.openSettings)

    Settings.alert.value = alertVersion
    -- if (alertVersion > Settings.alert.value) then
    --   print("...")

    --   Settings.alert.value = alertVersion
    -- end
  end
)

useEvent(
  function()
    isPlaying.value = false
    -- when current speech is completed try to speck next segment
    module.processNextSpeechSegment()
  end, { "VOICE_CHAT_TTS_PLAYBACK_FINISHED", "VOICE_CHAT_TTS_PLAYBACK_FAILED" }
)

useSlashCmd(
  function(cmd)
    if cmd == "play" then
      module.ttsToggle()
      print("Playing...")
    elseif cmd == "stop" then
      module.ttsStop()
      print("Stopping...")
    elseif cmd == "settings" then
      module.openSettings()
    end
  end, { "qtts" }
)

useGossipUpdateHook(
  function(self, frame)
    if not frame:IsShown() then
      return
    end

    module.ttsAutoPlay("gossip")
  end
)
useHook(
  function()
    module.ttsAutoStop()
  end, "OnHide", "secure-widget", GossipFrame
)

useHook(
  function(self, frame, event)
    if not frame:IsShown() then
      return
    end

    if event == "QUEST_GREETING" then
      module.ttsAutoPlay("quest:greeting")
    elseif event == "QUEST_DETAIL" then
      module.ttsAutoPlay("quest:detail")
    elseif event == "QUEST_PROGRESS" then
      module.ttsAutoPlay("quest:progress")
    elseif event == "QUEST_COMPLETE" then
      module.ttsAutoPlay("quest:reward")
    end
  end, "OnEvent", "secure-widget", QuestFrame
)
useHook(
  function()
    module.ttsAutoStop()
  end, "OnHide", "secure-widget", QuestFrame
)

function module.ttsAutoPlay(source)
  if source:find("quest") and not Settings.autoReadQuest.value then
    return
  elseif source:find("gossip") and not Settings.autoReadGossip.value then
    return
  end

  if isPlaying.value then
    module.ttsAutoStop()
  end

  local text = module.getText(source)

  local isRecentText = textHistory:some(
    function(element, index, array)
      return element == text
    end
  )

  textHistory:unshift(text)
  textHistory = textHistory:slice(1, 10)

  if isRecentText and Settings.skipRecentText.value then
    return
  end

  C_Timer.After(
    0.1, function()
      module.ttsPlay(text)
    end
  )
end

function module.ttsAutoStop()
  if not Settings.autoStopRead.value then
    return
  end

  module.ttsStop()
end

function module.ttsToggle(source)
  if isPlaying.value then
    module.ttsStop()
  else
    module.ttsPlay(module.getText(source))
  end
end

-- Function to process speechQueue waiting for previous segment to finish (without it sometimes the text segments were swaped for no reason)
function module.processNextSpeechSegment()
  -- Just quit if queue is empty or stil pseakinf
  if #speechQueue == 0 or isPlaying.value then
    return
  end
  -- Start processing next segment
  isPlaying.value = true
  local segment = table.remove(speechQueue, 1)
  -- Speak the text
  CrossExp.speakText(
    segment.voiceID, segment.text, Settings.voiceSpeed.value,
    Settings.voiceVolume.value
  )
end

-- Function to parse text with narratorTags and make an array of segments { text: string, voiceID: integer }
function module.processAndSplitNarrator(text, actorVoiceID, narratorVoiceID)
  -- Split the text by [narratorTag][/narratorTag] tags and track the text
  local toRet = {}
  local lastPos = 1
  -- Pattern to capture text outside and inside [narratorTag] tags
  for outsideText, insideText in text:gmatch(
    "(.-)%[" .. narratorTag .. "%](.-)%[/" .. narratorTag .. "%]"
  ) do
    -- Add text outside [narratorTag][/narratorTag] tags
    if outsideText ~= "" then
      table.insert(toRet, { text = outsideText, voiceID = actorVoiceID })
    end
    -- Add text inside [narratorTag][/narratorTag] tags
    table.insert(toRet, { text = insideText, voiceID = narratorVoiceID })
    -- Update lastPos to the end of the current match
    lastPos = lastPos + #outsideText + #insideText + (#narratorTag * 2 + 5)
  end
  -- Capture any remaining text after the last match
  if lastPos <= #text then
    local remainingText = text:sub(lastPos)
    if remainingText ~= "" then
      table.insert(toRet, { text = remainingText, voiceID = actorVoiceID })
    end
  end
  return toRet
end

function module.ttsPlay(text)
  if Settings.useNarrator.value then
    -- Parse text into segments (narrated and normal)
    local actorVoiceID = module.getVoice().voiceID
    local narratorVoiceID = Settings.voice3.value
    local narratedText = module.processAndSplitNarrator(
      text, actorVoiceID, narratorVoiceID
    )
    for _, segment in ipairs(narratedText) do
      -- Check if there is anything to speak and if so, insert into queue
      if segment.text ~= nil and segment.text:match("^%s*$") == nil then
        table.insert(speechQueue, segment)
      end
    end
    -- Proccess first segment of the queue (following ones will be triggered by TTS events as mentioned above in UseEvent)
    module.processNextSpeechSegment()
  else
    isPlaying.value = true
    CrossExp.speakText(
      module.getVoice().voiceID, text, Settings.voiceSpeed.value,
      Settings.voiceVolume.value
    )
  end
end

function module.ttsStop()
  -- Empty speechQueue
  speechQueue = {}
  C_VoiceChat.StopSpeakingText()
end

-- Add <> for any text we want to be narrated
function module.getText(source)
  local toRet = ""

  source = module.guessSource(source)

  if source == "gossip" then
    local npcName = UnitName("npc")
    local gossip = CrossExp.getGossipText()

    if Settings.readNpcName.value then
      toRet = toRet .. "\n<" .. npcName .. ":>"
    end

    toRet = toRet .. "\n" .. gossip .. "."
  elseif source == "quest:focused" then
    local title = CrossExp.getQuestLogTitle()
    local description, objective = GetQuestLogQuestText()

    if Settings.readTitle.value then
      toRet = toRet .. "\n<" .. title .. ".>"
    end

    toRet = toRet .. "\n" .. description .. "."

    if Settings.readObjective.value then
      toRet = toRet .. "\n<" .. objective .. ".>"
    end
  elseif source == "quest:greeting" then
    local npcName = UnitName("npc")
    -- local title = GetTitleText()
    local greeting = GetGreetingText()

    if Settings.readNpcName.value then
      toRet = toRet .. "\n<" .. npcName .. ":>"
    end

    toRet = toRet .. "\n" .. greeting .. "."
  elseif source == "quest:detail" then
    local title = GetTitleText()
    local description = GetQuestText()
    local objective = GetObjectiveText()

    if Settings.readTitle.value then
      toRet = toRet .. "\n<" .. title .. ".>"
    end

    toRet = toRet .. "\n" .. description .. "."

    if Settings.readObjective.value then
      toRet = toRet .. "\n<" .. objective .. ".>"
    end
  elseif source == "quest:progress" then
    -- local title = GetTitleText()
    local progress = GetProgressText()

    toRet = toRet .. "\n" .. progress .. "."
  elseif source == "quest:reward" then
    -- title = GetTitleText()
    local reward = GetRewardText()

    toRet = toRet .. "\n" .. reward .. "."
  elseif source == "book:1" then
    local title = ItemTextGetItem()
    local description = ItemTextGetText()

    if Settings.readTitle.value then
      toRet = toRet .. "\n<" .. title .. ".>"
    end

    toRet = toRet .. "\n" .. description .. "."
  elseif source and source:find("^book:") then
    local description = ItemTextGetText()

    toRet = toRet .. "\n" .. description .. "."
  end

  if Settings.useNarrator.value then
    -- Replace any <...> tag with [narratorTag]...[/narratorTag]
    toRet = toRet:gsub(
      "<(.-)>", "[" .. narratorTag .. "]%1[/" .. narratorTag .. "]"
    )
  else
    toRet = toRet:gsub("<", ""):gsub(">", "")
  end

  return toRet
end

function module.guessSource(source)
  local toRet = source

  if source == nil and CrossExp.isQuestFrameShown() then
    toRet = "quest"
  elseif source == nil and GossipFrame:IsShown() then
    toRet = "gossip"
  elseif source == nil and ItemTextFrame:IsShown() then
    toRet = "book"
  end

  source = toRet

  if source == "quest" and QuestFrameGreetingPanel:IsShown() then
    toRet = "quest:greeting"
  elseif source == "quest" and QuestFrameProgressPanel:IsShown() then
    toRet = "quest:progress"
  elseif source == "quest" and QuestFrameRewardPanel:IsShown() then
    toRet = "quest:reward"
  elseif source == "quest" and QuestFrame:IsShown() then
    toRet = "quest:detail"
  elseif source == "quest" then
    toRet = "quest:focused"
  elseif source == "book" then
    toRet = "book:" .. ItemTextGetPage()
  end

  return toRet
end

function module.getVoice()
  local toRet = Settings.voice1.value
  local unitSex = UnitSex("questnpc") or UnitSex("npc")

  if unitSex == 2 then -- male
    toRet = Settings.voice1.value
  elseif unitSex == 3 then -- female
    toRet = Settings.voice2.value
  else
    toRet = Settings.voice3.value
  end

  local voices = Array.new(C_VoiceChat.GetTtsVoices())
  local voiceToRet = voices:find(
    function(v)
      return v.voiceID == toRet
    end
  )

  return voiceToRet
end

function module.openSettings()
  GameSettings.OpenToCategory(Settings.CATEGORY_ID)
end

function module.initPlayButton(onLeftClick, onRightClick)
  local function factory(parent, x, y, source)
    local toRet = CreateFrame("Button", nil, parent)

    toRet:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    toRet:SetHighlightTexture(
      "Interface\\Buttons\\UI-Common-MouseHilight", "ADD"
    )
    toRet:SetPoint("TOPRIGHT", x, y)
    toRet:SetWidth(22)
    toRet:SetHeight(22)
    toRet:SetFrameStrata("HIGH")
    toRet:RegisterForClicks("LeftButtonUp", "RightButtonDown")
    toRet:SetScript(
      "OnClick", function(_, event)
        if event == "RightButton" then
          onRightClick()
        else
          onLeftClick(source)
        end
      end
    )

    return toRet
  end

  local buttons = Array.new()

  CrossExp.initPlayButton(buttons, factory)

  watch(
    { isPlaying }, function(newValue, oldValue)
      if newValue then
        buttons:forEach(
          (function(button)
            button:SetNormalTexture("Interface\\TimeManager\\PauseButton")
          end)
        )
      else
        buttons:forEach(
          (function(button)
            button:SetNormalTexture(
              "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"
            )
          end)
        )
      end
    end
  )
end

function module.getState()
  return { isPlaying = isPlaying }
end

__module.Main = module
