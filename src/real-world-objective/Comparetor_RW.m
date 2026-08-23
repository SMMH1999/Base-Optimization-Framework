function Comparetor_RW(CEC_Index,populationNo,maxRun,maxItr,CECsDim)
    %COMPARATOR_RW Run the constrained engineering benchmark suite.

    CECNames = 'Real World Problems';
    [~,~,nFunction] = Load_CEC_Function(CEC_Index);
    algorithmFileAddress = '\AlgorithmsName.txt';
    [algorithmsName,algorithms] = Get_algorithm(algorithmFileAddress);
    useParallel = isParallelEnabled(maxRun);

    for dimIdx = 1:numel(CECsDim)
        d = CECsDim{dimIdx};
        if iscell(d)
            dim = d{1};
            DimOverride = d{2};
        else
            dim = d;
            DimOverride = d;
        end

        benchmarkResults = cell(size(algorithms,1),nFunction);
        bestSolutionResults = cell(size(algorithms,1),nFunction);
        runEvaluationResults = cell(size(algorithms,1),nFunction);

        for functionNo = 1:nFunction
            problem = EngineeringProblem(functionNo);
            functionName = problem.name;
            Dim = problem.dimension;
            LB = problem.lowerBound;
            UB = problem.upperBound;

            if ~isempty(DimOverride) && isnumeric(DimOverride) && ...
                    isscalar(DimOverride) && DimOverride ~= Dim
                error('Comparetor_RW:FixedDimensionOverride', ...
                    ['Engineering Problem %d has fixed dimension %d. ' ...
                    'A dimension override of %d is invalid.'], ...
                    functionNo,Dim,DimOverride);
            end

            localCostFunction = @(x) CostFunction(x,functionNo);

            for algorithmNo = 1:size(algorithms,1)
                algorithm = algorithms{algorithmNo};
                algorithmName = algorithmsName(algorithmNo);

                curveMat = nan(maxItr,maxRun);
                bestMerits = nan(maxRun,1);
                bestSearchPositions = nan(maxRun,Dim);

                baseSeed = 1000000*CEC_Index + 10000*Dim + 100*functionNo + algorithmNo;

                if useParallel
                    fprintf('Mode:PARALLEL | RW:%s | P%d:%s | Alg:%s | Runs:%d\n', ...
                        CECNames,functionNo,functionName,string(algorithmName),maxRun);

                    bestMeritsPar = nan(maxRun,1);
                    bestPositionsPar = nan(maxRun,Dim);
                    curvePar = nan(maxItr,maxRun);
                    algFun = algorithm;
                    LBp = LB; UBp = UB; Dp = Dim; popp = populationNo; itrp = maxItr;
                    objp = localCostFunction;

                    parfor run = 1:maxRun
                        rng(baseSeed+run,'twister');
                        [bestMerit,bestPosition,curve] = algFun(LBp,UBp,Dp,popp,itrp,objp);
                        bestMeritsPar(run) = bestMerit;
                        bestPositionsPar(run,:) = bestPosition(:).';
                        curvePar(:,run) = normalizeCurve(curve,itrp,bestMerit);
                    end

                    bestMerits = bestMeritsPar;
                    bestSearchPositions = bestPositionsPar;
                    curveMat = curvePar;
                else
                    for run = 1:maxRun
                        rng(baseSeed+run,'twister');
                        fprintf('Mode:SERIAL | RW:%s | P%d:%s | Alg:%s | Run:%d\n', ...
                            CECNames,functionNo,functionName,string(algorithmName),run);

                        [bestMerits(run),bestPosition,curve] = algorithm( ...
                            LB,UB,Dim,populationNo,maxItr,localCostFunction);
                        bestSearchPositions(run,:) = bestPosition(:).';
                        curveMat(:,run) = normalizeCurve(curve,maxItr,bestMerits(run));
                    end
                end

                runEvaluations = cell(maxRun,1);
                for run = 1:maxRun
                    evaluation = EngineeringEvaluate(bestSearchPositions(run,:),functionNo);
                    runEvaluations{run} = evaluation;

                    % Make the final convergence point match the reportable final
                    % objective whenever the run is valid. Invalid runs retain the
                    % optimizer merit and therefore cannot masquerade as good values.
                    if evaluation.isValidResult
                        curveMat(maxItr,run) = evaluation.reportedObjective;
                    else
                        curveMat(maxItr,run) = evaluation.merit;
                    end
                end

                [curveMin,curveMean,curveMax,curveStd] = summarizeRunMatrix(curveMat);
                algorithmResults = [curveMat,curveMin,curveMean,curveMax,curveStd];

                [bestEvaluation,bestRunIndex] = selectBestRun(runEvaluations);
                bestSolutionResults{algorithmNo,functionNo} = struct( ...
                    'run',bestRunIndex, ...
                    'evaluation',bestEvaluation);
                runEvaluationResults{algorithmNo,functionNo} = runEvaluations;
                benchmarkResults{algorithmNo,functionNo} = algorithmResults;
            end
        end

        ConclusionRW(benchmarkResults,maxItr,maxRun,algorithmFileAddress,nFunction, ...
            CEC_Index,dim,bestSolutionResults,runEvaluationResults);
        PlotingRW(benchmarkResults,maxItr,maxRun,algorithmFileAddress,dim);
    end
