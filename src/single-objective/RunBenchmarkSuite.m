function RunBenchmarkSuite(CEC_Index, populationNo, maxRun, maxItr, CECsDim)
    %% Benchmark Function
    CECNames = ["2005","2014","2017","2019","2020","2022"];
    [costFunction, costFunctionDetails, nFunction] = Load_CEC_Function(CEC_Index);

    %% Load algorithms list
    algorithmFileAddress = '\AlgorithmsName.txt';
    [algorithmsName, algorithms] = Get_algorithm(algorithmFileAddress);

    % Pre-detect benchmark families
    isCEC2017 = strcmp(func2str(costFunctionDetails), 'CEC_2017_Function');
    isCEC2005 = strcmp(func2str(costFunctionDetails), 'CEC_2005_Function');

    % Decide parallel execution mode
    useParallel = isParallelEnabled(maxRun);

    %% Loop over dimensions
    for dimIdx = 1:numel(CECsDim)

        Dim = resolveDim(CECsDim, dimIdx);
        benchmarkResults = cell(size(algorithms, 1), nFunction);

        % ---- NEW (simple FE logs) ----
        benchmarkFEs       = cell(size(algorithms, 1), nFunction); % each cell: [maxRun x 1]
        benchmarkFEWarnItr = cell(size(algorithms, 1), nFunction); % each cell: [maxRun x 1]
        % --------------------------------

        %% Loop over functions
        for functionNo = 1:nFunction

            if isCEC2017 && functionNo == 2
                continue;
            end

            % Get bounds (CEC2005 may return function handle per function)
            if isCEC2005
                [LB, UB, ~, localCostFunction] = costFunctionDetails(functionNo);
            else
                [LB, UB, ~] = costFunctionDetails(functionNo);
                localCostFunction = costFunction;
            end

            %% Loop over algorithms
            for algorithmNo = 1:size(algorithms, 1)

                algorithm     = algorithms{algorithmNo};
                algorithmName = algorithmsName(algorithmNo);

                % Preallocate result containers
                algorithmResults = -ones(maxItr + 1, maxRun);
                bestResults      = zeros(maxRun, 1);
                timeExecute      = zeros(maxRun, 1);

                % FE logs per run (small)
                feCount   = zeros(maxRun, 1);
                feWarnItr = NaN(maxRun, 1);

                if useParallel
                    fprintf('CEC:%s | Dim:%d | F%d | Alg:%s | Runs:%d | Mode:PARALLEL\n', ...
                        CECNames(CEC_Index), Dim, functionNo, string(algorithmName), maxRun);
                end

                %% Runs
                if useParallel
                    baseSeed = 1000000 * CEC_Index + 10000 * Dim + 100 * functionNo + algorithmNo;

                    curveMat    = zeros(maxItr, maxRun);
                    bestResults = zeros(maxRun, 1);
                    timeExecute = zeros(maxRun, 1);

                    algFun = algorithm;  % local copy (parfor-friendly)

                    parfor run = 1:maxRun
                        rng(baseSeed + run, "twister");
                        tStart = tic;

                        maxFEs = populationNo * maxItr;
                        counter = EvalCounter(maxFEs);
                        objectiveRun = BuildObjective(localCostFunction, functionNo, isCEC2005, Dim, counter, populationNo);

                        [best, ~, curve] = algFun(LB, UB, Dim, populationNo, maxItr, objectiveRun);

                        timeExecute(run) = toc(tStart);
                        bestResults(run) = best;

                        curve = curve(:);
                        if numel(curve) ~= maxItr
                            error("Algorithm returned a curve with length %d, expected %d.", numel(curve), maxItr);
                        end
                        curveMat(:, run) = curve;

                        feCount(run)   = counter.count;
                        feWarnItr(run) = counter.warnItr;
                    end


                    algorithmResults(1:maxItr, :) = curveMat;

                else
                    for run = 1:maxRun
                        fprintf('CEC:%s | Dim:%d | F%d | Alg:%s | Run:%d | Mode:SERIAL\n', ...
                            CECNames(CEC_Index), Dim, functionNo, string(algorithmName), run);

                        tStart = tic;

                        % maxFEs = populationNo * maxItr; % warning only
                        maxFEs = 1000000;

                        counter = EvalCounter(maxFEs);

                        objectiveRun = BuildObjective(localCostFunction, functionNo, isCEC2005, Dim, counter, populationNo);

                        [bestResults(run), ~, algorithmResults(1:maxItr, run)] = ...
                            algorithm(LB, UB, Dim, populationNo, maxItr, objectiveRun);

                        timeExecute(run) = toc(tStart);

                        tmpCurve = algorithmResults(1:maxItr, run);
                        algorithmResults(1:maxItr, run) = tmpCurve(:);

                        feCount(run)   = counter.count;
                        feWarnItr(run) = counter.warnItr;
                    end
                end

                % Keep compatibility with your previous storage convention
                algorithmResults(maxItr, :)   = bestResults;
                algorithmResults(maxItr+1, :) = timeExecute;

                [~, algorithmResults(:, maxRun + 1), ~, algorithmResults(:, maxRun + 2)] = ...
                    Results_Toolkit(algorithmResults);

                benchmarkResults{algorithmNo, functionNo} = algorithmResults;

                benchmarkFEs{algorithmNo, functionNo}       = feCount;
                benchmarkFEWarnItr{algorithmNo, functionNo} = feWarnItr;
            end
        end

        %% Output stage
        Conclusion(benchmarkResults, maxItr, maxRun, algorithmFileAddress, nFunction, CEC_Index, Dim);
        Ploting(benchmarkResults, maxItr, maxRun, algorithmFileAddress, CEC_Index, Dim);

        feLogName = sprintf('FELog_CEC%s_Dim%d.mat', CECNames(CEC_Index), Dim);
        save(feLogName, 'benchmarkFEs', 'benchmarkFEWarnItr', 'populationNo', 'maxItr', 'maxRun', 'CEC_Index', 'Dim');
    end
