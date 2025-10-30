classdef wave_filters < handle
    % 波场滤波器模块 - 提供3D波场数据的滤波功能
    
    methods (Static)
        function filtered_data = apply_3d_filter(data_xyt, filter_type, low_freq, high_freq, fs)
            % 对3D波场数据应用滤波器
            % 输入:
            %   data_xyt - 3D波场数据 (m×n×t)
            %   filter_type - 滤波器类型 (1:无滤波, 2:高通, 3:低通, 4:带通)
            %   low_freq - 低频截止频率 (Hz)
            %   high_freq - 高频截止频率 (Hz)
            %   fs - 采样频率 (Hz)
            % 输出:
            %   filtered_data - 滤波后的3D数据
            
            if filter_type == 1
                % 无滤波
                filtered_data = data_xyt;
                return;
            end
            
            [m_size, n_size, t_size] = size(data_xyt);
            filtered_data = zeros(size(data_xyt));
            
            % 进度条
            h_wait = waitbar(0, 'Applying filter to wave field...');
            
            try
                total_points = m_size * n_size;
                processed_points = 0;
                
                for i = 1:m_size
                    for j = 1:n_size
                        signal = squeeze(data_xyt(i, j, :));
                        filtered_data(i, j, :) = wave_filters.apply_point_filter(signal, filter_type, low_freq, high_freq, fs);
                        
                        processed_points = processed_points + 1;
                        waitbar(processed_points/total_points, h_wait);
                    end
                end
                
                close(h_wait);
                
            catch ME
                close(h_wait);
                % 如果滤波失败，返回原数据
                warning(ME.identifier, 'Filter application failed: %s. Returning original data.', ME.message);
                filtered_data = data_xyt;
            end
        end
        
        function filtered_signal = apply_point_filter(signal, filter_type, low_freq, high_freq, fs)
            % 对单点信号应用滤波器
            
            try
                switch filter_type
                    case 2 % High Pass
                        filtered_signal = wave_filters.wordfilter(low_freq, fs/2-1, fs/1e6, signal);
                    case 3 % Low Pass
                        filtered_signal = wave_filters.wordfilter(1, low_freq, fs/1e6, signal);
                    case 4 % Band Pass
                        filtered_signal = wave_filters.wordfilter(low_freq, high_freq, fs/1e6, signal);
                    otherwise
                        filtered_signal = signal;
                end
            catch
                % 如果滤波失败，保持原信号
                filtered_signal = signal;
            end
        end
        
        function filtered_signal = wordfilter(low_freq, high_freq, fs_MHz, signal)
            % 基础带通滤波器实现
            % 这应该被替换为您实际的wordfilter函数
            
            fs = fs_MHz * 1e6;
            nyquist = fs / 2;
            
            if low_freq >= high_freq
                filtered_signal = signal;
                return;
            end
            
            % 归一化频率
            low_norm = low_freq / nyquist;
            high_norm = high_freq / nyquist;
            
            % 确保频率在有效范围内
            low_norm = max(0.001, min(0.999, low_norm));
            high_norm = max(0.001, min(0.999, high_norm));
            
            try
                [b, a] = butter(4, [low_norm, high_norm], 'bandpass');
                filtered_signal = filtfilt(b, a, signal);
            catch
                filtered_signal = signal;
            end
        end
        
        function filter_names = get_filter_names()
            % 获取滤波器类型名称
            filter_names = {'No Filter', 'High Pass', 'Low Pass', 'Band Pass'};
        end
        
        function result = validate_frequencies(low_freq, high_freq, fs)
            % 验证滤波器频率设置
            % 输入: low_freq, high_freq (Hz), fs - 采样频率 (Hz)
            % 输出: result - 包含验证结果的结构体
            
            result = struct();
            result.valid = true;
            result.message = '';
            
            nyquist = fs / 2;
            
            if low_freq <= 0
                result.valid = false;
                result.message = 'Low frequency must be positive';
                return;
            end
            
            if high_freq <= 0
                result.valid = false;
                result.message = 'High frequency must be positive';
                return;
            end
            
            if low_freq >= high_freq
                result.valid = false;
                result.message = 'Low frequency must be less than high frequency';
                return;
            end
            
            if high_freq >= nyquist
                result.valid = false;
                result.message = sprintf('High frequency must be less than Nyquist frequency (%.1f Hz)', nyquist);
                return;
            end
            
            result.message = 'Frequencies are valid';
        end
    end
end
