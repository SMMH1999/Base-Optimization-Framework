%% Initialization
clearvars;
clc;

% Set the base path to the folder where this script is located
basePath = fileparts(which('main.m'));
cd(basePath);

% Ensure algorithms submodule exists and is not stale
algDir = fullfile(basePath, 'optimization algorithms');
ensureAlgorithmsSubmodule(basePath, algDir, 14);        % 14 days threshold

addedPaths = genpath(basePath);
addpath(addedPaths);

%% Statistical analysis configuration
statsConfig = struct();
statsConfig.enabled = true;
statsConfig.alpha = 0.05;
statsConfig.referenceAlgorithm = 1;
statsConfig.performanceDirection = "min";
statsConfig.rankingMetric = "mean";
statsConfig.comparisonAbsoluteTolerance = 1e-14;
statsConfig.comparisonUlpFactor = 16;
statsConfig.applyHolm = true;
statsConfig.exportBoxplots = true;
statsConfig.boxplotFunctions = [];
statisticalConfig('set', statsConfig);

%% Reference algorithm diagnostic configuration
diagConfig = struct();
diagConfig.enabled = false;
diagConfig.cecIndex = 1;
diagConfig.functionIndices = [1 5 8 9 11];
diagConfig.runSelection = "median";
diagConfig.validateReplay = true;
diagConfig.saveReplayData = true;
diagConfig.exportFigures = true;
diagConfig.surfaceGridSize = 60;
diagConfig.maxDisplayedPoints = 2500;
diagConfig.maxCapturedEvaluations = 100000;
referenceDiagnosticConfig('set', diagConfig);

%% Parallel control
global RUN_PARALLEL;

RUN_PARALLEL = false; % <<< set to false to disable parallel mode
% Global switch:
% true  -> enable parallel execution (parfor inside RunBenchmarkSuite)
% false -> run everything serially

%% Parameters
maxRun = 3;          % Number of independent runs for each algorithm
maxItr = 500;         % Maximum number of iterations
populationNo = 30;    % Population size for algorithms

if RUN_PARALLEL
    cluster = parcluster;
    maxAllowedWorkers = cluster.NumWorkers;

    % Best practice: match workers with maxRun if you parallelize the run-loop
    numWorkers = min(maxRun, maxAllowedWorkers);
    if numWorkers > 1 && isempty(gcp('nocreate'))
        parpool("Processes", numWorkers);
    end
end

% Define dimensions for each benchmark set
CECsDim = { ...
    { {'fixDim', []} }, ...                          % CEC2005
    { 10, 30 }, ...                         % CEC2014
    { 10, 30 }, ...                         % CEC2017
    { {'fixDim', []} }, ...                          % CEC2019
    { 10, 20 }, ...                                  % CEC2020
    { 10, 20 } ...                                   % CEC2022
    { {'fixDim', []} }, ...                          % Real World Problem
    };

% Select which benchmark indices to run
selectedIndex = [5:6];

% Initialize results context after benchmark selection is fully defined.
% Only templates required by selectedIndex and CECsDim are copied.
ProjectContext('init',basePath,selectedIndex,CECsDim);

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