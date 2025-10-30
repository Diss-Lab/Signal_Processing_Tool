function start()
    % 快速启动脚本 - 一键启动信号处理工具
    
    fprintf('\n========================================\n');
    fprintf('Signal Processing Tool\n');
    fprintf('========================================\n\n');
    
    % 获取当前目录
    current_dir = pwd;
    script_dir = fileparts(mfilename('fullpath'));
    
    % 切换到项目根目录
    cd(script_dir);
    
    try
        % 启动主界面
        fprintf('正在启动主界面...\n\n');
        main_launcher();
        
    catch ME
        fprintf('启动失败: %s\n', ME.message);
        cd(current_dir);
        rethrow(ME);
    end
    
    % 返回原目录
    cd(current_dir);
end
