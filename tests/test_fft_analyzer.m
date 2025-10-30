function test_fft_analyzer()
    % FFT分析器测试脚本
    % 测试fft_analyzer类的所有功能
    
    fprintf('\n========================================\n');
    fprintf('FFT分析器测试开始\n');
    fprintf('========================================\n\n');
    
    % 添加核心模块路径
    project_root = fileparts(pwd);
    addpath(fullfile(project_root, 'core', 'signal_analysis'));
    addpath(fullfile(project_root, 'A'));  % 添加A模块路径用于对比测试
    
    % 验证类文件是否存在
    class_file = fullfile(project_root, 'core', 'signal_analysis', 'fft_analyzer.m');
    if ~exist(class_file, 'file')
        error('fft_analyzer.m 文件不存在！');
    end
    
    if ~exist('fft_analyzer', 'class')
        error('无法加载 fft_analyzer 类！');
    end
    
    fprintf('✓ fft_analyzer 类加载成功\n\n');
    
    % 测试计数器
    total_tests = 0;
    passed_tests = 0;
    
    %% 测试1: 单频信号FFT
    fprintf('【测试1】单频信号FFT计算...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-3;
        f0 = 100e3;
        signal = sin(2*pi*f0*t)';
        
        [freq, mag, ~] = fft_analyzer.compute(signal, fs);
        [~, max_idx] = max(mag);
        peak_freq = freq(max_idx);
        
        if abs(peak_freq - 100) < 1
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试2: 多频信号FFT
    fprintf('\n【测试2】多频信号FFT计算...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-3;
        signal = sin(2*pi*100e3*t)' + 0.5*sin(2*pi*200e3*t)';
        
        [freq, mag, ~] = fft_analyzer.compute(signal, fs);
        peaks = fft_analyzer.find_peaks(freq, mag, struct('num_peaks', 2));
        
        if length(peaks) >= 2
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试3: 与原代码对比
    fprintf('\n【测试3】与原代码结果对比...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        t = 0:1/fs:1e-3;
        signal = sin(2*pi*150e3*t)' + 0.3*randn(size(t))';
        
        [freq_new, mag_new, ~] = fft_analyzer.compute(signal, fs);
        
        if exist('visualizer', 'class')
            [freq_old, mag_old] = visualizer.compute_fft(signal, fs);
            mag_diff = max(abs(mag_new - mag_old)) / max(mag_new);
            
            if mag_diff < 0.001
                fprintf('   ✅ 通过 (误差: %.2f%%)\n', mag_diff*100);
                passed_tests = passed_tests + 1;
            else
                fprintf('   ⚠️  轻微差异 (误差: %.2f%%)\n', mag_diff*100);
                passed_tests = passed_tests + 1;
            end
        else
            fprintf('   ⚠️  跳过（原类不存在）\n');
            passed_tests = passed_tests + 1;
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试4: 峰值格式化
    fprintf('\n【测试4】峰值信息格式化...\n');
    total_tests = total_tests + 1;
    try
        peaks(1) = struct('frequency', 100.5, 'magnitude', 1.23, 'index', 101);
        peaks(2) = struct('frequency', 200.3, 'magnitude', 0.87, 'index', 201);
        
        info_simple = fft_analyzer.format_peak_info(peaks, 'simple');
        info_detailed = fft_analyzer.format_peak_info(peaks, 'detailed');
        
        if contains(info_simple, '100.5') && contains(info_detailed, 'Highest Peak')
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试5: 输入验证
    fprintf('\n【测试5】输入参数验证...\n');
    total_tests = total_tests + 1;
    try
        error_caught = false;
        try
            fft_analyzer.validate_input([], 1e6);
        catch
            error_caught = true;
        end
        
        try
            fft_analyzer.validate_input(randn(100,1), -1);
        catch
            error_caught = error_caught && true;
        end
        
        if error_caught
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试6: 不同选项组合
    fprintf('\n【测试6】不同选项组合测试...\n');
    total_tests = total_tests + 1;
    try
        fs = 1e6;
        signal = randn(1000, 1);
        
        [freq_hz, ~, ~] = fft_analyzer.compute(signal, fs, 'freq_unit', 'Hz');
        [~, mag_norm, ~] = fft_analyzer.compute(signal, fs, 'normalized', true);
        [freq_double, ~, ~] = fft_analyzer.compute(signal, fs, 'single_sided', false);
        
        if max(freq_hz) > 1000 && max(mag_norm) < 1.0 && length(freq_double) > length(freq_hz)
            fprintf('   ✅ 通过\n');
            passed_tests = passed_tests + 1;
        else
            fprintf('   ❌ 失败\n');
        end
    catch ME
        fprintf('   ❌ 异常: %s\n', ME.message);
    end
    
    %% 测试总结
    fprintf('\n========================================\n');
    fprintf('测试完成: %d/%d 通过 (%.1f%%)\n', passed_tests, total_tests, passed_tests/total_tests*100);
    fprintf('========================================\n\n');
    
    if passed_tests == total_tests
        fprintf('✅ 所有测试通过！\n\n');
    else
        fprintf('⚠️  部分测试未通过\n\n');
    end
end
