clear;
clc;
close all;

cd('C:\Users\pc\Desktop\کد نویسی و برنامه‌ها');

if isempty(gcp)
    parpool;
end



for index = 1 : 1    
    addpath(genpath('C:\Users\pc\Desktop\کد نویسی و برنامه‌ها'));
    
    % Setting some variables
    CECsDim = cell({"fix"});
    populationNo = 30;
    maxRun = 30;
    maxItr = 500;

    % if index ~= 1
    % if index ~= 2
    % if index ~= 3
    % if index ~= 4
    % if index ~= 5
    % if index ~= 6
    % if index ~= 1 && index ~= 5
    % if index ~= 1 && index ~= 6
    % if index ~= 4 && index ~= 5
    % if index ~= 5 && index ~= 6
    % if index ~= 1 && index ~= 3 && index ~= 6
    % 
    %     continue;
    % end
    
    Comparetor_RW(index, populationNo, maxRun, maxItr, CECsDim{index});
    rmpath(genpath('C:\Users\pc\Desktop\کد نویسی و برنامه‌ها'));

end
% delete(gcp('nocreate'));