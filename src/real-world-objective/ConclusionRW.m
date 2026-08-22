function ConclusionRW(benchmarkResults,maxItr,maxRun,algorithmFileAddress,nFunction, ...
    ~,dim,bestSolutionResults,runEvaluationResults)
%CONCLUSIONRW Save constrained-engineering results and feasibility-aware ranks.

suiteName = 'Real World Problems';
[algorithmNames,~] = Get_algorithm(algorithmFileAddress);
algorithmNames = string(algorithmNames(:));
numAlgs = numel(algorithmNames);
algorithmCapacity = 15;

if numAlgs > algorithmCapacity
    error('ConclusionRW:TemplateAlgorithmCapacity', ...
        'The Real World template supports %d algorithms; %d were supplied.', ...
        algorithmCapacity,numAlgs);
end

ctx = ProjectContext('get');
resultsDir = fullfile(ctx.resultsRoot,suiteName);
algoDir = fullfile(resultsDir,'algorithms');
if exist(resultsDir,'dir') ~= 7, mkdir(resultsDir); end
if exist(algoDir,'dir') ~= 7, mkdir(algoDir); end

fileFormat = 'xlsx';
baseName = dimTagFromInput(dim);

summaryMetricCount = 6;  % Min, Mean, Max, Std, Feasible %, Optimum Hits
rankingMetricCount = 3;  % Min, Mean, Max
summaryValues = nan(summaryMetricCount*nFunction,numAlgs);
feasibleCounts = zeros(nFunction,numAlgs);
validCounts = zeros(nFunction,numAlgs);
meanViolations = inf(nFunction,numAlgs);

for functionIndex = 1:nFunction
    for algorithmIndex = 1:numAlgs
        runs = runEvaluationResults{algorithmIndex,functionIndex};
        if isempty(runs)
            continue;
        end

        rawObjectives = nan(maxRun,1);
        reportObjectives = nan(maxRun,1);
        feasibleMask = false(maxRun,1);
        validMask = false(maxRun,1);
        hitMask = false(maxRun,1);
        violations = inf(maxRun,1);

        for run = 1:min(maxRun,numel(runs))
            e = runs{run};
            if isempty(e), continue; end
            rawObjectives(run) = e.rawObjective;
            reportObjectives(run) = e.reportedObjective;
            feasibleMask(run) = e.isFeasible;
            validMask(run) = e.isValidResult;
            hitMask(run) = e.optimumHit;
            violations(run) = e.weightedViolation;
        end

        validValues = reportObjectives(validMask & isfinite(reportObjectives));
        rowStart = (functionIndex-1)*summaryMetricCount+1;
        if ~isempty(validValues)
            summaryValues(rowStart,algorithmIndex) = min(validValues);
            summaryValues(rowStart+1,algorithmIndex) = mean(validValues);
            summaryValues(rowStart+2,algorithmIndex) = max(validValues);
            if numel(validValues) > 1
                summaryValues(rowStart+3,algorithmIndex) = std(validValues,0);
            else
                summaryValues(rowStart+3,algorithmIndex) = 0;
            end
        end

        feasibleCounts(functionIndex,algorithmIndex) = sum(feasibleMask);
        validCounts(functionIndex,algorithmIndex) = sum(validMask);
        summaryValues(rowStart+4,algorithmIndex) = 100*sum(feasibleMask)/maxRun;
        summaryValues(rowStart+5,algorithmIndex) = sum(hitMask);

        finiteViolations = violations(isfinite(violations));
        if ~isempty(finiteViolations)
            meanViolations(functionIndex,algorithmIndex) = mean(finiteViolations);
        end
    end
end

[bestFunctionCount,overallRank] = calculateRealWorldRanking( ...
    summaryValues,validCounts,meanViolations,nFunction,numAlgs,summaryMetricCount);

bestCountStartRow = 3+nFunction*summaryMetricCount;
overallRankStartRow = bestCountStartRow+rankingMetricCount;

% Clear all algorithm-header slots, then write the active names.
headerCells = repmat({''},1,algorithmCapacity);
for k = 1:numAlgs
    headerCells{k} = char(algorithmNames(k));
end
Saving(headerCells,resultsDir,baseName,fileFormat,'Conclusions','C2');
Saving(summaryValues,resultsDir,baseName,fileFormat,'Conclusions','C3');
Saving(bestFunctionCount,resultsDir,baseName,fileFormat,'Conclusions', ...
    sprintf('C%d',bestCountStartRow));
