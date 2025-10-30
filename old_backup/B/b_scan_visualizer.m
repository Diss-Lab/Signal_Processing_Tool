classdef b_scan_visualizer < handle
    % B扫可视化模块 - 负责图形绘制和数据提取
    
    methods (Static)
        function plot_all_time_signals(time_axes, data_xyt, data_time, selected_time_range)
            % 绘制所有时域信号叠加图
            % 输入: time_axes - 轴句柄, data_xyt - 3D数据, data_time - 时间数据, selected_time_range - 选择的时间范围
            
            axes(time_axes);
            cla;
            hold on;
            
            [~, num_files, ~] = size(data_xyt);
            time_us = data_time * 1e6; % 转换为微秒
            
            % 生成颜色映射
            colors = lines(num_files);
            
            % 绘制所有信号
            for i = 1:num_files
                signal = squeeze(data_xyt(1, i, :));
                plot(time_us, signal, 'Color', colors(i, :), 'LineWidth', 1);
            end
            
            % 标记选择的时间范围
            ylims = ylim;
            if ~isempty(selected_time_range)
                fill([selected_time_range(1), selected_time_range(2), selected_time_range(2), selected_time_range(1)], ...
                     [ylims(1), ylims(1), ylims(2), ylims(2)], ...
                     [1, 1, 0], 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            end
            
            xlabel('Time (μs)', 'FontSize', 12);
            ylabel('Amplitude', 'FontSize', 12);
            title(sprintf('Time Domain Signals (Files 1-%d)', num_files), 'FontSize', 14);
            grid on;
            hold off;
            
            % 添加图例（如果文件数不太多）
            if num_files <= 10
                legend_labels = cell(num_files, 1);
                for i = 1:num_files
                    legend_labels{i} = sprintf('File %d', i);
                end
                legend(legend_labels, 'Location', 'best', 'FontSize', 8);
            end
        end
        
        function amplitudes = extract_peak_to_peak_amplitudes(data_xyt, data_time, selected_time_range)
            % 提取选择时间范围内每个文件的峰峰值
            % 输入: data_xyt - 3D数据, data_time - 时间数据, selected_time_range - 时间范围(微秒)
            % 输出: amplitudes - 峰峰值数组
            
            [~, num_files, ~] = size(data_xyt);
            amplitudes = zeros(num_files, 1);
            
            % 转换时间范围为索引
            time_us = data_time * 1e6;
            start_idx = find(time_us >= selected_time_range(1), 1, 'first');
            end_idx = find(time_us <= selected_time_range(2), 1, 'last');
            
            if isempty(start_idx)
                start_idx = 1;
            end
            if isempty(end_idx)
                end_idx = length(time_us);
            end
            
            % 提取每个文件在选择时间范围内的峰峰值
            for i = 1:num_files
                signal = squeeze(data_xyt(1, i, start_idx:end_idx));
                amplitudes(i) = max(signal) - min(signal); % 峰峰值
            end
        end
        
        function plot_amplitude_line(amp_axes, amplitudes, num_files)
            % 绘制幅值线图
            % 输入: amp_axes - 轴句柄, amplitudes - 幅值数组, num_files - 文件数量
            
            axes(amp_axes);
            cla;
            
            file_numbers = 1:num_files;
            
            % 绘制线图和点
            plot(file_numbers, amplitudes, 'b-o', 'LineWidth', 2, 'MarkerSize', 6, 'MarkerFaceColor', 'b');
            
            xlabel('File Number', 'FontSize', 12);
            ylabel('Peak-to-Peak Amplitude', 'FontSize', 12);
            title('Peak-to-Peak Amplitude vs File Number', 'FontSize', 14);
            grid on;
            
            % 设置x轴范围和刻度
            xlim([0.5, num_files + 0.5]);
            if num_files <= 20
                xticks(1:num_files);
            end
            
            % 添加数值标注（如果文件数不太多）
            if num_files <= 15
                for i = 1:num_files
                    text(i, amplitudes(i), sprintf('%.3f', amplitudes(i)), ...
                         'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                         'FontSize', 8);
                end
            end
            
            % 显示统计信息
            mean_amp = mean(amplitudes);
            std_amp = std(amplitudes);
            max_amp = max(amplitudes);
            min_amp = min(amplitudes);
            
            stats_text = sprintf('Mean: %.3f\nStd: %.3f\nMax: %.3f\nMin: %.3f', ...
                                mean_amp, std_amp, max_amp, min_amp);
            text(0.02, 0.98, stats_text, 'Units', 'normalized', ...
                 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
                 'BackgroundColor', 'white', 'FontSize', 10);
        end
    end
end
