function result = click_screen(params)
% click_screen - 在屏幕指定百分比坐标处模拟鼠标点击
%   params.x: 屏幕X百分比 (0~100)
%   params.y: 屏幕Y百分比 (0~100)
%   params.double: 可选，true表示双击，默认单击

    if ~isfield(params, 'x') || ~isfield(params, 'y')
        result = '请指定百分比坐标 params.x (0~100) 和 params.y (0~100)。';
        return;
    end

    pctX = params.x;
    pctY = params.y;

    toolkit = java.awt.Toolkit.getDefaultToolkit();
    screenSize = toolkit.getScreenSize();

    % 百分比 → 实际像素
    realX = round(pctX / 100 * screenSize.width);
    realY = round(pctY / 100 * screenSize.height);

    % 边界钳制
    realX = max(0, min(realX, screenSize.width - 1));
    realY = max(0, min(realY, screenSize.height - 1));

    try
        robot = java.awt.Robot();
        robot.mouseMove(realX, realY);
        pause(0.1);

        if isfield(params, 'double') && params.double
            % 双击
            robot.mousePress(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
            robot.mouseRelease(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
            pause(0.05);
            robot.mousePress(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
            robot.mouseRelease(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
        else
            % 单击
            robot.mousePress(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
            pause(0.05);
            robot.mouseRelease(java.awt.event.InputEvent.BUTTON1_DOWN_MASK);
        end

        result = sprintf('已点击百分比坐标(%.1f%%, %.1f%%)，实际像素(%d, %d)。', ...
            pctX, pctY, realX, realY);
    catch ME
        result = sprintf('点击失败: %s', ME.message);
    end
end
