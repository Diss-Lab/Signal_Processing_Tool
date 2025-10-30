classdef filters < handle
    % 滤波器模块 - 提供各种信号滤波功能
    
    methods (Static)
        function filtered_signal = apply_filter(signal, filter_type, low_freq, high_freq, fs)
            % 应用滤波器
            % 输入:
            %   signal - 输入信号
            %   filter_type - 滤波器类型 (1:无滤波, 2:高通, 3:低通, 4:带通)
            %   low_freq - 低频截止频率 (Hz)
            %   high_freq - 高频截止频率 (Hz)
            %   fs - 采样频率 (Hz)
            % 输出:
            %   filtered_signal - 滤波后的信号
            
            try
                switch filter_type
                    case 1 % No Filter
                        filtered_signal = signal;
                    case 2 % High Pass
                        filtered_signal = filters.wordfilter(low_freq, fs/2-1, fs/1e6, signal);
                    case 3 % Low Pass
                        filtered_signal = filters.wordfilter(1, low_freq, fs/1e6, signal);
                    case 4 % Band Pass
                        filtered_signal = filters.wordfilter(low_freq, high_freq, fs/1e6, signal);
                    otherwise
                        filtered_signal = signal;
                end
            catch ME
                warning(ME.identifier, 'Filter error: %s. Returning original signal.', ME.message);
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