Saving(overallRank,resultsDir,baseName,fileFormat,'Conclusions', ...
    sprintf('C%d',overallRankStartRow));

solutionTable = buildBestSolutionTable(bestSolutionResults,algorithmNames);
Saving(solutionTable,resultsDir,baseName,fileFormat,'BestSolutions','A3');

% Export median convergence across independent runs. This is a real aggregate
% trajectory and not the pointwise best envelope of unrelated runs.
headers = [{'Iteration'},arrayfun(@(x) sprintf('P%d',x),1:nFunction, ...
    'UniformOutput',false)];
iterationColumn = (1:maxItr)';

for algorithmIndex = 1:numAlgs
    rawData = nan(maxItr,nFunction);
    for functionIndex = 1:nFunction
        dataMatrix = benchmarkResults{algorithmIndex,functionIndex};
        if isempty(dataMatrix), continue; end
        rawData(:,functionIndex) = medianRunCurve(dataMatrix,maxItr,maxRun);
    end

    fullData = [iterationColumn,rawData];
    sheetName = sanitizeSheetName(algorithmNames(algorithmIndex));
    algorithmFile = sprintf('%s_%s',baseName,sheetName);
    Saving(headers,algoDir,algorithmFile,fileFormat,sheetName,'A1');
    Saving(fullData,algoDir,algorithmFile,fileFormat,sheetName,'A2');
end
end

function [bestFunctionCount,overallRank] = calculateRealWorldRanking( ...
    summaryValues,validCounts,meanViolations,nFunction,numAlgs,summaryMetricCount)
rankingMetricCount = 3;
rankCube = nan(nFunction,numAlgs,rankingMetricCount);

for functionIndex = 1:nFunction
    problem = EngineeringProblem(functionIndex);
    tolerance = problem.canonicalTolerance;

    for metricIndex = 1:rankingMetricCount
        row = (functionIndex-1)*summaryMetricCount+metricIndex;
        values = summaryValues(row,:);
        rankCube(functionIndex,:,metricIndex) = rankFeasibilityFirst( ...
            values,validCounts(functionIndex,:),meanViolations(functionIndex,:),tolerance);
    end
end

bestFunctionCount = nan(rankingMetricCount,numAlgs);
overallRank = nan(rankingMetricCount,numAlgs);
for metricIndex = 1:rankingMetricCount
    metricRanks = rankCube(:,:,metricIndex);
    validFunctions = all(isfinite(metricRanks),2);
    if ~any(validFunctions), continue; end
    validRanks = metricRanks(validFunctions,:);
    bestFunctionCount(metricIndex,:) = sum(abs(validRanks-1) <= 1e-12,1);
    averageRank = mean(validRanks,1);
    overallRank(metricIndex,:) = competitionRankTolerance(averageRank,1e-12);
end
end