end

function curveOut = normalizeCurve(curve,maxItr,fallbackValue)
    curveOut = nan(maxItr,1);
    curve = double(curve(:));
    L = min(numel(curve),maxItr);
    if L > 0
        curveOut(1:L) = curve(1:L);
    end

    % Preserve iteration positions. Never remove NaN/Inf entries because doing so
    % would shift later values to earlier iterations. Only extend a short curve
    % with its last finite value.
    if L < maxItr
        finiteIndex = find(isfinite(curveOut(1:max(L,1))),1,'last');
        if ~isempty(finiteIndex)
            curveOut(L+1:maxItr) = curveOut(finiteIndex);
        elseif isfinite(fallbackValue)
            curveOut(L+1:maxItr) = fallbackValue;
        end
    elseif L == 0 && isfinite(fallbackValue)
        curveOut(:) = fallbackValue;
    end
end

function [rowMin,rowMean,rowMax,rowStd] = summarizeRunMatrix(values)
    rowCount = size(values,1);
    rowMin = nan(rowCount,1);
    rowMean = nan(rowCount,1);
    rowMax = nan(rowCount,1);
    rowStd = nan(rowCount,1);
    for r = 1:rowCount
        v = values(r,:);
        v = v(isfinite(v));
        if isempty(v)
            continue;
        end
        rowMin(r) = min(v);
        rowMean(r) = mean(v);
        rowMax(r) = max(v);
        if numel(v) > 1
            rowStd(r) = std(v,0);
        else
            rowStd(r) = 0;
        end
    end
end

function [bestEvaluation,bestRunIndex] = selectBestRun(runEvaluations)
    runCount = numel(runEvaluations);
    valid = false(runCount,1);
    objective = inf(runCount,1);
    violation = inf(runCount,1);

    for k = 1:runCount
        e = runEvaluations{k};
        if isempty(e)
            continue;
        end
        valid(k) = e.isValidResult;
        if e.isValidResult && isfinite(e.rawObjective)
            objective(k) = e.rawObjective;
        end
        if isfinite(e.weightedViolation)
            violation(k) = e.weightedViolation;
        end
    end

    if any(valid)
        candidates = find(valid);
        [~,localIndex] = min(objective(candidates));
        bestRunIndex = candidates(localIndex);
    else
        [~,bestRunIndex] = min(violation);
        if isempty(bestRunIndex) || ~isfinite(violation(bestRunIndex))
            bestRunIndex = 1;
        end
    end

    bestEvaluation = runEvaluations{bestRunIndex};
end

function tf = isParallelEnabled(maxRunLocal)
    global RUN_PARALLEL;
    pool = gcp('nocreate');
    tf = ~isempty(RUN_PARALLEL) && RUN_PARALLEL && ~isempty(pool) && ...
        pool.NumWorkers > 1 && maxRunLocal > 1;
end
