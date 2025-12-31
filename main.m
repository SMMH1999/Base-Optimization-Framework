%% Initialization
clearvars;    % Clear only variables, not everything
clc;          % Clear command window

% Set the base path to the folder where this script is located
basePath = fileparts(which('main.m'));
cd(basePath);

% --- Ensure algorithms submodule exists and is not stale ---
algDir = fullfile(basePath, 'optimization algorithms');
ensureAlgorithmsSubmodule(basePath, algDir, 14); % 14 days threshold


addedPaths = genpath(basePath);
addpath(addedPaths);

% Initialize versioned results context (creates results_YY-MM-DD HH-MM and snapshots templates)
ProjectContext('init', basePath);


%% ---------------- Parallel control (GLOBAL FLAG) ----------------
% Global switch:
% true  -> enable parallel execution (parfor inside RunBenchmarkSuite)
% false -> run everything serially
global RUN_PARALLEL;
RUN_PARALLEL = false;   % <<< set to false to disable parallel mode

% Parameters
maxRun = 1;          % Number of independent runs for each algorithm
maxItr = 500;        % Maximum number of iterations
populationNo = 30;   % Population size for algorithms

% Start parallel pool only if parallel mode is enabled
if RUN_PARALLEL
    c = parcluster;
    maxAllowedWorkers = c.NumWorkers;

    % Best practice: match workers with maxRun if you parallelize the run-loop
    numWorkers = min(maxRun, maxAllowedWorkers);

    if numWorkers > 1 && isempty(gcp('nocreate'))
        % "Processes" is usually better for CPU-heavy independent runs
        parpool("Processes", numWorkers);
    end
end

% Define dimensions for each benchmark set
CECsDim = { ...
    { {'fixDim', []} }, ...                          % CEC2005
    { 10, 30, 50, 100 }, ...                         % CEC2014
    { 10, 30, 50, 100 }, ...                         % CEC2017
    { {'fixDim', []} }, ...                          % CEC2019
    { 10, 20 }, ...                              % CEC2020
    { 10, 20 }, ...                               % CEC2022
    { {'fixDim', []} }, ...                              % Real World Problem
};

% CECsDim = { ...
%     { {'fixDim', []} }, ...                          % CEC2005
%     { 10, 30, 50, 100 }, ...                         % CEC2014
%     { 10, 30, 50, 100 }, ...                         % CEC2017
%     { {'fixDim', []} }, ...                          % CEC2019
%     { 10, 15, 20 }, ...                              % CEC2020
%     { 10, 15, 20 } ...                               % CEC2022
% };



% Select which benchmark indices to run
selectedIndex = 7:7;

%% Main execution loop
for index = selectedIndex
    fprintf('--- Running Benchmark Index %d ---\n', index);
    cd(basePath);

    RunBenchmarkSuite(index, populationNo, maxRun, maxItr, CECsDim{index});
end

%% Clean up
rmpath(addedPaths);

% Close the pool only if you want to free resources at the end
if RUN_PARALLEL
    delete(gcp('nocreate'));
end
