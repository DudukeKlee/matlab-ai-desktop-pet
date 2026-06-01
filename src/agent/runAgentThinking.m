function runAgentThinking(appData, task)
% runAgentThinking - thinking 模式
%   runAgentThinking(appData, task)  — 初始化（由 call_agent 调用）
%   runAgentThinking(appData)        — 启动循环（由 onAILoopComplete 调用）

    if nargin == 2
        appData.agentB_status = 'working';
        appData.agentB_mode = 'thinking';
        appData.agentB_currentTask = task;
        appData.agentB_messages = buildAgentPrompt(appData.config, task, 'thinking');
        appData.agentB_round = 0;
        appData.agentB_success = false;
        appData.agentB_result = '';
        appData.agentB_remark = '';

        createAgentWindow(appData);
        appData.agentB_pendingStart = true;
    else
        scheduleNextTick(appData);
    end
end

function scheduleNextTick(appData)
    t = timer('ExecutionMode', 'singleShot', ...
        'StartDelay', 0.1, ...
        'TimerFcn', @(src,~) thinkingTickWrapper(appData, src));
    appData.agentB_loopTimer = t;
    start(t);
end

function thinkingTickWrapper(appData, timerObj)
    try, delete(timerObj); catch, end
    thinkingTick(appData);
end

function thinkingTick(appData)
    try
        if isempty(appData.agentB_fig) || ~isvalid(appData.agentB_fig)
            appData.agentB_status = 'idle';
            appData.agentB_mode = '';
            appData.agentB_currentTask = '';
            appData.agentB_messages = {};
            appData.agentB_round = 0;
            return;
        end

        maxR = appData.config.agentB.maxRounds;
        if appData.agentB_round >= maxR
            appData.agentB_result = sprintf('超过最大轮次 %d', maxR);
            appData.agentB_success = false;
            appData.agentB_remark = '';
            appendAgentChat(appData, '=== 超过最大轮次 ===');
            finishThinking(appData);
            return;
        end

        appData.agentB_round = appData.agentB_round + 1;
        updateAgentStatus(appData);

        agentConfig = buildAgentAIConfig(appData.config);
        [reply, appData.agentB_messages] = sendAIRequest(agentConfig, appData.agentB_messages);
        parsed = parseAIResponse(reply);

        if ~isempty(parsed.emotion)
            switchAgentImage(appData, parsed.emotion);
        end

        if ~isempty(parsed.text)
            appendAgentChat(appData, sprintf('[%d] %s', appData.agentB_round, parsed.text));
        end

        % 状态图
        if ~isempty(parsed.status) && ~isempty(appData.agentB_fig) && isvalid(appData.agentB_fig)
            angleDeg = 90;
            if ~isempty(parsed.angle), angleDeg = parsed.angle; end
            showAgentStatus(appData, parsed.status, angleDeg);
        end


        if parsed.done
            appData.agentB_success = true;
            appData.agentB_result = parsed.text;
            appData.agentB_remark = parsed.remark;

            if ~isempty(parsed.remark)
                appendAgentChat(appData, sprintf('%s: %s', appData.config.agentB.name, parsed.remark));
            end

            if ~isempty(parsed.toUser)
                savedPath = saveThinkingResult(appData, parsed.toUser);
                appData.agentB_result = sprintf('%s（详细结果已保存到 %s）', ...
                    parsed.text, savedPath);
            end

            appendAgentChat(appData, '=== 任务完成 ===');
            finishThinking(appData);
            return;
        end

        if ~isempty(parsed.skillCall)
            skillResult = handleAgentSkillCall(appData, parsed.skillCall);
            appendAgentChat(appData, sprintf('  → %s', truncate(skillResult, 200)));
            appData.agentB_messages{end+1} = struct('role', 'user', ...
                'content', sprintf('[Skill 结果] %s', skillResult));
        else
            appData.agentB_messages{end+1} = struct('role', 'user', ...
                'content', '请继续，或输出 [done:true] 并用 [toUser:...] 包裹产出结束。');
        end

        scheduleNextTick(appData);

    catch ME
        appData.agentB_result = sprintf('异常: %s', ME.message);
        appData.agentB_success = false;
        appData.agentB_remark = '';
        appendAgentChat(appData, sprintf('=== 异常: %s ===', ME.message));
        finishThinking(appData);
    end
end

function finishThinking(appData)
    appData.agentB_status = 'done_pending';
    delay = appData.config.agentB.autoCloseDelay;
    t = timer('ExecutionMode', 'singleShot', 'StartDelay', delay, ...
        'TimerFcn', @(src,~) closeAgentWin(appData, src));
    appData.agentB_closeTimer = t;
    start(t);
end

function closeAgentWin(appData, t)
    try
        if ~isempty(appData.agentB_fig) && isvalid(appData.agentB_fig)
            delete(appData.agentB_fig);
            appData.agentB_fig = [];
        end
    catch
    end
    try, delete(t); catch, end
end

function savedPath = saveThinkingResult(appData, content)
    dirName = appData.config.agentB.resultSaveDir;
    saveDir = fullfile(getProjectRoot(), dirName);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    fname = sprintf('result_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
    savedPath = fullfile(saveDir, fname);
    fid = fopen(savedPath, 'w', 'n', 'UTF-8');
    fwrite(fid, content, 'char');
    fclose(fid);
end

function out = truncate(s, n)
    if ~ischar(s) && ~isstring(s)
        s = char(string(s));
    end
    s = char(s);
    if numel(s) > n
        out = [s(1:n) '...'];
    else
        out = s;
    end
end
