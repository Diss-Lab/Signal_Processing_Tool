function start_SPT()
    % SPT启动脚本
    % Signal Processing Tool 启动器
    
    fprintf('启动 Signal Processing Tool (SPT)...\n');
    
    % 添加路径
    current_path = fileparts(mfilename('fullpath'));
    addpath(genpath(current_path));
    
    % 启动主程序
    SPT();
    
    fprintf('SPT 已启动完成。\n');
end
