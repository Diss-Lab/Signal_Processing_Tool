classdef b_scan_analyzer < handle
    % B扫分析模块 - 提供时域信号分析和幅值提取功能
    
    methods (Static)
        function create_analysis_ui(data_xyt, data_time, fs)
            % 创建B扫分析界面
            % 输入: data_xyt - 3D数据(1×m×t), data_time - 时间数据, fs - 采样频率
            
            % 创建分析界面
            analysis_fig = figure('Name', 'B-Scan Analysis', 'Position', [200, 50, 1200, 700], ...
                                 'MenuBar', 'none', 'ToolBar', 'none');
            
            % 提取数据维度信息
            [~, num_files, num_time_points] = size(data_xyt);
            time_range = [data_time(1), data_time(end)] * 1e6; % 转换为微秒
            
            % 选择的时间范围
            selected_time_range = time_range;
            
            % 左侧控制面板
            control_panel = uipanel('Parent', analysis_fig, 'Position', [0.02, 0.02, 0.25, 0.96], ...
                                   'Title', 'Control Panel');
            
            % 数据信息显示
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Data Information:', ...
                      'Position', [10, 590, 100, 60], 'FontWeight', 'bold');
            
            info_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                 'String', sprintf('Files: %d\nTime Points: %d\nSampling Rate: %.2f MHz\nDuration: %.2f μs', ...
                                                  num_files, num_time_points, fs/1e6, (data_time(end)-data_time(1))*1e6), ...
                                 'Position', [10, 520, 200, 80], ...
                                 'HorizontalAlignment', 'left');
            
            % 时间范围选择
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Time Range Selection (μs):', ...
                      'Position', [10, 480, 160, 20], 'FontWeight', 'bold');
            
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Start Time:', ...
                      'Position', [10, 450, 80, 20]);
            start_time_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
                                       'String', sprintf('%.2f', time_range(1)), ...
                                       'Position', [100, 450, 80, 25]);
            
            uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'End Time:', ...
                      'Position', [10, 420, 80, 20]);
            end_time_edit = uicontrol('Parent', control_panel, 'Style', 'edit', ...
                                     'String', sprintf('%.2f', time_range(2)), ...
                                     'Position', [100, 420, 80, 25]);
            
            % 应用时间范围按钮
            uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Apply Time Range', ...
                      'Position', [60, 380, 120, 30], 'BackgroundColor', [0.8 0.9 1.0], ...
                      'Callback', @apply_time_range);
            
            % 提取幅值按钮
            uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Extract Peak-to-Peak', ...
                      'Position', [60, 330, 120, 30], 'BackgroundColor', [0.9 1.0 0.8], ...
                      'Callback', @extract_amplitude);
            
            % 选择的时间范围显示
            range_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                  'String', sprintf('Selected Range:\n%.2f - %.2f μs', selected_time_range(1), selected_time_range(2)), ...
                                  'Position', [10, 270, 200, 40], ...
                                  'HorizontalAlignment', 'left', ...
                                  'BackgroundColor', [0.9 0.9 0.9]);
            
            % 右侧显示区域
            % 时域信号图
            time_panel = uipanel('Parent', analysis_fig, 'Position', [0.29, 0.52, 0.69, 0.46], ...
                                'Title', 'Time Domain Signals (All Files)');
            time_axes = axes('Parent', time_panel, 'Position', [0.1, 0.2, 0.85, 0.7]);
            
            % 幅值图
            amp_panel = uipanel('Parent', analysis_fig, 'Position', [0.29, 0.02, 0.69, 0.46], ...
                               'Title', 'Peak-to-Peak Amplitude vs File Number');
            amp_axes = axes('Parent', amp_panel, 'Position', [0.1, 0.2, 0.85, 0.7]);
            
            % 初始化显示
            update_time_plots();
            clear_amplitude_plot();
            
            function apply_time_range(~, ~)
                try
                    start_time = str2double(get(start_time_edit, 'String'));
                    end_time = str2double(get(end_time_edit, 'String'));
                    
                    if isnan(start_time) || isnan(end_time) || start_time >= end_time
                        msgbox('Invalid time range! Please enter valid start and end times.', 'Error', 'error');
                        return;
                    end
                    
                    if start_time < time_range(1) || end_time > time_range(2)
                        msgbox(sprintf('Time range must be within %.2f - %.2f μs', time_range(1), time_range(2)), 'Error', 'error');
                        return;
                    end
                    
                    selected_time_range = [start_time, end_time];
                    set(range_text, 'String', sprintf('Selected Range:\n%.2f - %.2f μs', start_time, end_time));
                    
                    % 更新时域图显示选择范围
                    update_time_plots();
                    
                catch ME
                    msgbox(['Error applying time range: ' ME.message], 'Error', 'error');
                end
            end
            
            function extract_amplitude(~, ~)
                try
                    % 调用可视化模块提取幅值
                    amplitudes = b_scan_visualizer.extract_peak_to_peak_amplitudes(data_xyt, data_time, selected_time_range);
                    
                    % 绘制幅值图
                    b_scan_visualizer.plot_amplitude_line(amp_axes, amplitudes, num_files);
                    
                    msgbox(sprintf('Peak-to-peak amplitudes extracted for %d files in time range %.2f - %.2f μs', ...
                                  num_files, selected_time_range(1), selected_time_range(2)), 'Success');
                    
                catch ME
                    msgbox(['Error extracting amplitudes: ' ME.message], 'Error', 'error');
                end
            end
            
            function update_time_plots()
                % 使用可视化模块绘制时域信号
                b_scan_visualizer.plot_all_time_signals(time_axes, data_xyt, data_time, selected_time_range);
            end
            
            function clear_amplitude_plot()
                % 清空幅值图
                axes(amp_axes);
                cla;
                xlabel('File Number', 'FontSize', 12);
                ylabel('Peak-to-Peak Amplitude', 'FontSize', 12);
                title('Peak-to-Peak Amplitude vs File Number', 'FontSize', 14);
                grid on;
                text(0.5, 0.5, 'Click "Extract Peak-to-Peak" to generate amplitude plot', ...
                     'Units', 'normalized', 'HorizontalAlignment', 'center', ...
                     'FontSize', 12, 'Color', [0.5 0.5 0.5]);
            end
        end
    end
end
