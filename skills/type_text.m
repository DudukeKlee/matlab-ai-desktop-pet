function result = type_text(params)
% type_text - 在当前输入焦点处输入文字
%   params.text: 要输入的文字

    if ~isfield(params, 'text') || isempty(params.text)
        result = '请指定要输入的文字（params.text）。';
        return;
    end

    textToType = params.text;

    try
        % 使用剪贴板 + Ctrl+V 方式输入（支持中文）
        toolkit = java.awt.Toolkit.getDefaultToolkit();
        clipboard = toolkit.getSystemClipboard();

        % 保存原始剪贴板
        try
            oldContent = clipboard.getContents([]);
        catch
            oldContent = [];
        end

        % 将文字放入剪贴板
        stringSelection = java.awt.datatransfer.StringSelection(textToType);
        clipboard.setContents(stringSelection, []);
        pause(0.1);

        % 模拟 Ctrl+V 粘贴
        robot = java.awt.Robot();
        robot.keyPress(java.awt.event.KeyEvent.VK_CONTROL);
        pause(0.05);
        robot.keyPress(java.awt.event.KeyEvent.VK_V);
        pause(0.05);
        robot.keyRelease(java.awt.event.KeyEvent.VK_V);
        pause(0.05);
        robot.keyRelease(java.awt.event.KeyEvent.VK_CONTROL);
        pause(0.2);

        % 恢复原始剪贴板
        if ~isempty(oldContent)
            try
                clipboard.setContents(oldContent, []);
            catch
            end
        end

        result = sprintf('已输入文字: %s', textToType);
    catch ME
        result = sprintf('输入文字失败: %s', ME.message);
    end
end
