local __namespace, __module = ...

local Array = __module.Array --- @class Array
local Addon = __module.Addon --- @class Addon

local onInit = Addon.onInit
local onLoad = Addon.onLoad
local wrap = Addon.wrap
local useState = Addon.useState
local useEffect = Addon.useEffect
local useEvent = Addon.useEvent
local useSlashCmd = Addon.useSlashCmd
-- local useDebugValue = Addon.useDebugValue
local useSavedVariable = Addon.useSavedVariable
local print = Addon.print

local module = {}

local isPlaying = useState(false)
local globalDB = "QuestTTSGlobalDB"
local alertVersion = 1
local settings = {
  readTitle = useSavedVariable(globalDB, "readTitle", true),
  readObjective = useSavedVariable(globalDB, "readObjective", true),
  voice1 = useSavedVariable(globalDB, "voice1", Enum.TtsVoiceType.Standard),
  voice2 = useSavedVariable(globalDB, "voice2", Enum.TtsVoiceType.Standard),
  voice3 = useSavedVariable(globalDB, "voice3", Enum.TtsVoiceType.Standard),
  alert = useSavedVariable(globalDB, "alert", 0),
}

onInit(
  function()
    BINDING_HEADER_QUESTTTS = __namespace

    QuestTTSAddon = {}
    QuestTTSAddon.name = __namespace
    QuestTTSAddon.registerCheckSetting = wrap(module, "registerCheckSetting")
    QuestTTSAddon.registerVoiceSetting = wrap(module, "registerVoiceSetting")
    QuestTTSAddon.keybindReadQuest = wrap(module, "keybindReadQuest")
  end
)

onLoad(
  function()
    module.initPlayButton(module.readQuest, module.openSettings)

    if (alertVersion > settings.alert.get()) then
      print(
        "Hello! I have a brand new settings panel, check it out from the interface menu or by right cliking the play/stop button :D"
      )
      settings.alert.set(alertVersion)
    end
  end
)

useEvent(
  function()
    isPlaying.set(false)
  end, { "VOICE_CHAT_TTS_PLAYBACK_FINISHED", "VOICE_CHAT_TTS_PLAYBACK_FAILED" }
)

useSlashCmd(
  function(cmd)
    if cmd == "play" then
      module.keybindReadQuest()
      print("Playing...")
    elseif cmd == "stop" then
      module.ttsStop()
      print("Stopping...")
    elseif cmd == "settings" then
      module.openSettings()
    end
  end, { "qtts" }
)

function module.ttsPlay(text)
  isPlaying.set(true)
  TextToSpeech_Speak(text, module.getVoice())
end

function module.ttsStop()
  isPlaying.set(false)
  C_VoiceChat.StopSpeakingText()
end

function module.readQuest(source)
  if isPlaying.get() then
    return module.ttsStop()
  end

  local title = ""
  local description = ""
  local objective = ""
  local info = ""
  local reward = ""
  local progress = ""

  if source == "questlog" then
    title = C_QuestLog.GetTitleForQuestID(QuestMapFrame_GetFocusedQuestID())
    description, objective = GetQuestLogQuestText()
  elseif source == "gossip" then
    info = C_GossipInfo.GetText()
  elseif source == "book" and ItemTextGetPage() == 1 then
    title = ItemTextGetItem()
    description = ItemTextGetText()
  elseif source == "book" then
    description = ItemTextGetText()
  elseif source == "quest" and QuestFrameRewardPanel:IsShown() then
    -- title = GetTitleText()
    reward = GetRewardText()
  elseif source == "quest" and QuestFrameProgressPanel:IsShown() then
    -- title = GetTitleText()
    progress = GetProgressText()
  elseif source == "quest" then
    title = GetTitleText()
    description = GetQuestText()
    objective = GetObjectiveText()
  elseif source == "immersion" and module.immersionIsGossip() then
    info = C_GossipInfo.GetText()
  elseif source == "immersion" and module.immersionIsQuestActive() then
    -- title = GetTitleText()
    progress = GetProgressText()
    reward = GetRewardText()
  elseif source == "immersion" and module.immersionIsQuestIncomplete() then
    -- title = GetTitleText()
    progress = GetProgressText()
    reward = GetRewardText()
  elseif source == "immersion" and module.immersionIsQuestAvailable() then
    title = GetTitleText()
    description = GetQuestText()
    objective = GetObjectiveText()
  end

  local text = ""

  if settings.readTitle.get() then
    text = text .. "\n" .. title
  end

  text = text .. "\n" .. description

  if settings.readObjective.get() then
    text = text .. "\n" .. objective
  end

  text = text .. "\n" .. info
  text = text .. "\n" .. reward
  text = text .. "\n" .. progress

  module.ttsPlay(module.cleanText(text))