function ranks = rankFeasibilityFirst(values,validCounts,meanViolations,tolerance)
numAlgs = numel(values);
ranks = nan(1,numAlgs);
validCounts = double(validCounts(:).');

countLevels = unique(validCounts,'sorted');
countLevels = fliplr(countLevels);
baseRank = 1;
for levelIndex = 1:numel(countLevels)
    countLevel = countLevels(levelIndex);
    group = find(validCounts == countLevel);
    if isempty(group), continue; end

    if countLevel > 0
        groupValues = values(group);
        finiteMask = isfinite(groupValues);
        localRanks = nan(size(groupValues));
        if any(finiteMask)
            localRanks(finiteMask) = competitionRankTolerance(groupValues(finiteMask),tolerance);
        end
        if any(~finiteMask)
            worstFinite = max(localRanks(finiteMask));
            if isempty(worstFinite) || ~isfinite(worstFinite), worstFinite = 0; end
            localRanks(~finiteMask) = worstFinite + (1:sum(~finiteMask));
        end
    else
        groupValues = meanViolations(group);
        finiteMask = isfinite(groupValues);
        localRanks = nan(size(groupValues));
        if any(finiteMask)
            localRanks(finiteMask) = competitionRankTolerance(groupValues(finiteMask),1e-12);
            worstFinite = max(localRanks(finiteMask));
            localRanks(~finiteMask) = worstFinite+1;
        else
            % All algorithms in this feasibility group failed numerically.
            % Keep the function in the ranking and tie them at the same worst rank.
            localRanks(:) = 1;
        end
    end

    ranks(group) = baseRank-1+localRanks;
    baseRank = baseRank+numel(group);
end
end

function ranks = competitionRankTolerance(values,tolerance)
values = double(values(:).');
ranks = nan(size(values));
finiteIndices = find(isfinite(values));
if isempty(finiteIndices), return; end

[sortedValues,order] = sort(values(finiteIndices),'ascend');
sortedIndices = finiteIndices(order);
position = 1;
while position <= numel(sortedValues)
    groupStart = position;
    groupEnd = position;
    referenceValue = sortedValues(groupStart);
    while groupEnd < numel(sortedValues)
        candidate = sortedValues(groupEnd+1);
        scale = max([1 abs(referenceValue) abs(candidate)]);
        numericTolerance = max(tolerance,16*eps(scale));
        if abs(candidate-referenceValue) > numericTolerance
            break;
        end
        groupEnd = groupEnd+1;
    end
    ranks(sortedIndices(groupStart:groupEnd)) = groupStart;
    position = groupEnd+1;
end
end

function output = buildBestSolutionTable(bestSolutionResults,algorithmNames)
[algorithmCount,functionCount] = size(bestSolutionResults);
variableCapacity = 11;
fixedColumnCount = 14;
output = cell(algorithmCount*functionCount,fixedColumnCount+variableCapacity);
rowIndex = 0;

for functionIndex = 1:functionCount
    problem = EngineeringProblem(functionIndex);
    for algorithmIndex = 1:algorithmCount
        rowIndex = rowIndex+1;
        output{rowIndex,1} = sprintf('Problem %d',functionIndex);
        output{rowIndex,2} = problem.name;
        output{rowIndex,3} = char(algorithmNames(algorithmIndex));

        record = bestSolutionResults{algorithmIndex,functionIndex};
        if isempty(record) || ~isfield(record,'evaluation') || isempty(record.evaluation)
            continue;
        end

        e = record.evaluation;
        position = e.position(:).';
        output{rowIndex,4} = record.run;
        output{rowIndex,5} = resultStatus(e);
        output{rowIndex,6} = logical(e.isFeasible);
        output{rowIndex,7} = logical(e.optimumHit);
        output{rowIndex,8} = e.rawObjective;
        output{rowIndex,9} = e.reportedObjective;
        output{rowIndex,10} = e.globalOptimum;
        output{rowIndex,11} = e.absoluteError;
        output{rowIndex,12} = e.totalViolation;
        output{rowIndex,13} = e.maxViolation;
        output{rowIndex,14} = numel(position);

        if numel(position) > variableCapacity
            error('ConclusionRW:BestSolutionDimensionExceeded', ...
                'Problem %d returned %d variables; template supports %d.', ...
                functionIndex,numel(position),variableCapacity);
        end
        for variableIndex = 1:numel(position)
            output{rowIndex,fixedColumnCount+variableIndex} = position(variableIndex);
        end
    end
end
end

function status = resultStatus(e)
if e.isValidResult && e.optimumHit
    status = 'Optimum';
elseif e.isValidResult
    status = 'Feasible';
elseif ~e.domainValid
    status = 'Invalid domain';
else
    status = 'Infeasible';
end
end

function curve = medianRunCurve(dataMatrix,maxItr,maxRun)
curve = nan(maxItr,1);
rowCount = min(maxItr,size(dataMatrix,1));
runCount = min(maxRun,size(dataMatrix,2));
for r = 1:rowCount
    values = dataMatrix(r,1:runCount);
    values = values(isfinite(values));
    if ~isempty(values)
        curve(r) = median(values);
    end
end
end

function tag = dimTagFromInput(dimVal)
if isempty(dimVal)
    tag = 'fixDim';
    return;
end
if iscell(dimVal) && ~isempty(dimVal)
    dimVal = dimVal{1};
end
if isnumeric(dimVal)
    if dimVal == 0
        tag = 'fixDim';
    else
        tag = sprintf('%dDim',dimVal);
    end
    return;
end
value = lower(strtrim(string(dimVal)));
if value == "fix" || value == "fixdim"
    tag = 'fixDim';
elseif endsWith(value,"dim")
    tag = char(value);
else
    tag = char(value+"Dim");
end
end

function sheetName = sanitizeSheetName(sheetName)
sheetName = char(string(sheetName));
sheetName = regexprep(sheetName,'[:\\/?*\[\]]','_');
if numel(sheetName) > 31, sheetName = sheetName(1:31); end
if isempty(sheetName), sheetName = 'Sheet1'; end
end
