function result = skill_template(params)
% skill_template - 技能模板，演示如何写一个标准技能
%
% ============================================================
% 这个文件不会被 AI 调用（没在 config/settings.json 注册）。
% 复制本文件 → 重命名 → 在 settings.json 里 skills 数组加一项 → 启动即可生效。
% ============================================================
%
% ## 函数签名
%   function result = <技能名>(params)         ← 普通技能
%   function result = <技能名>(params, appData) ← 需要访问 AppData 时（罕见）
%   后者需要在 src/skill/executeSkill.m 里加入特殊分支调用，
%   参考 call_agent 的处理方式。
%
% ## 参数
%   params: struct，来自 AI 调用时传入的 JSON 对象
%     例如 AI 输出 [skill:{"name":"use_skill","params":{"skill":"my_skill","params":{"foo":"bar"}}}]
%     则本函数收到的 params 是 struct('foo','bar')
%   注意：params 字段不存在不会自动报错，必须自己 isfield 检查。
%
% ## 返回值
%   result: 通常是一个字符串，会作为 [Skill 结果] 显示给 AI 和用户。
%   保持简短清晰，AI 看到这段文字就当作"操作的反馈"，会基于它做下一步。
%
%   特殊情况：返回 struct 且包含 type='screenshot' 字段时，
%   主循环会把 filePath 指向的图片转成 base64 发给视觉模型。
%   普通技能不需要这样做。
%
% ## 写法约定
%   1. 第一段统一做参数校验，缺什么直接告诉调用者；
%   2. 主逻辑用 try/catch 包住，捕获异常并把错误信息写进 result；
%   3. result 全用中文（AI 是中文人设），保持口吻自然；
%   4. 不要 disp/fprintf 长篇内容到 MATLAB 命令窗——会污染日志。

    % ---------- 1. 参数校验 ----------
    if ~isfield(params, 'message')
        result = '请指定 params.message（要回声的内容）。';
        return;
    end

    msg = params.message;

    % ---------- 2. 主逻辑（用 try/catch 包住） ----------
    try
        % 这里换成你的真实逻辑：调系统命令、操作文件、调 Web API …
        % 此处仅演示：把传入的 message 原样返回
        result = sprintf('技能已执行，收到的消息是: %s', msg);

    catch ME
        % 任何异常都转成可读字符串，AI 会看到并据此判断要不要重试 / 换方法
        result = sprintf('技能执行失败: %s', ME.message);
    end
end

% ============================================================
% ## 如何在 settings.json 里注册新技能
% ============================================================
%
% 打开 config/settings.json，在 "skills" 数组里添加一项：
%
% {
%   "name": "my_skill",
%   "description": "一句话说明这个技能做什么。说清楚 params 需要哪些字段、什么类型、什么含义。AI 完全靠这段描述决定调不调用、怎么调用。写得越清楚越不容易出错。",
%   "fileName": "my_skill.m"
% }
%
% 注意：
%   - name 是 AI 调用时引用的名字，建议小写+下划线，纯英文
%   - fileName 必须和实际 .m 文件名一致，放在 skills/ 目录
%   - description 是给 AI 看的，要写明前置条件（比如"调用前必须先 screenshot"）
%   - 不需要重启 MATLAB，下次启动 main.m 自动加载
%
% ============================================================
