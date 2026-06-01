function result = screenshot(params)
% screenshot - 截取屏幕截图并叠加边缘百分比刻度尺
%   返回: 结构体，包含 success, filePath, message, type
%   刻度说明: 1%小刻度(白色短线), 5%中刻度(黄色中线+数字), 10%大刻度(黄色粗线+数字)
%   配合 click_screen 使用百分比坐标 (0~100)

    tempDir = fullfile(getProjectRoot(), 'temp');
    if ~exist(tempDir, 'dir')
        mkdir(tempDir);
    end

    timestamp = datestr(now, 'yyyymmdd_HHMMss');
    imgFile = fullfile(tempDir, sprintf('screenshot_%s.png', timestamp));

    try
        robot = java.awt.Robot();
        toolkit = java.awt.Toolkit.getDefaultToolkit();
        screenSize = toolkit.getScreenSize();
        rect = java.awt.Rectangle(0, 0, screenSize.width, screenSize.height);

        bufferedImage = robot.createScreenCapture(rect);

        g2d = bufferedImage.createGraphics();
        scrW = screenSize.width;
        scrH = screenSize.height;

        % ========== 抗锯齿 ==========
        g2d.setRenderingHint( ...
            java.awt.RenderingHints.KEY_ANTIALIASING, ...
            java.awt.RenderingHints.VALUE_ANTIALIAS_ON);
        g2d.setRenderingHint( ...
            java.awt.RenderingHints.KEY_TEXT_ANTIALIASING, ...
            java.awt.RenderingHints.VALUE_TEXT_ANTIALIAS_ON);

        % ========== 边缘刻度尺配置 ==========
        rulerThick = 30;    % 刻度尺条带宽度（像素）
        tickSmall  = 8;     % 1% 小刻度长度
        tickMid    = 14;    % 5% 中刻度长度
        tickBig    = 24;    % 10% 大刻度长度

        % ---------- 顶部刻度尺背景 ----------
        g2d.setColor(java.awt.Color(0.0, 0.0, 0.0, 160/255));
        g2d.fillRect(0, 0, scrW, rulerThick);

        % ---------- 左侧刻度尺背景 ----------
        g2d.setColor(java.awt.Color(0.0, 0.0, 0.0, 160/255));
        g2d.fillRect(0, rulerThick, rulerThick, scrH - rulerThick);

        % ---------- 左上角交汇区域加深 ----------
        g2d.setColor(java.awt.Color(0.0, 0.0, 0.0, 200/255));
        g2d.fillRect(0, 0, rulerThick, rulerThick);

        % ---------- 字体 ----------
        fontBig  = java.awt.Font('Arial', java.awt.Font.BOLD, 12);
        fontMid  = java.awt.Font('Arial', java.awt.Font.PLAIN, 10);

        % =============================================
        %  顶部 X 轴刻度 (从左到右, 0% ~ 100%)
        % =============================================
        for pct = 0:1:100
            px = round(pct / 100 * scrW);

            if mod(pct, 10) == 0
                % --- 10% 大刻度：粗黄线 + 大数字 ---
                g2d.setColor(java.awt.Color(1.0, 1.0, 0.0, 1.0));
                g2d.setStroke(java.awt.BasicStroke(2));
                g2d.drawLine(px, 0, px, tickBig);
                g2d.setFont(fontBig);
                label = java.lang.String(sprintf('%d', pct));
                g2d.drawString(label, px + 3, rulerThick - 4);

            elseif mod(pct, 5) == 0
                % --- 5% 中刻度：黄线 + 小数字 ---
                g2d.setColor(java.awt.Color(1.0, 1.0, 0.0, 220/255));
                g2d.setStroke(java.awt.BasicStroke(1));
                g2d.drawLine(px, 0, px, tickMid);
                g2d.setFont(fontMid);
                label = java.lang.String(sprintf('%d', pct));
                g2d.drawString(label, px + 2, tickMid + 10);

            else
                % --- 1% 小刻度：白色短线 ---
                g2d.setColor(java.awt.Color(1.0, 1.0, 1.0, 150/255));
                g2d.setStroke(java.awt.BasicStroke(1));
                g2d.drawLine(px, 0, px, tickSmall);
            end
        end

        % =============================================
        %  左侧 Y 轴刻度 (从上到下, 0% ~ 100%)
        % =============================================
        for pct = 0:1:100
            py = round(pct / 100 * scrH);

            if mod(pct, 10) == 0
                % --- 10% 大刻度：粗黄线 + 大数字 ---
                g2d.setColor(java.awt.Color(1.0, 1.0, 0.0, 1.0));
                g2d.setStroke(java.awt.BasicStroke(2));
                g2d.drawLine(0, py, tickBig, py);
                g2d.setFont(fontBig);
                label = java.lang.String(sprintf('%d', pct));
                g2d.drawString(label, 2, py + 14);

            elseif mod(pct, 5) == 0
                % --- 5% 中刻度：黄线 + 小数字 ---
                g2d.setColor(java.awt.Color(1.0, 1.0, 0.0, 220/255));
                g2d.setStroke(java.awt.BasicStroke(1));
                g2d.drawLine(0, py, tickMid, py);
                g2d.setFont(fontMid);
                label = java.lang.String(sprintf('%d', pct));
                g2d.drawString(label, tickMid + 2, py + 5);

            else
                % --- 1% 小刻度：白色短线 ---
                g2d.setColor(java.awt.Color(1.0, 1.0, 1.0, 150/255));
                g2d.setStroke(java.awt.BasicStroke(1));
                g2d.drawLine(0, py, tickSmall, py);
            end
        end

        % =============================================
        %  每10%画淡色参考线穿过屏幕（辅助定位）
        %  用极细实线代替虚线，避免 javaArray float 兼容问题
        % =============================================
        g2d.setStroke(java.awt.BasicStroke(1));

        % 10% 参考线（稍明显）
        g2d.setColor(java.awt.Color(1.0, 0.0, 0.0, 40/255));
        for pct = 10:10:90
            px = round(pct / 100 * scrW);
            g2d.drawLine(px, rulerThick, px, scrH);
        end
        for pct = 10:10:90
            py = round(pct / 100 * scrH);
            g2d.drawLine(rulerThick, py, scrW, py);
        end

        % 5% 参考线（更淡）
        g2d.setColor(java.awt.Color(1.0, 0.0, 0.0, 20/255));
        for pct = 5:10:95
            px = round(pct / 100 * scrW);
            g2d.drawLine(px, rulerThick, px, scrH);
        end
        for pct = 5:10:95
            py = round(pct / 100 * scrH);
            g2d.drawLine(rulerThick, py, scrW, py);
        end

        g2d.dispose();

        % ========== 缩放图片 ==========
        origWidth  = bufferedImage.getWidth();
        origHeight = bufferedImage.getHeight();
        maxWidth   = 1920;

        if origWidth > maxWidth
            scale     = maxWidth / origWidth;
            newWidth  = maxWidth;
            newHeight = round(origHeight * scale);

            scaledImage = java.awt.image.BufferedImage(newWidth, newHeight, ...
                java.awt.image.BufferedImage.TYPE_INT_RGB);
            sg = scaledImage.createGraphics();
            sg.setRenderingHint(java.awt.RenderingHints.KEY_INTERPOLATION, ...
                java.awt.RenderingHints.VALUE_INTERPOLATION_BILINEAR);
            sg.drawImage(bufferedImage, 0, 0, newWidth, newHeight, []);
            sg.dispose();

            bufferedImage = scaledImage;
        end

        outputFile = java.io.File(imgFile);
        javax.imageio.ImageIO.write(bufferedImage, 'png', outputFile);

        if exist(imgFile, 'file')
            result = struct();
            result.success  = true;
            result.filePath = imgFile;
            result.message  = sprintf( ...
                '截图已保存（含百分比刻度尺）: %s\n坐标说明: X轴(0=最左, 100=最右) Y轴(0=最顶, 100=最底)\n分度值: 1%%小刻度(白), 5%%中刻度(黄+数字), 10%%大刻度(黄粗+数字)', ...
                imgFile);
            result.type = 'screenshot';
        else
            result = struct();
            result.success  = false;
            result.filePath = '';
            result.message  = '截图保存失败，文件未生成。';
            result.type     = 'screenshot';
        end
    catch ME
        result = struct();
        result.success  = false;
        result.filePath = '';
        result.message  = sprintf('截图失败: %s', ME.message);
        result.type     = 'screenshot';
    end
end
