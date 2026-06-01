function result = runAgentSkill(appData, task)
% runAgentSkill - skill 模式：阻塞执行直到完成

    appData.agentB_status = 'working';
    appData.agentB_mode = 'skill';
    appData.agentB_currentTask = task;
    appData.agentB_messages = buildAgentPrompt(appData.config, task, 'skill');
    appData.agentB_round = 0;
    appData.agentB_success = false;
    appData.agentB_result = '';
    appData.agentB_remark = '';

    % 开窗口
    createAgentWindow(appData);

    maxR = appData.config.agentB.maxRounds;
    agentConfig = buildAgentAIConfig(appData.config);

    try
        while appData.agentB_round < maxR
            % 用户可能手动关了 B 窗口
            if isempty(appData.agentB_fig) || ~isvalid(appData.agentB_fig)
                result = '[任务中断] Agent 窗口被关闭。';
                cleanupAgent(appData);
                return;
            end

            appData.agentB_round = appData.agentB_round + 1;
            updateAgentStatus(appData);

            [reply, appData.agentB_messages] = sendAIRequest(agentConfig, appData.agentB_messages, appData);
            parsed = parseAIResponse(reply);

            % 立绘切换
            if ~isempty(parsed.emotion)
                switchAgentImage(appData, parsed.emotion);
            end

            % 显示到 B 窗口
            if ~isempty(parsed.text)
                appendAgentChat(appData, sprintf('[%d] %s', appData.agentB_round, parsed.text));
            end

            % 状态图
            if ~isempty(parsed.status) && ~isempty(appData.agentB_fig) && isvalid(appData.agentB_fig)
                angleDeg = 90;
                if ~isempty(parsed.angle), angleDeg = parsed.angle; end
                showAgentStatus(appData, parsed.status, angleDeg);
            end


            % 检查完成
            if parsed.done
                appData.agentB_success = true;
                appData.agentB_result = parsed.text;
                appData.agentB_remark = parsed.remark;
                result = sprintf('[Agent 完成] %s', parsed.text);
                if ~isempty(parsed.remark)
                    appendAgentChat(appData, sprintf('%s: %s', appData.config.agentB.name, parsed.remark));
                end
                appendAgentChat(appData, '=== 任务完成 ===');
                pause(appData.config.agentB.autoCloseDelay);
                cleanupAgent(appData);
                return;
            end

            % 执行 skill
            if ~isempty(parsed.skillCall)
                skillResult = handleAgentSkillCall(appData, parsed.skillCall);
                appendAgentChat(appData, sprintf('  → %s', truncate(skillResult, 200)));
                appData.agentB_messages{end+1} = struct('role', 'user', ...
                    'content', sprintf('[Skill 结果] %s', skillResult));
            else
                % 没有 skill 也没有 done，提示继续
                appData.agentB_messages{end+1} = struct('role', 'user', ...
                    'content', '请继续执行任务，或输出 [done:true] 结束。');
            end

            drawnow;
        end

        % 超轮次
        result = sprintf('[Agent 失败] 超过最大轮次 %d。', maxR);
        appData.agentB_success = false;
        appData.agentB_result = result;
        appData.agentB_remark = '';
        appendAgentChat(appData, '=== 超过最大轮次 ===');
        pause(appData.config.agentB.autoCloseDelay);
        cleanupAgent(appData);

    catch ME
        result = sprintf('[Agent 异常] %s', ME.message);
        appData.agentB_success = false;
        appData.agentB_result = result;
        appData.agentB_remark = '';
        cleanupAgent(appData);
    end
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
