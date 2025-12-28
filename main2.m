%% Initialization
clearvars;    % Clear only variables, not everything
clc;          % Clear command window

% Set the base path for your code and add all subfolders
% Get current script path
scriptPath = mfilename('fullpath'); 
projectDir = fileparts(scriptPath);  % Parent folder (project root)

% Now projectDir is the same as basePath
basePath = projectDir;

addpath(genpath(basePath));


% Parameters
maxRun = 3;          % Number of independent runs for each algorithm
maxItr = 500;        % Maximum number of iterations
populationNo = 30;   % Population size for algorithms

% Start parallel pool if not already running
% if maxRun > 1 && isempty(gcp('nocreate'))
%     % "Processes" uses default number of workers; can adjust if needed
%     parpool("Processes", maxRun);
% end

% Define dimensions for each CEC benchmark
CECsDim = { {"fix"}, [30, 100], [30, 100], {"fix"}, [10, 20], [10, 20] };

% Select which CEC indices to run
selectedIndex = 6:6;   % Example: run all 6, can change to subset like [1,3,5]

%% Main execution loop
for index = selectedIndex
    fprintf('--- Running CEC Index %d ---\n', index);  % Inform which benchmark is running

    % Call the main comparison function for the selected CEC
    Comparetor3(index, populationNo, maxRun, maxItr, CECsDim{index});
end

%% Clean up
rmpath(genpath(basePath));       % Remove added paths
% delete(gcp('nocreate'));       % Uncomment if you want to close the parallel pool
