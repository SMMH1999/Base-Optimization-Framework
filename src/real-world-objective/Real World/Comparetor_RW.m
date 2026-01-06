function Comparetor_RW(CEC_Index, populationNo, maxRun, maxItr, CECsDim)

    %% Benchmark Function  (BASE: RunBenchmarkSuite style)
    CECNames = "Real World Problems";
    [~, costFunctionDetails, nFunction] = Load_CEC_Function(CEC_Index); %#ok<ASGLU>

    %% Load algorithms list  (BASE)
    algorithmFileAddress = '\AlgorithmsName.txt';
    [algorithmsName, algorithms] = Get_algorithm(algorithmFileAddress);

    %% Decide parallel execution mode (MATCH RunBenchmarkSuite idea)
    useParallel = isParallelEnabled(maxRun);

    %% Loop over dimensions  (BASE)
    for dimIdx = 1:numel(CECsDim)

        d = CECsDim{dimIdx};
        if iscell(d)
            dim = d{1};           % tag for output
            DimOverride = d{2};   % numeric or []
        else
            dim = d;
            DimOverride = d;
        end

        benchmarkResults = cell(size(algorithms, 1), nFunction);

        %% Loop over functions  (BASE)
        for functionNo = 1:nFunction

            functionName = ['Problem ' num2str(functionNo)];

            % ===== RW OVERRIDE: bounds + objective =====
            [Dim, LB, UB, VioFactor, ~, Obj] = ProbInfo(functionNo);

            if ~isempty(DimOverride)
                Dim = DimOverride;
            end

            LB = LB .* ones(1, Dim);
            UB = UB .* ones(1, Dim);

            localCostFunction = @(x) CostFunction(x, VioFactor, Obj);
            % ==========================================

            %% Loop over algorithms  (BASE)
            for algorithmNo = 1:size(algorithms, 1)

                algorithm     = algorithms{algorithmNo};
                algorithmName = algorithmsName(algorithmNo);

                % Preallocate result containers (RW schema)
                algorithmResults = -ones(maxItr + 1, maxRun);
                bestResults      = zeros(maxRun, 1);
                bestSolutions    = zeros(maxRun, Dim);

                if useParallel
                    fprintf('Mode:PARALLEL | RW:%s | Dim:%d | %s | Alg:%s | Runs:%d\n', ...
                        CECNames, Dim, functionName, string(algorithmName), maxRun);
                end

                %% Runs
                if useParallel
                    % ---- deterministic base seed (like your other core) ----
                    baseSeed = 1000000 * CEC_Index + 10000 * Dim + 100 * functionNo + algorithmNo;

                    curveMat      = -ones(maxItr, maxRun);   % keep same fill semantics
                    bestResultsPar = zeros(maxRun, 1);
                    bestPosPar     = zeros(maxRun, Dim);

                    algFun = algorithm;    % parfor-friendly local copy
                    LBp = LB; UBp = UB; Dp = Dim; popp = populationNo; itrp = maxItr;
                    objp = localCostFunction;

                    parfor run = 1:maxRun
                        rng(baseSeed + run, "twister");

                        [b, p, curve] = algFun(LBp, UBp, Dp, popp, itrp, objp);

                        bestResultsPar(run) = b;
                        bestPosPar(run, :)  = p;

                        % --- make fixed-length vector for parfor slicing ---
                        tmp = -ones(itrp, 1);

                        curve = curve(:);
                        L = min(numel(curve), itrp);

                        if L > 0
                            tmp(1:L) = curve(1:L);
                            if L < itrp
                                tmp(L+1:itrp) = curve(L);   % pad with last value
                            end
                        end

                        % only fixed slicing allowed in parfor:
                        curveMat(:, run) = tmp;
                    end


                    bestResults   = bestResultsPar;
                    bestSolutions = bestPosPar;
                    algorithmResults(1:maxItr, :) = curveMat;

                else
                    for run = 1:maxRun
                        fprintf('Mode:SERIAL | RW:%s | Dim:%d | %s | Alg:%s | Run:%d\n', ...
                            CECNames, Dim, functionName, string(algorithmName), run);

                        [bestResults(run), bestSolutions(run, :), curve] = algorithm( ...
                            LB, UB, Dim, populationNo, maxItr, localCostFunction);

                        curve = curve(:);
                        L = min(numel(curve), maxItr);
                        if L > 0
                            algorithmResults(1:L, run) = curve(1:L);
                            if L < maxItr
                                algorithmResults(L+1:maxItr, run) = curve(L);
                            end
                        end
                    end
                end

                % ===== RW OVERRIDE: storage + stats (keep your RW schema) =====
                algorithmResults(maxItr, :) = bestResults;

                [algorithmResults(:, maxRun + 1), ...
                    algorithmResults(:, maxRun + 2), ...
                    algorithmResults(:, maxRun + 3), ...
                    algorithmResults(:, maxRun + 4)] = Results_Toolkit(algorithmResults);

                % RW schema: last row holds a solution vector
                algorithmResults(maxItr + 1, 1:Dim) = bestSolutions(maxRun, :);
                % ============================================================

                benchmarkResults{algorithmNo, functionNo} = algorithmResults;

                clear algorithmResults bestResults bestSolutions
            end
        end

        %% RW conclusion
        ConclusionRW(benchmarkResults, maxItr, maxRun, algorithmFileAddress, nFunction, CEC_Index, dim);
        % PlotingRW(benchmarkResults, maxItr, maxRun, algorithmFileAddress, CEC_Index, dim);

    end
end

%% ===== Local helper (NOT nested inside loops) =====
function tf = isParallelEnabled(maxRunLocal)
    global RUN_PARALLEL;
    pool = gcp('nocreate');
    tf = ~isempty(RUN_PARALLEL) && RUN_PARALLEL && ~isempty(pool) && pool.NumWorkers > 1 && maxRunLocal > 1;
end
