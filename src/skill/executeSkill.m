function resultMsg = executeSkill(config, skillCall, appData, callerID)
% executeSkill - 执行 skill
%   config, skillCall: 原有
%   appData: handle 对象，可选（B 状态检查用）
%   callerID: 'A' / 'B'，默认 'A'

    if nargin < 3, appData = []; end
    if nargin < 4, callerID = 'A'; end

    skillName = skillCall.name;

    % skill-B 锁：B 在 skill 模式工作时，A 不能调 skill
    if ~isempty(appData) && strcmp(callerID, 'A') && ...
       strcmp(appData.agentB_status, 'working') && ...
       strcmp(appData.agentB_mode, 'skill')
        resultMsg = '[系统] Agent 正在操作电脑，请稍候...';
        return;
    end

    if isfield(skillCall, 'params')
        params = skillCall.params;
    else
        params = struct();
    end

    % B 不能调 call_agent
    if strcmp(callerID, 'B') && strcmp(skillName, 'call_agent')
        resultMsg = '[Skill 错误] Agent B 不能召唤自己。';
        return;
    end

    % 查找 skill 文件
    fileName = '';
    if ~isempty(config.skills) && numel(config.skills) > 0
        for i = 1:numel(config.skills)
            if strcmp(config.skills(i).name, skillName)
                fileName = config.skills(i).fileName;
                break;
            end
        end
    end

    if isempty(fileName)
        resultMsg = sprintf('[Skill 错误] 未找到名为 "%s" 的 skill。', skillName);
        return;
    end

    projectRoot = getProjectRoot();
    skillDir = fullfile(projectRoot, 'skills');
    if exist(skillDir, 'dir') && ~contains(path, skillDir)
        addpath(skillDir);
    end

    [~, funcName, ~] = fileparts(fileName);

    try
    funcHandle = str2func(funcName);
    % call_agent 需要 appData，特殊处理
    if strcmp(skillName, 'call_agent')
        resultMsg = funcHandle(params, appData);
    else
        resultMsg = funcHandle(params);
    end

        if isstruct(resultMsg)
            return;
        end

        if ~ischar(resultMsg) && ~isstring(resultMsg)
            resultMsg = '[Skill 完成] 执行成功，无文本返回。';
        end
    catch ME
        resultMsg = sprintf('[Skill 错误] 执行 "%s" 失败: %s', skillName, ME.message);
    end
end
