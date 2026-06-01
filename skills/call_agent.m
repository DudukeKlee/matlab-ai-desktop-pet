function result = call_agent(params, appData)
% call_agent - A 召唤 B 的入口
%   params.task: 任务描述
%   params.mode: 'skill' / 'thinking'
%   appData: handle 对象

    if ~isfield(params, 'task') || isempty(params.task)
        result = '请指定 params.task（任务描述）。';
        return;
    end
    if ~isfield(params, 'mode') || ~ismember(params.mode, {'skill', 'thinking'})
        result = '请指定 params.mode 为 "skill" 或 "thinking"。';
        return;
    end

    if isempty(appData)
        result = '[Skill 错误] call_agent 无法获取 appData。';
        return;
    end

    if ~appData.config.agentB.enabled
        result = '[系统] Agent B 未启用，请在设置中配置。';
        return;
    end

    % 忙碌检查
    if strcmp(appData.agentB_status, 'working')
        result = sprintf('[B 忙碌中] 上次派发的任务 "%s" 还在进行中，请等待或自行处理。', ...
            appData.agentB_currentTask);
        return;
    end
    if strcmp(appData.agentB_status, 'done_pending')
        result = '[B 有待汇报的结果] 请等我先汇报上次的任务结果。';
        return;
    end

    task = params.task;
    mode = params.mode;

    if strcmp(mode, 'skill')
        % 阻塞同步
        result = runAgentSkill(appData, task);
    else
        % 异步
        runAgentThinking(appData, task);
        result = sprintf('[已派发] 思考任务 "%s" 已交给 %s，完成后会通知你。', ...
            task, appData.config.agentB.name);
    end
end
