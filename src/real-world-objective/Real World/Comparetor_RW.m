function Comparetor_RW(CEC_Index, populationNo, maxRun, maxItr, CECsDim)

    %% Benchmark Function  (BASE: RunBenchmarkSuite style)
    CECNames = "Real World Problems";
    [~, costFunctionDetails, nFunction] = Load_CEC_Function(CEC_Index);

    %% Load algorithms list  (BASE)
    % اگر RW لیست جدا دارد فقط همین یک خط را عوض کن
    % algorithmFileAddress = '\RWP\RW_AlgorithmsName.txt';
    algorithmFileAddress = '\AlgorithmsName.txt';
    [algorithmsName, algorithms] = Get_algorithm(algorithmFileAddress);

    %% Loop over dimensions  (BASE)
    for dimIdx = 1:numel(CECsDim)

        d = CECsDim{dimIdx};          % force cell
        if iscell(d)
            dim = d{1};               % tag for output (e.g., 'fixDim')
            DimOverride = d{2};       % numeric or []
        else
            dim = d;                  % numeric dim
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

                % Preallocate result containers (BASE-ish but RW schema)
                algorithmResults = -ones(maxItr + 1, maxRun);
                bestResults      = zeros(maxRun, 1);
                bestSolutions    = zeros(maxRun, Dim);

                %% Runs (SERIAL)  (BASE)
                for run = 1:maxRun
                    fprintf('Mode:SERIAL | RW:%s | Dim:%d | %s | Alg:%s | Run:%d\n', ...
                        CECNames, Dim, functionName, string(algorithmName), run);

                    % ===== RW OVERRIDE: algorithm call signature =====
                    [bestResults(run), bestSolutions(run, :), curve] = algorithm( ...
                        LB, UB, Dim, populationNo, maxItr, localCostFunction);
                    % =================================================

                    % normalize curve into column (robust)
                    curve = curve(:);
                    L = min(numel(curve), maxItr);
                    if L > 0
                        algorithmResults(1:L, run) = curve(1:L);
                        if L < maxItr
                            algorithmResults(L+1:maxItr, run) = curve(L);
                        end
                    end
                end

                % ===== RW OVERRIDE: storage + stats =====
                algorithmResults(maxItr, :) = bestResults;

                % keep exactly RW toolkit outputs (min/mean/max/std)
                [algorithmResults(:, maxRun + 1), ...
                 algorithmResults(:, maxRun + 2), ...
                 algorithmResults(:, maxRun + 3), ...
                 algorithmResults(:, maxRun + 4)] = Results_Toolkit(algorithmResults);

                % RW schema: last row holds a solution vector
                algorithmResults(maxItr + 1, 1:Dim) = bestSolutions(maxRun, :);
                % =======================================

                benchmarkResults{algorithmNo, functionNo} = algorithmResults;

                clear algorithmResults bestResults bestSolutions curve
            end
        end

        % RW conclusion (override vs Conclusion/Ploting)
        ConclusionRW(benchmarkResults, maxItr, maxRun, algorithmFileAddress, nFunction, CEC_Index, dim);
        % اگر PlotingRW داری:
        % PlotingRW(benchmarkResults, maxItr, maxRun, algorithmFileAddress, CEC_Index, dim);

    end
end
