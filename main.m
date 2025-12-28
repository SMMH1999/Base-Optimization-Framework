clear;
clc;
close all;

cd('C:\Users\pc\Desktop\کد نویسی و برنامه‌ها');
maxRun = 3;
if isempty(gcp)
    parpool("Processes",maxRun);
end

for index = 1 : 6
    addpath(genpath('C:\Users\pc\Desktop\کد نویسی و برنامه‌ها'));

    % Setting some variables
    CECsDim = cell([{"fix"}, [30, 100], [30, 100], {"fix"}, [10, 20], [10, 20]]);
    populationNo = 30;

    maxItr = 500;

    %     if index ~= 1
    % if index ~= 2
    %     if index ~= 3
    % if index ~= 4
    % if index ~= 5
    % if index ~= 6
    % if index ~= 1 && index ~= 2
    % if index ~= 1 && index ~= 6
    % if index ~= 4 && index ~= 5
    %     if index ~= 3 && index ~= 6
    % if index ~= 3 && index ~= 4 && index ~= 5 && index ~= 6
    %     if index ~= 1 && index ~= 2 && index ~= 6
    %         continue;
    %     end

    Comparetor3(index, populationNo, maxRun, maxItr, CECsDim{index});
    rmpath(genpath('C:\Users\pc\Desktop\کد نویسی و برنامه‌ها'));

end
% delete(gcp('nocreate'));