end


%% ===== Local functions (NOT nested) => OK for parfor =====

function tf = isParallelEnabled(maxRunLocal)
    global RUN_PARALLEL;
    pool = gcp('nocreate');
    tf = ~isempty(RUN_PARALLEL) && RUN_PARALLEL && ~isempty(pool) && pool.NumWorkers > 1 && maxRunLocal > 1;
end

function DimOut = resolveDim(CECsDimIn, idx)
    if iscell(CECsDimIn)
        DimOut = CECsDimIn{idx};
    else
        DimOut = CECsDimIn(idx);
    end
    DimOut = double(DimOut);
end

function y = WrapObjective(innerFun, counter, popNo)
    y = innerFun();

    counter.count = counter.count + 1;

    if ~counter.warned && counter.count > counter.maxFEs
        counter.warned  = true;
        counter.warnItr = ceil(counter.count / max(popNo,1));
        warning('CEC:FEsExceeded', ...
            'FEs exceeded: %d > %d (estimated itr: %d)', ...
            counter.count, counter.maxFEs, counter.warnItr);
    end
end

function obj = BuildObjective(costFun, functionNo, isCEC2005_local, Dim_local, counter, popNo)
    if isCEC2005_local
        obj = @(x) WrapObjective(@() costFun(x), counter, popNo);
    else
        obj = @(x) WrapObjective(@() costFun(normalizeToDxN(x, Dim_local), functionNo), counter, popNo);
    end
end

function X = normalizeToDxN(x, Dim_local)
    if isvector(x)
        if numel(x) ~= Dim_local
            error('normalizeToDxN:VectorSizeMismatch', ...
                'Vector length (%d) does not match Dim (%d).', numel(x), Dim_local);
        end
        X = reshape(x, Dim_local, 1);
        return;
    end

    [r, c] = size(x);

    if r == Dim_local
        X = x;
        return;
    end

    if c == Dim_local
        X = x.';
        return;
    end

    error('normalizeToDxN:MatrixSizeMismatch', ...
        'Input size %dx%d is incompatible with Dim=%d (expected DxN or NxD).', r, c, Dim_local);
end
