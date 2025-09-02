classdef wave_field_analyzer < handle
    % 波场分析器 - 提供波场可视化和分析功能
    
    methods (Static)
        function create_analysis_ui(data_xyt, data_time, fs)
            % 创建波场分析界面
            % try
                % 验证输入参数
                if nargin < 3
                    error('需要三个参数: data_xyt, data_time, fs');
                end
                
                if isempty(data_xyt) || isempty(data_time) || fs <= 0
                    error('输入参数无效');
                end
                
                fprintf('创建分析界面 - 数据尺寸: %s\n', mat2str(size(data_xyt)));
                
                % 创建分析窗口
                analysis_fig = figure('Name', 'Wave Field Analysis', 'Position', [100, 50, 1000, 800], ...
                                     'MenuBar', 'none', 'ToolBar', 'none');
                
                % 左侧控制面板
                control_panel = uipanel('Parent', analysis_fig, 'Position', [0.01, 0.01, 0.25, 0.98], ...
                                       'Title', 'Analysis Controls');
                
                % 时间控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Time Control:', ...
                          'Position', [10, 750, 100, 20], 'FontWeight', 'bold');
                
                time_slider = uicontrol('Parent', control_panel, 'Style', 'slider', ...
                                       'Position', [10, 720, 200, 20], ...
                                       'Min', 1, 'Max', length(data_time), 'Value', 1, ...
                                       'SliderStep', [1/(length(data_time)-1), 10/(length(data_time)-1)]);
                
                time_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                     'String', sprintf('Time: %.2f μs', data_time(1)*1e6), ...
                                     'Position', [10, 695, 200, 20], ...
                                     'HorizontalAlignment', 'left');
                
                % 显示控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Display Options:', ...
                          'Position', [10, 700, 100, 20], 'FontWeight', 'bold');
                
                colormap_popup = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
                                          'String', {'jet', 'hot', 'cool', 'gray', 'bone', 'parula'}, ...
                                          'Position', [10, 670, 150, 25]);
                
                
                % 平滑开关
                smooth_checkbox = uicontrol('Parent', control_panel, 'Style', 'checkbox', ...
                                           'String', 'Enable Smoothing', 'Value', 0, ...
                                           'Position', [10, 650, 120, 20], ...
                                           'Callback', @toggle_smoothing);
                
                % 平滑方法选择
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Method:', ...
                          'Position', [3, 625, 50, 20]);
                smooth_method_popup = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
                                               'String', {'Gaussian', 'Average', 'Median', 'Bilateral'}, ...
                                               'Position', [50, 625, 80, 20], ...
                                               'Callback', @change_smooth_method);
                
                % 平滑强度滑块
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Intensity:', ...
                          'Position', [3, 600, 60, 20]);
                smooth_intensity_slider = uicontrol('Parent', control_panel, 'Style', 'slider', ...
                                                   'Position', [75, 600, 100, 20], ...
                                                   'Min', 0.5, 'Max', 5.0, 'Value', 1.5, ...
                                                   'SliderStep', [0.1/4.5, 0.5/4.5], ...
                                                   'Callback', @change_smooth_intensity);
                
                smooth_intensity_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                                 'String', '1.5', ...
                                                 'Position', [180, 600, 30, 20]);
                
                % 插值方法选择
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Interpolation:', ...
                          'Position', [10, 575, 80, 20]);
                interp_method_popup = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
                                               'String', {'None', 'Linear', 'Cubic', 'Spline'}, ...
                                               'Position', [150, 625, 80, 20], ...
                                               'Callback', @change_interp_method);
                
                % 滤波控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Filter Options:', ...
                          'Position', [10, 580, 100, 20], 'FontWeight', 'bold');
                
                filter_popup = uicontrol('Parent', control_panel, 'Style', 'popupmenu', ...
                                        'String', {'No Filter', 'High Pass', 'Low Pass', 'Band Pass'}, ...
                                        'Position', [10, 550, 100, 25]);
                
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Low Freq (kHz):', ...
                          'Position', [10, 520, 100, 20]);
                low_freq_edit = uicontrol('Parent', control_panel, 'Style', 'edit', 'String', '100', ...
                                         'Position', [110, 520, 60, 25]);
                
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'High Freq (kHz):', ...
                          'Position', [10, 490, 100, 20]);
                high_freq_edit = uicontrol('Parent', control_panel, 'Style', 'edit', 'String', '500', ...
                                          'Position', [110, 490, 60, 25]);
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Apply Filter', ...
                          'Position', [10, 450, 100, 30], 'BackgroundColor', [0.9 1.0 0.8], ...
                          'Callback', @apply_filter);
                
                % 动画控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Animation:', ...
                          'Position', [10, 400, 100, 20], 'FontWeight', 'bold');
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Play', ...
                          'Position', [10, 370, 60, 25], 'BackgroundColor', [0.8 1.0 0.8], ...
                          'Callback', @play_animation);
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', 'Stop', ...
                          'Position', [80, 370, 60, 25], 'BackgroundColor', [1.0 0.8 0.8], ...
                          'Callback', @stop_animation);
                
                % 播放速度控制
                uicontrol('Parent', control_panel, 'Style', 'text', 'String', 'Speed Control:', ...
                          'Position', [10, 340, 100, 20], 'FontWeight', 'bold');
                
                % 速度滑块
                speed_slider = uicontrol('Parent', control_panel, 'Style', 'slider', ...
                                        'Position', [10, 315, 150, 20], ...
                                        'Min', 0.1, 'Max', 5.0, 'Value', 1.0, ...
                                        'SliderStep', [0.1/4.9, 0.5/4.9]);
                
                % 速度显示文本
                speed_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                      'String', 'Speed: 1.0x', ...
                                      'Position', [170, 315, 50, 50], ...
                                      'HorizontalAlignment', 'left');
                
                % 预设速度按钮
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', '0.5x', ...
                          'Position', [10, 290, 35, 20], 'FontSize', 8, ...
                          'Callback', @(~,~) set_speed(0.5));
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', '1x', ...
                          'Position', [50, 290, 35, 20], 'FontSize', 8, ...
                          'Callback', @(~,~) set_speed(1.0));
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', '2x', ...
                          'Position', [90, 290, 35, 20], 'FontSize', 8, ...
                          'Callback', @(~,~) set_speed(2.0));
                
                uicontrol('Parent', control_panel, 'Style', 'pushbutton', 'String', '5x', ...
                          'Position', [130, 290, 35, 20], 'FontSize', 8, ...
                          'Callback', @(~,~) set_speed(5.0));
                
                % 信息显示
                info_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                     'String', sprintf('Data Info:\nSize: %dx%dx%d\nSampling: %.2f MHz\nDuration: %.2f ms', ...
                                                      size(data_xyt,1), size(data_xyt,2), size(data_xyt,3), ...
                                                      fs/1e6, (data_time(end)-data_time(1))*1000), ...
                                     'Position', [10, 150, 200, 100], ...
                                     'HorizontalAlignment', 'left', ...
                                     'BackgroundColor', [0.9 0.9 0.9]);
                
                % 点击信息显示
                click_text = uicontrol('Parent', control_panel, 'Style', 'text', ...
                                      'String', 'Click on wave field to analyze point', ...
                                      'Position', [10, 50, 200, 100], ...
                                      'HorizontalAlignment', 'left', ...
                                      'BackgroundColor', [0.9 0.9 0.9]);
                
                % 右侧显示区域
                display_panel = uipanel('Parent', analysis_fig, 'Position', [0.27, 0.01, 0.72, 0.98], ...
                                       'Title', 'Wave Field Visualization');
                
                % 波场显示轴
                wave_axes = axes('Parent', display_panel, 'Position', [0.05, 0.55, 0.9, 0.4]);
                
                % 时域信号显示轴
                time_axes = axes('Parent', display_panel, 'Position', [0.05, 0.05, 0.42, 0.4]);
                
                % 频域信号显示轴
                freq_axes = axes('Parent', display_panel, 'Position', [0.53, 0.05, 0.42, 0.4]);
                
                % 初始化变量
                current_time_idx = 1;
                filtered_data = data_xyt;
                animation_timer = [];
                animation_speed = 1.0; % 播放速度倍数
                base_period = 0.1; % 基础播放周期（秒）
                is_playing = false; % 动画播放状态
                
                % 平滑处理参数
                use_smoothing = false;
                smooth_method = 'Gaussian';
                smooth_intensity = 1.5;
                interp_method = 'None';
                
                % 初始显示
                update_wavefield();
                
                fprintf('分析界面创建成功\n');
                
                % 回调函数
                function apply_filter(~, ~)
                    try
                        filter_type = get(filter_popup, 'Value');
                        low_freq = str2double(get(low_freq_edit, 'String')) * 1000; % 转换为Hz
                        high_freq = str2double(get(high_freq_edit, 'String')) * 1000; % 转换为Hz
                        
                        if filter_type == 1 % No Filter
                            filtered_data = data_xyt;
                            msgbox('Filter removed', 'Info');
                        else
                            % 应用滤波器
                            filtered_data = apply_3d_filter_helper(data_xyt, filter_type, low_freq, high_freq, fs);
                            msgbox('Filter applied successfully!', 'Success');
                        end
                        
                        update_wavefield();
                        
                    catch ME
                        msgbox(['Filter error: ' ME.message], 'Error', 'error');
                    end
                end
                
                function update_time(~, ~)
                    try
                        current_time_idx = round(get(time_slider, 'Value'));
                        set(time_text, 'String', sprintf('Time: %.2f μs', data_time(current_time_idx)*1e6));
                        update_wavefield();
                    catch ME
                        fprintf('更新时间失败: %s\n', ME.message);
                    end
                end
                
                function toggle_smoothing(~, ~)
                    use_smoothing = get(smooth_checkbox, 'Value');
                    update_wavefield();
                end
                
                function change_smooth_method(~, ~)
                    methods = get(smooth_method_popup, 'String');
                    smooth_method = methods{get(smooth_method_popup, 'Value')};
                    if use_smoothing
                        update_wavefield();
                    end
                end
                
                function change_smooth_intensity(~, ~)
                    smooth_intensity = get(smooth_intensity_slider, 'Value');
                    set(smooth_intensity_text, 'String', sprintf('%.1f', smooth_intensity));
                    if use_smoothing
                        update_wavefield();
                    end
                end
                
                function change_interp_method(~, ~)
                    methods = get(interp_method_popup, 'String');
                    interp_method = methods{get(interp_method_popup, 'Value')};
                    update_wavefield();
                end
                
                function update_wavefield()
                    try
                        % 显示当前时刻的波场
                        axes(wave_axes);
                        cla;
                        
                        wave_field = squeeze(filtered_data(:, :, current_time_idx));
                        
                        % 应用平滑处理
                        if use_smoothing
                            wave_field = apply_smoothing(wave_field, smooth_method, smooth_intensity);
                        end
                        
                        % 应用插值处理
                        if ~strcmp(interp_method, 'None')
                            wave_field = apply_interpolation(wave_field, interp_method);
                        end
                        
                        % 使用imagesc绘制并获取图像句柄
                        h_image = imagesc(wave_field);
                        axis equal;
                        axis tight;
                        
                        % 设置颜色映射
                        colormap_names = get(colormap_popup, 'String');
                        colormap_idx = get(colormap_popup, 'Value');
                        colormap(wave_axes, colormap_names{colormap_idx});
                        colorbar(wave_axes);
                        
                        % 添加平滑状态到标题
                        title_str = sprintf('Wave Field at t = %.2f μs', data_time(current_time_idx)*1e6);
                        if use_smoothing
                            title_str = [title_str, sprintf(' [%s Smoothed]', smooth_method)];
                        end
                        if ~strcmp(interp_method, 'None')
                            title_str = [title_str, sprintf(' [%s Interp]', interp_method)];
                        end
                        title(wave_axes, title_str);
                        
                        xlabel(wave_axes, 'X Position');
                        ylabel(wave_axes, 'Y Position');
                        
                        % 同时设置轴和图像的点击回调
                        set(wave_axes, 'ButtonDownFcn', @wavefield_click);
                        set(h_image, 'ButtonDownFcn', @wavefield_click);
                        
                        % 确保轴可以响应点击
                        set(wave_axes, 'HitTest', 'on');
                        set(h_image, 'HitTest', 'on');
                        
                    catch ME
                        fprintf('更新波场显示失败: %s\n', ME.message);
                    end
                end
                
                function smoothed_field = apply_smoothing(wave_field, method, intensity)
                    % 应用平滑处理
                    try
                        switch method
                            case 'Gaussian'
                                % 高斯滤波
                                sigma = intensity;
                                smoothed_field = imgaussfilt(wave_field, sigma);
                                
                            case 'Average'
                                % 均值滤波
                                kernel_size = max(3, round(intensity * 2) * 2 + 1); % 确保奇数
                                h = fspecial('average', kernel_size);
                                smoothed_field = imfilter(wave_field, h, 'replicate');
                                
                            case 'Median'
                                % 中值滤波
                                kernel_size = max(3, round(intensity * 2) * 2 + 1); % 确保奇数
                                smoothed_field = medfilt2(wave_field, [kernel_size, kernel_size]);
                                
                            case 'Bilateral'
                                % 双边滤波（如果可用）
                                try
                                    degree_of_smoothing = intensity * 10;
                                    smoothed_field = imbilatfilt(wave_field, degree_of_smoothing);
                                catch
                                    % 如果imbilatfilt不可用，使用高斯滤波替代
                                    smoothed_field = imgaussfilt(wave_field, intensity);
                                end
                                
                            otherwise
                                smoothed_field = wave_field;
                        end
                    catch
                        % 如果平滑处理失败，返回原图像
                        smoothed_field = wave_field;
                    end
                end
                
                function interp_field = apply_interpolation(wave_field, method)
                    % 应用插值处理以增加分辨率
                    try
                        [m, n] = size(wave_field);
                        scale_factor = 2; % 插值倍数
                        
                        % 创建新的网格
                        [X, Y] = meshgrid(1:n, 1:m);
                        [Xi, Yi] = meshgrid(1:1/scale_factor:n, 1:1/scale_factor:m);
                        
                        switch method
                            case 'Linear'
                                interp_field = interp2(X, Y, wave_field, Xi, Yi, 'linear');
                                
                            case 'Cubic'
                                interp_field = interp2(X, Y, wave_field, Xi, Yi, 'cubic');
                                
                            case 'Spline'
                                interp_field = interp2(X, Y, wave_field, Xi, Yi, 'spline');
                                
                            otherwise
                                interp_field = wave_field;
                        end
                        
                        % 处理NaN值
                        interp_field(isnan(interp_field)) = 0;
                        
                    catch
                        % 如果插值失败，返回原图像
                        interp_field = wave_field;
                    end
                end
                
                function update_wavefield_old()
                    try
                        % 显示当前时刻的波场
                        axes(wave_axes);
                        cla;
                        
                        wave_field = squeeze(filtered_data(:, :, current_time_idx));
                        
                        % 使用imagesc绘制并获取图像句柄
                        h_image = imagesc(wave_field);
                        axis equal;
                        axis tight;
                        
                        % 设置颜色映射
                        colormap_names = get(colormap_popup, 'String');
                        colormap_idx = get(colormap_popup, 'Value');
                        colormap(wave_axes, colormap_names{colormap_idx});
                        colorbar(wave_axes);
                        
                        title(wave_axes, sprintf('Wave Field at t = %.2f μs', data_time(current_time_idx)*1e6));
                        xlabel(wave_axes, 'X Position');
                        ylabel(wave_axes, 'Y Position');
                        
                        % 同时设置轴和图像的点击回调
                        set(wave_axes, 'ButtonDownFcn', @wavefield_click);
                        set(h_image, 'ButtonDownFcn', @wavefield_click);
                        
                        % 确保轴可以响应点击
                        set(wave_axes, 'HitTest', 'on');
                        set(h_image, 'HitTest', 'on');
                        
                    catch ME
                        fprintf('更新波场显示失败: %s\n', ME.message);
                    end
                end
                
                function wavefield_click(src, ~)
                    try
                        % 获取点击位置
                        if src == wave_axes
                            point = get(wave_axes, 'CurrentPoint');
                        else
                            % 如果是图像对象被点击，获取轴的CurrentPoint
                            point = get(get(src, 'Parent'), 'CurrentPoint');
                        end
                        
                        % 转换坐标（注意imagesc的坐标系统）
                        x_idx = round(point(1, 2)); % Y坐标对应行索引
                        y_idx = round(point(1, 1)); % X坐标对应列索引
                        
                        [m_size, n_size, ~] = size(filtered_data);
                        
                        % 检查坐标是否在有效范围内
                        if x_idx >= 1 && x_idx <= m_size && y_idx >= 1 && y_idx <= n_size
                            fprintf('点击位置: (%d, %d)\n', x_idx, y_idx);
                            
                            % 提取该点的时域信号
                            point_signal = squeeze(filtered_data(x_idx, y_idx, :));
                            
                            % 绘制时域信号
                            axes(time_axes);
                            cla;
                            h_time = plot(data_time * 1e6, point_signal, 'b-', 'LineWidth', 1.5);
                            title(sprintf('Time Domain Signal - Point (%d,%d)', x_idx, y_idx));
                            xlabel('Time (μs)');
                            ylabel('Amplitude');
                            grid on;
                            
                            % 设置时域图的点击回调
                            set(time_axes, 'ButtonDownFcn', @time_click);
                            set(h_time, 'ButtonDownFcn', @time_click);
                            
                            % 绘制频域信号
                            axes(freq_axes);
                            cla;
                            try
                                [freq_vector, magnitude] = compute_fft_helper(point_signal, fs);
                                h_freq = plot(freq_vector, magnitude, 'r-', 'LineWidth', 1.5);
                                title(sprintf('Frequency Spectrum - Point (%d,%d)', x_idx, y_idx));
                                xlabel('Frequency (kHz)');
                                ylabel('Magnitude');
                                grid on;
                                
                                % 设置频域图的点击回调
                                set(freq_axes, 'ButtonDownFcn', @freq_click);
                                set(h_freq, 'ButtonDownFcn', @freq_click);
                                
                            catch ME
                                fprintf('FFT计算失败: %s\n', ME.message);
                                text(0.5, 0.5, 'FFT computation failed', 'Units', 'normalized', ...
                                     'HorizontalAlignment', 'center');
                            end
                            
                            % 更新点击信息
                            max_amp = max(abs(point_signal));
                            rms_val = sqrt(mean(point_signal.^2)); % 使用更准确的RMS计算
                            
                            set(click_text, 'String', sprintf('Selected Point:\nPosition: (%d, %d)\nMax Amplitude: %.2e\nRMS: %.2e\nClick successful!', ...
                                                             x_idx, y_idx, max_amp, rms_val));
                        else
                            fprintf('点击位置超出范围: (%d, %d), 有效范围: [1-%d, 1-%d]\n', x_idx, y_idx, m_size, n_size);
                            set(click_text, 'String', sprintf('Click out of range:\nClicked: (%d, %d)\nValid range: [1-%d, 1-%d]', ...
                                                             x_idx, y_idx, m_size, n_size));
                        end
                        
                    catch ME
                        fprintf('波场点击处理失败: %s\n', ME.message);
                        set(click_text, 'String', sprintf('Click processing failed:\n%s', ME.message));
                    end
                end
                
                function time_click(src, ~)
                    try
                        % 获取时域图点击位置
                        if src == time_axes
                            point = get(time_axes, 'CurrentPoint');
                        else
                            point = get(get(src, 'Parent'), 'CurrentPoint');
                        end
                        
                        x_coord = point(1, 1); % 时间 (μs)
                        y_coord = point(1, 2); % 幅值
                        
                        set(click_text, 'String', sprintf('Time Domain Click:\nTime: %.2f μs\nAmplitude: %.4e', ...
                                                         x_coord, y_coord));
                    catch ME
                        fprintf('时域图点击失败: %s\n', ME.message);
                    end
                end
                
                function freq_click(src, ~)
                    try
                        % 获取频域图点击位置
                        if src == freq_axes
                            point = get(freq_axes, 'CurrentPoint');
                        else
                            point = get(get(src, 'Parent'), 'CurrentPoint');
                        end
                        
                        x_coord = point(1, 1); % 频率 (kHz)
                        y_coord = point(1, 2); % 幅值
                        
                        set(click_text, 'String', sprintf('Frequency Domain Click:\nFrequency: %.1f kHz\nMagnitude: %.2e', ...
                                                         x_coord, y_coord));
                    catch ME
                        fprintf('频域图点击失败: %s\n', ME.message);
                    end
                end
                
                function play_animation(~, ~)
                    if is_playing
                        % 如果已在播放，先停止
                        stop_animation();
                    end
                    
                    % 清理旧的定时器
                    if ~isempty(animation_timer) && isvalid(animation_timer)
                        stop(animation_timer);
                        delete(animation_timer);
                        animation_timer = [];
                    end
                    
                    % 根据当前速度设置定时器周期
                    current_period = base_period / animation_speed;
                    
                    % 创建新的定时器
                    animation_timer = timer(...
                        'ExecutionMode', 'fixedRate', ...
                        'Period', current_period, ...
                        'TimerFcn', @animate_frame, ...
                        'StopFcn', @animation_stopped, ...
                        'ErrorFcn', @animation_error);
                    
                    % 启动定时器
                    start(animation_timer);
                    is_playing = true;
                    
                    fprintf('动画开始播放，周期: %.3f秒\n', current_period);
                end
                
                function stop_animation(~, ~)
                    if ~isempty(animation_timer) && isvalid(animation_timer)
                        try
                            stop(animation_timer);
                            delete(animation_timer);
                        catch
                            % 忽略停止错误
                        end
                        animation_timer = [];
                    end
                    is_playing = false;
                    fprintf('动画已停止\n');
                end
                
                function animation_stopped(~, ~)
                    % 定时器停止回调
                    is_playing = false;
                    fprintf('定时器已停止\n');
                end
                
                function animation_error(timer_obj, ~)
                    % 定时器错误回调
                    fprintf('定时器错误，正在清理\n');
                    try
                        stop(timer_obj);
                        delete(timer_obj);
                    catch
                        % 忽略清理错误
                    end
                    animation_timer = [];
                    is_playing = false;
                end
                
                function animate_frame(~, ~)
                    try
                        % 检查figure是否仍然存在
                        if ~ishandle(analysis_fig)
                            stop_animation();
                            return;
                        end
                        
                        % 更新时间索引
                        current_time_idx = current_time_idx + 1;
                        if current_time_idx > length(data_time)
                            current_time_idx = 1;
                        end
                        
                        % 更新界面（使用try-catch防止界面更新错误）
                        try
                            set(time_slider, 'Value', current_time_idx);
                            set(time_text, 'String', sprintf('Time: %.2f μs', data_time(current_time_idx)*1e6));
                            update_wavefield();
                        catch ME
                            fprintf('界面更新失败: %s\n', ME.message);
                            stop_animation();
                        end
                        
                        % 强制刷新显示
                        drawnow limitrate;
                        
                    catch ME
                        fprintf('动画帧更新失败: %s\n', ME.message);
                        stop_animation();
                    end
                end
                
                function set_speed(speed_value)
                    % 设置播放速度
                    animation_speed = speed_value;
                    set(speed_slider, 'Value', speed_value);
                    set(speed_text, 'String', sprintf('Speed: %.1fx', speed_value));
                    
                    % 如果动画正在播放，重新启动以应用新速度
                    if is_playing
                        % 停止当前动画
                        stop_animation();
                        
                        % 稍微延迟后重新启动（确保停止完成）
                        pause(0.05);
                        
                        % 重新启动动画
                        play_animation();
                    end
                end
                
                function update_speed_from_slider(~, ~)
                    % 从滑块更新播放速度
                    speed_value = get(speed_slider, 'Value');
                    set_speed(speed_value);
                end
                
                % 设置回调函数
                set(time_slider, 'Callback', @update_time);
                set(colormap_popup, 'Callback', @(~,~) update_wavefield());
                set(speed_slider, 'Callback', @update_speed_from_slider);
                
                % 清理函数
                set(analysis_fig, 'CloseRequestFcn', @cleanup_and_close);
                
                function cleanup_and_close(~, ~)
                    try
                        % 首先停止动画
                        if is_playing
                            stop_animation();
                        end
                        
                        % 等待一小段时间确保定时器完全停止
                        pause(0.1);
                        
                        % 清理任何剩余的定时器
                        if ~isempty(animation_timer) && isvalid(animation_timer)
                            try
                                stop(animation_timer);
                                delete(animation_timer);
                            catch
                                % 忽略清理错误
                            end
                        end
                        
                        % 删除figure
                        if ishandle(analysis_fig)
                            delete(analysis_fig);
                        end
                        
                        fprintf('分析窗口已关闭\n');
                        
                    catch ME
                        fprintf('清理失败: %s\n', ME.message);
                        % 强制删除figure
                        try
                            delete(analysis_fig);
                        catch
                            % 忽略删除错误
                        end
                    end
                end
                
            % catch ME
            %     fprintf('波场分析创建失败: %s\n', getReport(ME));
            %     msgbox(['波场分析创建失败: ' ME.message], 'Error', 'error');
            % end
        end
    end
