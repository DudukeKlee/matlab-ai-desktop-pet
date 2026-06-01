function config = loadConfig()
    configDir = fullfile(getProjectRoot(), 'config');
    filePath = fullfile(configDir, 'settings.json');

    if exist(filePath, 'file')
        fid = fopen(filePath, 'r', 'n', 'UTF-8');
        raw = fread(fid, '*char')';
        fclose(fid);
        config = jsondecode(raw);
        config = ensureDefaults(config);
    else
        config = getDefaultConfig();
    end
end

function config = getDefaultConfig()
    config = struct();
    config.ai.baseURL = 'https://api.openai.com/v1';
    config.ai.model = 'gpt-4';
    config.ai.apiKey = '';
    config.ai.systemPrompt = '你是一个桌面宠物助手。';
    config.tts.url = 'http://localhost:5000';
    config.tts.language = 'en';
    config.skills = struct('name', {}, 'description', {}, 'fileName', {});
    config.images = struct('name', {}, 'type', {}, 'fileName', {}, 'description', {});
    config.defaultCharacterImage = '';
    config.stateDuration = 5;
    config.characterSize = 200;
    config.characterOffsetX = 0;
    config.characterOffsetY = 0;
    config.chatHeight = 115;
    config.chatFontSize = 14;

    % 翻译
    config.translator.enabled = false;
    config.translator.baseURL = '';
    config.translator.model = '';
    config.translator.apiKey = '';
    config.translator.targetLanguage = '中文';
    % 显示
    config.display.showOriginal = true;
    config.display.showTranslation = true;
    config.display.originalPrefix = '宠物';
    config.display.translationPrefix = '翻译';
    % Agent B
    config.agentB.enabled = false;
    config.agentB.baseURL = '';
    config.agentB.model = '';
    config.agentB.apiKey = '';
    config.agentB.name = 'Vedal';
    config.agentB.userPrompt = '你叫 Vedal，是牛肉（neuro）的创造者兼技术支持。当牛肉遇到自己搞不定的任务时，会向你求助。你冷静、精准、话少，是个程序员式的存在。';
    config.agentB.maxRounds = 30;
    config.agentB.defaultAgentImage = '';
    config.agentB.resultSaveDir = 'results';
    config.agentB.autoCloseDelay = 3;
    % Agent C（状态图选择）
    config.agentC.enabled = false;
    config.agentC.baseURL = '';
    config.agentC.model = '';
    config.agentC.apiKey = '';
end


function config = ensureDefaults(config)
    defaults = getDefaultConfig();
    config = mergeStruct(config, defaults);
end

function out = mergeStruct(src, def)
    % 递归合并：src 缺的字段用 def 补
    if ~isstruct(src)
        out = def;
        return;
    end
    out = src;
    if ~isstruct(def)
        return;
    end
    fns = fieldnames(def);
    for i = 1:numel(fns)
        fn = fns{i};
        if ~isfield(out, fn)
            out.(fn) = def.(fn);
            continue;
        end
        srcVal = out.(fn);
        defVal = def.(fn);
        % 只递归合并"标量结构体"（scalar struct），数组 struct 保留原值
        if isstruct(defVal) && isstruct(srcVal) && ...
           isscalar(defVal) && isscalar(srcVal)
            out.(fn) = mergeStruct(srcVal, defVal);
        end
    end
end
