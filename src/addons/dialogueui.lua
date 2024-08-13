local __namespace, __module = ...

local Addon = __module.Addon --- @class Addon

local onLoad = Addon.onLoad
local useHook = Addon.useHook
local useEffect = Addon.useEffect

local module = {}

function module.init()
  local Main = __module.Main
  local isPlaying = Main.getState().isPlaying

  local source = "gossip"

  local frame = DUIQuestFrame
  if not frame then
    return
  end

  local BUTTON_SIZE = 24;
  local ICON_SIZE = 16;
  local ALPHA_UNFOCUSED = 0.6;

  if DialogueUI_DB and DialogueUI_DB.TTSEnabled then
    DialogueUI_DB.TTSEnabled = false
  end

  local b = CreateFrame("Button", nil, frame)

  b:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8);
  b:SetSize(BUTTON_SIZE, BUTTON_SIZE);
  b:SetAlpha(ALPHA_UNFOCUSED);
  b:RegisterForClicks("LeftButtonUp", "RightButtonDown")

  local file = "Interface/AddOns/DialogueUI/Art/Theme_Shared/TTSButton.png";

  b.Icon = b:CreateTexture(nil, "OVERLAY");
  b.Icon:SetSize(ICON_SIZE, ICON_SIZE);
  b.Icon:SetPoint("CENTER", b, "CENTER", 0, 0);
  b.Icon:SetTexture(file);

  b.Wave1 = b:CreateTexture(nil, "OVERLAY");
  b.Wave1:SetSize(0.25*ICON_SIZE, ICON_SIZE);
  b.Wave1:SetPoint("LEFT", b, "RIGHT", -8, 0);
  b.Wave1:SetTexture(file);

  b.Wave2 = b:CreateTexture(nil, "OVERLAY");
  b.Wave2:SetSize(0.375*ICON_SIZE, ICON_SIZE);
  b.Wave2:SetPoint("LEFT", b.Wave1, "RIGHT", -3, 0);
  b.Wave2:SetTexture(file);

  b.Wave3 = b:CreateTexture(nil, "OVERLAY");
  b.Wave3:SetSize(0.375*ICON_SIZE, ICON_SIZE);
  b.Wave3:SetPoint("LEFT", b.Wave2, "RIGHT", -4, 0);
  b.Wave3:SetTexture(file);

  local function setTheme()
    local themeID = DialogueUI_DB and DialogueUI_DB.Theme or 1
    local x;
    if themeID == 1 then
        x = 0;
    else
        x = 0.5;
    end
    b.Icon:SetTexCoord(0 + x, 0.5 + x, 0, 0.5);
    b.Wave1:SetTexCoord(0 + x, 0.125 + x, 0.5, 1);
    b.Wave2:SetTexCoord(0.125 + x, 0.3125 + x, 0.5, 1);
    b.Wave3:SetTexCoord(0.3125 + x, 0.5 + x, 0.5, 1);
  end

  b.Wave1:Hide();
  b.Wave2:Hide();
  b.Wave3:Hide();

  b.AnimWave = b:CreateAnimationGroup(nil, "DUISpeakerAnimationTemplate");

  b.AnimWave:SetScript("OnPlay", function()
    b.Wave1:Show();
    b.Wave2:Show();
    b.Wave3:Show();
  end);

  b.AnimWave:SetScript("OnStop", function()
      b.Wave1:Hide();
      b.Wave2:Hide();
      b.Wave3:Hide();
  end);

  b:SetScript(
    "OnEnter", function(self)
      self:SetAlpha(1)
    end
  )

  b:SetScript(
    "OnLeave", function(self)
      self:SetAlpha(ALPHA_UNFOCUSED)
    end
  )

  b:SetScript(
    "OnClick", function(_, event)
      if event == "RightButton" then
        Main.openSettings()
      else
        -- print(source)
        Main.ttsToggle(source)
      end
    end
  )

  DUIQuestFrame.QuestTTSButton = b

  useEffect(
    function()
      if isPlaying.get() then
        b.AnimWave:Play()
      else
        b.AnimWave:Stop()
      end
    end, { isPlaying }
  )

  useHook(
    "OnShow", function()
      setTheme()
    end, "secure-widget", DUIQuestFrame
  )

  useHook(
    "OnHide", function()
      Main.ttsAutoStop()
    end, "secure-widget", DUIQuestFrame
  )

  useHook(
    "HandleGossip", function()
      source = "gossip"
      --print(source)
      Main.ttsAutoPlay(source)
    end, "secure-function", DUIQuestFrame
  )

  useHook(
    "HandleQuestDetail", function()
      source = "quest:detail"
      --print(source)
      Main.ttsAutoPlay(source)
    end, "secure-function", DUIQuestFrame
  )

  useHook(
    "HandleQuestComplete", function()
      source = "quest:reward"
      --print(source)
      Main.ttsAutoPlay(source)
    end, "secure-function", DUIQuestFrame
  )

  useHook(
    "HandleQuestGreeting", function()
      source = "quest:greeting"
      --print(source)
      Main.ttsAutoPlay(source)
    end, "secure-function", DUIQuestFrame
  )

  useHook(
    "HandleQuestProgress", function()
      source = "quest:progress"
      --print(source)
      Main.ttsAutoPlay(source)
    end, "secure-function", DUIQuestFrame
  )
end

onLoad(
  function()
    module.init()
  end
)

__module.DialogueUI = module