end

% 辅助函数 - 移到类定义外部
function filtered_data = apply_3d_filter_helper(data_xyt, filter_type, low_freq, high_freq, fs)
    % 对3D数据应用滤波器
    [m, n, t] = size(data_xyt);
    filtered_data = zeros(size(data_xyt));
    
    for i = 1:m
        for j = 1:n
            signal = squeeze(data_xyt(i, j, :));
            filtered_data(i, j, :) = apply_1d_filter_helper(signal, filter_type, low_freq, high_freq, fs);
        end
    end
end

function filtered_signal = apply_1d_filter_helper(signal, filter_type, low_freq, high_freq, fs)
    % 对1D信号应用滤波器
    try
        nyquist = fs / 2;
        
        switch filter_type
            case 2 % High Pass
                low_norm = low_freq / nyquist;
                [b, a] = butter(4, low_norm, 'high');
            case 3 % Low Pass
                high_norm = high_freq / nyquist;
                [b, a] = butter(4, high_norm, 'low');
            case 4 % Band Pass
                low_norm = low_freq / nyquist;
                high_norm = high_freq / nyquist;
                [b, a] = butter(4, [low_norm, high_norm], 'bandpass');
            otherwise
                filtered_signal = signal;
                return;
        end
        
        filtered_signal = filtfilt(b, a, signal);
        
    catch
        filtered_signal = signal; % 如果滤波失败，返回原信号
    end
end

function [freq_vector, magnitude] = compute_fft_helper(signal, fs)
    % 计算FFT
    N = length(signal);
    Y = fft(signal);
    freq_vector = (0:N-1) * fs / N / 1000; % 转换为 kHz
    magnitude = abs(Y);
    
    % 只返回前半部分（正频率）
    freq_vector = freq_vector(1:floor(N/2));
    magnitude = magnitude(1:floor(N/2));
end
