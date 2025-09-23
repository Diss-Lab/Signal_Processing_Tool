classdef visualizer < handle
    % 可视化模块 - 负责各种图形绘制和时频分析
    
    methods (Static)
        function [freq_vector, magnitude] = compute_fft(signal, fs)
            % 计算FFT
            % 输入: signal - 信号, fs - 采样频率
            % 输出: freq_vector - 频率向量(kHz), magnitude - 幅值
            
            N = length(signal);
            Y = fft(signal);
            freq_vector = (0:N-1) * fs / N / 1000; % 转换为 kHz
            magnitude = abs(Y);
            
            % 只返回前半部分（正频率）
            freq_vector = freq_vector(1:floor(N/2));
            magnitude = magnitude(1:floor(N/2));
        end
        
        function peak_info = find_frequency_peaks(freq_vector, magnitude)
            % 查找频率峰值
            % 输入: freq_vector - 频率向量, magnitude - 幅值
            % 输出: peak_info - 峰值信息字符串
            
            peak_info = '';
            
            try
                % 找到峰值
                min_peak_distance = max(10, round(length(magnitude) / 100));
                [peaks, locs] = findpeaks(magnitude, 'MinPeakHeight', max(magnitude)*0.1, ...
                                         'MinPeakDistance', min_peak_distance, 'SortStr', 'descend');
                
                if length(peaks) >= 1
                    peak_info = sprintf('Highest Peak: %.1f kHz', freq_vector(locs(1)));
                end
                if length(peaks) >= 2
                    peak_info = [peak_info, sprintf('\nSecond Peak: %.1f kHz', freq_vector(locs(2)))];
                end
            catch
                % 如果findpeaks函数不可用，跳过峰值检测
            end
        end
        
        function create_timefreq_window(signal, time_data, fs)
            % 创建时频分析窗口
            % 输入: signal - 信号, time_data - 时间数据, fs - 采样频率
            
            % 创建时频分析窗口
            tf_fig = figure('Name', 'Time-Frequency Analysis', 'Position', [300, 100, 900, 650], ...
                           'MenuBar', 'figure', 'ToolBar', 'figure');
            
            % 添加自定义工具栏
            visualizer.add_timefreq_toolbar(tf_fig);
            
            % 计算短时傅里叶变换
            window_length = round(length(signal) / 20);
            overlap = round(window_length * 0.75);
            nfft = max(256, 2^nextpow2(window_length));
            
            % 使用汉宁窗
            window = hann(window_length);
            
            try
                [S, F, T] = spectrogram(signal, window, overlap, nfft, fs);
                
                % 转换单位
                F_kHz = F / 1000;
                T_us = (T + time_data(1)) * 1e6;
                
                % 计算幅值矩阵并进行平滑处理
                S_magnitude = abs(S);
                S_dB = 20*log10(S_magnitude + eps); % 加eps避免log(0)
                
                % 对时频图进行平滑处理
                S_dB_smooth = visualizer.smooth_spectrogram(S_dB);
                
                % 创建主轴和信息显示区域
                main_axes = axes('Parent', tf_fig, 'Position', [0.1, 0.15, 0.75, 0.75]);
                
                % 使用pcolor进行伪颜色映射显示
                h_timefreq = pcolor(main_axes, T_us, F_kHz, S_dB_smooth);
                shading(main_axes, 'interp');
                axis(main_axes, 'tight');
                colormap(main_axes, jet);
                
                % 设置颜色条
                h_colorbar = colorbar(main_axes);
                ylabel(h_colorbar, 'Magnitude (dB)', 'FontSize', 12);
                
                xlabel(main_axes, 'Time (μs)', 'FontSize', 12);
                ylabel(main_axes, 'Frequency (kHz)', 'FontSize', 12);
                title(main_axes, 'Time-Frequency Spectrogram', 'FontSize', 14);
                
                % 找到峰值信息
                [peak_info_str, tf_click_text] = visualizer.create_timefreq_info_panel(tf_fig, S_magnitude, F_kHz, T_us);
                
                % 设置点击功能
                set(h_timefreq, 'ButtonDownFcn', @(~,~) visualizer.timefreq_click(main_axes, F_kHz, T_us, S_dB_smooth, tf_click_text));
                set(main_axes, 'ButtonDownFcn', @(~,~) visualizer.timefreq_click(main_axes, F_kHz, T_us, S_dB_smooth, tf_click_text));
                
            catch ME
                msgbox(['Time-frequency analysis error: ' ME.message], 'Error', 'error');
            end
        end
        
        function S_dB_smooth = smooth_spectrogram(S_dB)
            % 平滑时频图
            if size(S_dB, 1) > 3 && size(S_dB, 2) > 3
                % 使用2D高斯滤波器进行平滑
                sigma = 1.0; % 平滑参数
                try
                    S_dB_smooth = imgaussfilt(S_dB, sigma);
                catch
                    % 如果没有imgaussfilt函数，使用原始数据
                    S_dB_smooth = S_dB;
                end
            else
                S_dB_smooth = S_dB;
            end
        end
        
        function [peak_info_str, tf_click_text] = create_timefreq_info_panel(tf_fig, S_magnitude, F_kHz, T_us)
            % 创建时频分析信息面板
            
            % 找到最大和第二大幅值位置
            [max_val, max_idx] = max(S_magnitude(:));
            [max_row, max_col] = ind2sub(size(S_magnitude), max_idx);
            max_freq = F_kHz(max_row);
            max_time = T_us(max_col);
            
            S_temp = S_magnitude;
            exclude_freq_range = max(1, round(length(F_kHz) * 0.05));
            exclude_time_range = max(1, round(length(T_us) * 0.05));
            
            row_start = max(1, max_row - exclude_freq_range);
            row_end = min(size(S_temp, 1), max_row + exclude_freq_range);
            col_start = max(1, max_col - exclude_time_range);
            col_end = min(size(S_temp, 2), max_col + exclude_time_range);
            
            S_temp(row_start:row_end, col_start:col_end) = 0;
            
            [second_max_val, second_max_idx] = max(S_temp(:));
            [second_max_row, second_max_col] = ind2sub(size(S_temp), second_max_idx);
            second_max_freq = F_kHz(second_max_row);
            second_max_time = T_us(second_max_col);
            
            % 创建信息显示区域
            % 调整信息面板位置（Units 使用 normalized；[left bottom width height]）
            % 需要改变显示位置时，仅修改 info_panel_pos 数组即可
            info_panel_pos = [0.85, 0.12, 0.14, 0.78];  % ← 按需调整
            info_panel = uipanel('Parent', tf_fig, ...
                                 'Units', 'normalized', ...
                                 'Position', info_panel_pos, ...
                                 'Title', 'Information');

            % 峰值信息显示文本（内容）
            peak_info_str = sprintf('Peak Values:\n\nMax:(%.1f μs, %.1f kHz)\n\n2nd Max:(%.1f μs, %.1f kHz)', ...
                                    max_time, max_freq, second_max_val, second_max_freq);

            peak_info_text = uicontrol('Parent', info_panel, 'Style', 'text', ...
                                      'String', peak_info_str, ...
                                      'Position', [5, 200, 100, 120], ...
                                      'HorizontalAlignment', 'left', ...
                                      'FontSize', 9);
            set(peak_info_text, 'Units', 'pixels');

            % 点击信息显示
            tf_click_text = uicontrol('Parent', info_panel, 'Style', 'text', ...
                                     'String', 'Click on spectrogram to see coordinates', ...
                                     'Position', [5, 50, 120, 110], ...
                                     'HorizontalAlignment', 'left', ...
                                     'FontSize', 9, ...
                                     'BackgroundColor', [0.9 0.9 0.9]);
        end
        
        function timefreq_click(main_axes, F_kHz, T_us, S_dB_smooth, tf_click_text)
            % 时频图点击回调函数
            if ishandle(main_axes)
                point = get(main_axes, 'CurrentPoint');
                time_coord = point(1, 1); % 时间 (μs)
                freq_coord = point(1, 2); % 频率 (kHz)
                
                % 找到最接近的数据点的幅值
                [~, time_idx] = min(abs(T_us - time_coord));
                [~, freq_idx] = min(abs(F_kHz - freq_coord));
                
                if time_idx <= size(S_dB_smooth, 2) && freq_idx <= size(S_dB_smooth, 1)
                    magnitude_val = S_dB_smooth(freq_idx, time_idx);
                    
                    click_info = sprintf('Time-Frequency Click:\n\nTime: %.1f μs\nFrequency: %.1f kHz\nMagnitude: %.1f dB', ...
                                        time_coord, freq_coord, magnitude_val);
                    if ishandle(tf_click_text)
                        set(tf_click_text, 'String', click_info);
                    end
                end
            end
        end
        
        function add_timefreq_toolbar(tf_fig)
            % 为时频分析窗口添加图形编辑工具栏
            try
                % 创建自定义工具栏
                htoolbar = uitoolbar('Parent', tf_fig);
                
                % 图标路径（MATLAB内置图标）
                iconpath = fullfile(matlabroot, 'toolbox', 'matlab', 'icons');
                
                % 添加缩放工具
                uipushtool(htoolbar, 'CData', imread(fullfile(iconpath, 'tool_zoom_in.png')), ...
                          'TooltipString', '放大', 'ClickedCallback', @(~,~) zoom(tf_fig, 'on'));
                
                uipushtool(htoolbar, 'CData', imread(fullfile(iconpath, 'tool_zoom_out.png')), ...
                          'TooltipString', '缩小', 'ClickedCallback', @(~,~) zoom(tf_fig, 'off'));
                
                % 添加平移工具
                uipushtool(htoolbar, 'CData', imread(fullfile(iconpath, 'tool_hand.png')), ...
                          'TooltipString', '平移', 'ClickedCallback', @(~,~) pan(tf_fig, 'on'));
                
                % 添加数据游标
                uipushtool(htoolbar, 'CData', imread(fullfile(iconpath, 'tool_data_cursor.png')), ...
                          'TooltipString', '数据游标', 'ClickedCallback', @(~,~) datacursormode(tf_fig, 'on'));
                
                % 添加分隔符
                uipushtool(htoolbar, 'Separator', 'on');
                
                % 添加颜色图选择工具
                try
                    colormap_icon = imread(fullfile(iconpath, 'tool_colorbar.png'));
                catch
                    % 如果找不到图标，创建简单的颜色图标
                    colormap_icon = ones(16, 16, 3);
                    colormap_icon(:,:,1) = linspace(0, 1, 16)';
                    colormap_icon(:,:,2) = linspace(0, 1, 16);
                    colormap_icon(:,:,3) = 0.5;
                end
                uipushtool(htoolbar, 'CData', colormap_icon, ...
                          'TooltipString', '更改颜色图', ...
                          'ClickedCallback', @(~,~) visualizer.change_colormap(tf_fig));
                
                % 添加文本注释工具
                try
                    text_icon = imread(fullfile(iconpath, 'plottools_text.png'));
                catch
                    % 如果找不到图标，创建简单的文本图标
                    text_icon = ones(16, 16, 3) * 0.8;
                end
                uipushtool(htoolbar, 'CData', text_icon, ...
                          'TooltipString', '添加文本注释', ...
                          'ClickedCallback', @(~,~) visualizer.add_timefreq_annotation(tf_fig));
                
                % 添加频率标记线工具
                try
                    line_icon = imread(fullfile(iconpath, 'plottools_line.png'));
                catch
                    % 如果找不到图标，创建简单的线条图标
                    line_icon = ones(16, 16, 3) * 0.8;
                end
                uipushtool(htoolbar, 'CData', line_icon, ...
                          'TooltipString', '添加频率标记', ...
                          'ClickedCallback', @(~,~) visualizer.add_frequency_marker(tf_fig));
                
                % 添加分隔符
                uipushtool(htoolbar, 'Separator', 'on');
                
                % 添加保存工具
                uipushtool(htoolbar, 'CData', imread(fullfile(iconpath, 'file_save.png')), ...
                          'TooltipString', '保存时频图', ...
                          'ClickedCallback', @(~,~) visualizer.save_timefreq_figure(tf_fig));
                
                % 添加另存为工具
                try
                    saveas_icon = imread(fullfile(iconpath, 'file_saveas.png'));
                catch
                    saveas_icon = imread(fullfile(iconpath, 'file_save.png'));
                end
                uipushtool(htoolbar, 'CData', saveas_icon, ...
                          'TooltipString', '另存为...', ...
                          'ClickedCallback', @(~,~) visualizer.save_timefreq_figure_as(tf_fig));
                
                % 重置视图工具
                uipushtool(htoolbar, 'CData', imread(fullfile(iconpath, 'tool_rotate_3d.png')), ...
                          'TooltipString', '重置视图', ...
                          'ClickedCallback', @(~,~) visualizer.reset_timefreq_view(tf_fig));
                
            catch ME
                fprintf('创建时频分析工具栏时出错: %s\n', ME.message);
            end
        end
        
        function change_colormap(tf_fig)
            % 更改颜色图
            try
                colormaps = {'jet', 'hot', 'cool', 'parula', 'viridis', 'plasma', 'magma', 'gray'};
                [selection, ok] = listdlg('PromptString', '选择颜色图:', ...
                                         'SelectionMode', 'single', ...
                                         'ListString', colormaps, ...
                                         'InitialValue', 1);
                if ok
                    colormap(tf_fig, colormaps{selection});
                end
            catch ME
                msgbox(['更改颜色图失败: ' ME.message], 'Error', 'error');
            end
        end
        
        function add_timefreq_annotation(tf_fig)
            % 添加时频图注释
            try
                % 让用户输入文本
                text_str = inputdlg('请输入注释文本:', '添加时频图注释', 1, {'频率峰值'});
                if isempty(text_str)
                    return;
                end
                
                % 设置鼠标点击模式
                set(tf_fig, 'WindowButtonDownFcn', @(src, evt) place_tf_text(src, evt, text_str{1}));
                set(tf_fig, 'Pointer', 'crosshair');
                
                % 显示提示
                msgbox('点击时频图上的位置来放置注释', '添加注释', 'help');
                
            catch ME
                msgbox(['添加时频图注释失败: ' ME.message], 'Error', 'error');
            end
            
            function place_tf_text(src, ~, text_content)
                % 获取当前坐标轴
                current_axes = gca;
                if ~isempty(current_axes) && strcmp(get(current_axes, 'Type'), 'axes')
                    % 获取点击位置
                    point = get(current_axes, 'CurrentPoint');
                    x_pos = point(1, 1); % 时间 (μs)
                    y_pos = point(1, 2); % 频率 (kHz)
                    
                    % 添加文本，使用白色背景以便在彩色图上可见
                    text(x_pos, y_pos, text_content, 'FontSize', 10, ...
                         'BackgroundColor', [1, 1, 1, 0.8], 'EdgeColor', 'black', ...
                         'HorizontalAlignment', 'center', 'FontWeight', 'bold');
                end
                
                % 恢复正常鼠标模式
                set(src, 'WindowButtonDownFcn', '');
                set(src, 'Pointer', 'arrow');
            end
        end
        
        function add_frequency_marker(tf_fig)
            % 添加频率标记线
            try
                % 让用户选择标记类型
                marker_types = {'时间标记线', '频率标记线', '峰值标记点'};
                [selection, ok] = listdlg('PromptString', '选择标记类型:', ...
                                         'SelectionMode', 'single', ...
                                         'ListString', marker_types);
                if ~ok
                    return;
                end
                
                switch selection
                    case 1 % 时间标记线
                        visualizer.add_time_marker(tf_fig);
                    case 2 % 频率标记线
                        visualizer.add_freq_marker(tf_fig);
                    case 3 % 峰值标记点
                        visualizer.add_peak_marker(tf_fig);
                end
                
            catch ME
                msgbox(['添加频率标记失败: ' ME.message], 'Error', 'error');
            end
        end
        
        function add_time_marker(tf_fig)
            % 添加时间标记线
            set(tf_fig, 'WindowButtonDownFcn', @place_time_marker);
            set(tf_fig, 'Pointer', 'crosshair');
            msgbox('点击位置添加时间标记线', '添加时间标记', 'help');
            
            function place_time_marker(src, ~)
                current_axes = gca;
                if ~isempty(current_axes) && strcmp(get(current_axes, 'Type'), 'axes')
                    point = get(current_axes, 'CurrentPoint');
                    x_pos = point(1, 1); % 时间 (μs)
                    ylims = get(current_axes, 'YLim');
                    
                    line([x_pos, x_pos], ylims, 'Color', 'white', 'LineWidth', 2, ...
                         'LineStyle', '--', 'Parent', current_axes);
                    
                    % 添加标签
                    text(x_pos, ylims(2)*0.9, sprintf('t=%.1fμs', x_pos), ...
                         'Color', 'white', 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'center', 'Parent', current_axes);
                end
                set(src, 'WindowButtonDownFcn', '');
                set(src, 'Pointer', 'arrow');
            end
        end
        
        function add_freq_marker(tf_fig)
            % 添加频率标记线
            set(tf_fig, 'WindowButtonDownFcn', @place_freq_marker);
            set(tf_fig, 'Pointer', 'crosshair');
            msgbox('点击位置添加频率标记线', '添加频率标记', 'help');
            
            function place_freq_marker(src, ~)
                current_axes = gca;
                if ~isempty(current_axes) && strcmp(get(current_axes, 'Type'), 'axes')
                    point = get(current_axes, 'CurrentPoint');
                    y_pos = point(1, 2); % 频率 (kHz)
                    xlims = get(current_axes, 'XLim');
                    
                    line(xlims, [y_pos, y_pos], 'Color', 'white', 'LineWidth', 2, ...
                         'LineStyle', '--', 'Parent', current_axes);
                    
                    % 添加标签
                    text(xlims(2)*0.1, y_pos, sprintf('f=%.1fkHz', y_pos), ...
                         'Color', 'white', 'FontWeight', 'bold', ...
                         'VerticalAlignment', 'bottom', 'Parent', current_axes);
                end
                set(src, 'WindowButtonDownFcn', '');
                set(src, 'Pointer', 'arrow');
            end
        end
        
        function add_peak_marker(tf_fig)
            % 添加峰值标记点
            set(tf_fig, 'WindowButtonDownFcn', @place_peak_marker);
            set(tf_fig, 'Pointer', 'crosshair');
            msgbox('点击峰值位置添加标记点', '添加峰值标记', 'help');
            
            function place_peak_marker(src, ~)
                current_axes = gca;
                if ~isempty(current_axes) && strcmp(get(current_axes, 'Type'), 'axes')
                    point = get(current_axes, 'CurrentPoint');
                    x_pos = point(1, 1); % 时间 (μs)
                    y_pos = point(1, 2); % 频率 (kHz)
                    
                    % 添加标记点
                    plot(x_pos, y_pos, 'wo', 'MarkerSize', 8, 'LineWidth', 2, ...
                         'MarkerFaceColor', 'red', 'Parent', current_axes);
                    
                    % 添加标签
                    text(x_pos, y_pos, sprintf('  (%.1f,%.1f)', x_pos, y_pos), ...
                         'Color', 'white', 'FontWeight', 'bold', ...
                         'HorizontalAlignment', 'left', 'Parent', current_axes);
                end
                set(src, 'WindowButtonDownFcn', '');
                set(src, 'Pointer', 'arrow');
            end
        end
        
        function save_timefreq_figure(tf_fig)
            % 快速保存时频图（默认格式）
            try
                timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
                filename = sprintf('timefreq_analysis_%s.png', timestamp);
                
                % 保存到当前工作目录
                saveas(tf_fig, filename, 'png');
                msgbox(sprintf('时频图已保存为: %s', filename), '保存成功', 'help');
                
            catch ME
                msgbox(['保存时频图失败: ' ME.message], 'Error', 'error');
            end
        end
        
        function save_timefreq_figure_as(tf_fig)
            % 时频图另存为对话框
            try
                % 设置文件过滤器
                filters = {
                    '*.png', 'PNG图像文件 (*.png)';
                    '*.jpg', 'JPEG图像文件 (*.jpg)';
                    '*.tiff', 'TIFF图像文件 (*.tiff)';
                    '*.eps', 'EPS矢量文件 (*.eps)';
                    '*.pdf', 'PDF文件 (*.pdf)';
                    '*.svg', 'SVG矢量文件 (*.svg)';
                    '*.fig', 'MATLAB图形文件 (*.fig)';
                    '*.*', '所有文件 (*.*)'
                };
                
                % 默认文件名
                timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
                default_name = sprintf('timefreq_analysis_%s', timestamp);
                
                [filename, pathname, filterindex] = uiputfile(filters, '保存时频图', default_name);
                
                if filename ~= 0
                    full_path = fullfile(pathname, filename);
                    
                    % 根据选择的格式保存
                    switch filterindex
                        case 1 % PNG
                            saveas(tf_fig, full_path, 'png');
                        case 2 % JPG
                            saveas(tf_fig, full_path, 'jpg');
                        case 3 % TIFF
                            saveas(tf_fig, full_path, 'tiff');
                        case 4 % EPS
                            saveas(tf_fig, full_path, 'eps');
                        case 5 % PDF
                            saveas(tf_fig, full_path, 'pdf');
                        case 6 % SVG
                            saveas(tf_fig, full_path, 'svg');
                        case 7 % FIG
                            savefig(tf_fig, full_path);
                        otherwise
                            % 自动检测格式
                            [~, ~, ext] = fileparts(filename);
                            if strcmpi(ext, '.fig')
                                savefig(tf_fig, full_path);
                            else
                                saveas(tf_fig, full_path);
                            end
                    end
                    
                    msgbox(sprintf('时频图已保存为: %s', full_path), '保存成功', 'help');
                end
                
            catch ME
                msgbox(['保存时频图失败: ' ME.message], 'Error', 'error');
            end
        end
        
        function reset_timefreq_view(tf_fig)
            % 重置时频图视图
            try
                all_axes = findobj(tf_fig, 'Type', 'axes');
                for i = 1:length(all_axes)
                    axis(all_axes(i), 'tight');
                end
                
                % 关闭所有交互模式
                zoom(tf_fig, 'off');
                pan(tf_fig, 'off');
                datacursormode(tf_fig, 'off');
                
                msgbox('时频图视图已重置', '重置完成', 'help');
                
            catch ME
                msgbox(['重置时频图视图失败: ' ME.message], 'Error', 'error');
            end
        end
    end
end