end

function module.keybindReadQuest()
  local immersionFrame = module.immersionGetFrame()
  local isQuestFocused = QuestMapFrame_GetFocusedQuestID()

  if WorldMapFrame:IsVisible() and isQuestFocused then
    module.readQuest("questlog")
  elseif QuestFrame:IsVisible() then
    module.readQuest("quest")
  elseif GossipFrame:IsVisible() and immersionFrame == nil then
    module.readQuest("gossip")
  elseif immersionFrame and immersionFrame:IsVisible() then
    module.readQuest("immersion")
  else
    module.ttsStop()
  end
end

function module.getVoice()
  local toRet = settings.voice1.get()
  local unitSex = UnitSex("questnpc") or UnitSex("npc")

  if unitSex == 2 then -- male
    toRet = settings.voice1.get()
  elseif unitSex == 3 then -- female
    toRet = settings.voice2.get()
  else
    toRet = settings.voice3.get()
  end

  local voices = Array.new(C_VoiceChat.GetTtsVoices())
  local voiceToRet = voices:find(
    function(v)
      if v.voiceID == toRet then
        return true
      end
    end
  )

  return voiceToRet
end

function module.cleanText(text)
  local toRet = text

  toRet = toRet:gsub("<", ""):gsub(">", "")

  return toRet
end

function module.openSettings()
  InterfaceOptionsFrame_OpenToCategory(__namespace)
  InterfaceOptionsFrame_OpenToCategory(__namespace)
end

function module.registerCheckSetting(key, frame)
  local setting = settings[key]

  useEffect(
    function()
      frame:SetChecked(setting.get())
    end, { setting }
  )

  frame:SetScript(
    "OnClick", function()
      if frame:GetChecked() then
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
      else
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
      end

      setting.set(frame:GetChecked())
    end
  )
end

function module.registerVoiceSetting(key, frame)
  local setting = settings[key]
  local voices = Array.new(C_VoiceChat.GetTtsVoices())

  useEffect(
    function()
      local voice = voices:find(
        function(v)
          if v.voiceID == setting.get() then
            return true
          end
        end
      )

      UIDropDownMenu_SetText(frame, (voice or {}).name)
    end, { setting }
  )

  UIDropDownMenu_SetWidth(frame, 350)

  UIDropDownMenu_Initialize(
    frame, function(_, level)
      if (level or 1) ~= 1 then
        return
      end

      voices:map(
        function(voice, i)
          local info = UIDropDownMenu_CreateInfo()
          info.text = voice.name
          info.value = voice.voiceID
          info.menuList = i
          info.checked = setting.get() == info.value
          info.func = function()
            setting.set(info.value)
          end

          UIDropDownMenu_AddButton(info)
        end
      )
    end
  )
end

function module.immersionGetFrame()
  return ((ImmersionFrame or {}).TalkBox or {}).MainFrame
end

function module.immersionIsGossip()
  local icon = ImmersionFrame.TalkBox.MainFrame.Indicator:GetTextureFilePath()
  return icon:find("GossipGossipIcon")
end

function module.immersionIsQuestActive()
  local icon = ImmersionFrame.TalkBox.MainFrame.Indicator:GetTextureFilePath()
  return icon:find("ActiveQuestIcon")
end

function module.immersionIsQuestIncomplete()
  local icon = ImmersionFrame.TalkBox.MainFrame.Indicator:GetTextureFilePath()
  return icon:find("IncompleteQuestIcon")
end

function module.immersionIsQuestAvailable()
  local icon = ImmersionFrame.TalkBox.MainFrame.Indicator:GetTextureFilePath()
  return icon:find("AvailableQuestIcon")
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

  local buttons = Array.new(
    {
      factory(QuestMapFrame.DetailsFrame, 18, 30, "questlog"),
      factory(QuestFrame, -10, -30, "quest"),
      factory(GossipFrame, -10, -30, "gossip"),
      factory(ItemTextFrame, -23, 0, "book"),
    }
  )

  local immersionFrame = module.immersionGetFrame()

  if immersionFrame then
    buttons:push(factory(immersionFrame, -59, -17, "immersion"))
  end

  useEffect(
    function()
      if isPlaying.get() then
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
    end, { isPlaying }
  )
end
