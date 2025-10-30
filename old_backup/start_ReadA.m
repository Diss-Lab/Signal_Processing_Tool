function start_ReadA()
    % ReadA便捷启动脚本
    % 自动初始化路径并启动ReadA界面
    
    fprintf('\n=== 启动ReadA模块 ===\n\n');
    
    % 获取脚本所在目录（项目根目录）
    project_root = fileparts(mfilename('fullpath'));
    
    % 切换到项目根目录
    old_dir = cd(project_root);
    
    try
        % 初始化路径
        fprintf('正在初始化项目路径...\n');
        init_project();
        
        % 启动ReadA
        fprintf('\n正在启动ReadA界面...\n\n');
        run('C:\Users\123\Documents\Projects\Signal_Processing_Tool\ui\main\ReadA.m');
        
    catch ME
        fprintf('\n❌ 启动失败: %s\n\n', ME.message);
        cd(old_dir);
        rethrow(ME);
    end
    
    % 返回原目录
    cd(old_dir);
end
