function []=Conclusion(benchmarkResults,maxItr,maxRun,algorithmFileAddress,nFunction,cecName,dim)
%CONCLUSION Save benchmark and statistical results into the copied template.

%% Configuration
cecNames=["2005","2014","2017","2019","2020","2022"];
cecLabel=char(cecNames(cecName));
[algorithmNames,~]=Get_algorithm(algorithmFileAddress);
algorithmNames=string(algorithmNames(:));
numAlgs=numel(algorithmNames);

ctx=ProjectContext('get');
resultsDir=fullfile(ctx.resultsRoot,['CEC' cecLabel]);
algoDir=fullfile(resultsDir,'algorithms');

if exist(algoDir,'dir')~=7
    mkdir(algoDir);
end

fileFormat='xlsx';
baseName=dimTagFromInput(dim);
layout=getTemplateLayout(nFunction);
workbookPath=fullfile(resultsDir,[baseName '.' fileFormat]);
shouldSkip=@(cecIndex,functionIndex) cecIndex==3 && functionIndex==2;

if exist(workbookPath,'file')~=2
    error('Conclusion:TemplateNotFound', ...
        'Copied result template was not found:\n%s',workbookPath);
end

if numAlgs>layout.algorithmCapacity
    error('Conclusion:TemplateAlgorithmCapacityExceeded', ...
        'Template capacity is %d algorithms, but %d were requested.', ...
        layout.algorithmCapacity,numAlgs);
end

%% Benchmark reference validation
reference=benchmarkReference(cecName);
if nFunction~=numel(reference.optimumValues)
    error('Conclusion:ReferenceSizeMismatch', ...
        'CEC%s provides %d functions but %d hard-coded optima are configured.', ...
        cecLabel,nFunction,numel(reference.optimumValues));
end

% Raw benchmarkResults remain untouched. Final-run values are canonicalized
% only when they enter reported summaries, rankings, and statistical tests.

%% Save Conclusions values into the existing template
config=statisticalConfig('get');
summaryValues=nan(nFunction*3,numAlgs);
referenceViolation=false(nFunction,1);

for functionIndex=1:nFunction
    if shouldSkip(cecName,functionIndex)
        continue;
    end

    outputRow=(functionIndex-1)*3+1;

    for algorithmIndex=1:numAlgs
        if isempty(benchmarkResults{algorithmIndex,functionIndex})
            continue;
        end

        dataMatrix=benchmarkResults{algorithmIndex,functionIndex};
        if size(dataMatrix,1)<maxItr+1 || size(dataMatrix,2)<maxRun
            continue;
        end

        finalValues=double(dataMatrix(maxItr,1:maxRun));
        finiteFinal=finalValues(isfinite(finalValues));
        if lower(string(config.performanceDirection))=="min" && ~isempty(finiteFinal)
            optimum=reference.optimumValues(functionIndex);
            tolerance=reference.canonicalTolerance(functionIndex);
            referenceViolation(functionIndex)=referenceViolation(functionIndex) || ...
                any(finiteFinal<optimum-tolerance);
        end
        finalValues=FixIfBelowFmin(finalValues,functionIndex,cecName);
        cpuValues=dataMatrix(maxItr+1,1:maxRun);

        reportedMean=mean(finalValues,'omitnan');
        reportedMean=FixIfBelowFmin(reportedMean,functionIndex,cecName);
        summaryValues(outputRow,algorithmIndex)=reportedMean;
        summaryValues(outputRow+1,algorithmIndex)=std(finalValues,0,'omitnan');
        summaryValues(outputRow+2,algorithmIndex)=mean(cpuValues,'omitnan');
    end
end

if any(referenceViolation)
    warning('Conclusion:ReferenceViolation', ...
        ['CEC%s returned values below the hard-coded optimum by more than the configured tolerance for function(s) %s. ' ...
        'Those values were preserved as requested; verify the external benchmark implementation and reference mapping.'], ...
        cecLabel,mat2str(find(referenceViolation)'));
end

[bestFunctionCount,equalBestFunctionCount]=calculateBestFunctionCounts( ...
    benchmarkResults,maxItr,maxRun,nFunction,numAlgs,cecName,config);

fprintf('  Saving formatted results... ');
saveTimer=tic;

% Same storage model as the original framework: write only dynamic ranges
% into the template copy created by ProjectContext.
Saving(cellstr(algorithmNames)',resultsDir,baseName,fileFormat, ...
    'Conclusions',layout.algorithmHeaderCell);
Saving(summaryValues,resultsDir,baseName,fileFormat, ...
    'Conclusions',layout.summaryStartCell);
statisticalAnalysis( ...
    benchmarkResults,maxItr,maxRun,algorithmNames,nFunction, ...
    cecLabel,baseName,resultsDir,fileFormat);

Saving([bestFunctionCount;equalBestFunctionCount],resultsDir,baseName,fileFormat, ...
    'Conclusions',layout.aggregateStartCell);

fprintf('done (%.2f s).\n',toc(saveTimer));

%% Save mean convergence curves to separate algorithm files
for algorithmIndex=1:numAlgs
    rawData=nan(maxItr,nFunction);

    for functionIndex=1:nFunction
        if isempty(benchmarkResults{algorithmIndex,functionIndex}) || ...
                shouldSkip(cecName,functionIndex)
            continue;
        end

        dataMatrix=benchmarkResults{algorithmIndex,functionIndex};
        if size(dataMatrix,1)<maxItr || size(dataMatrix,2)<maxRun
            continue;
        end

        rawData(:,functionIndex)=mean( ...
            dataMatrix(1:maxItr,1:maxRun),2,'omitnan');
    end

    headers=[{'Iteration'},arrayfun( ...
        @(x) sprintf('F%d',x),1:nFunction,'UniformOutput',false)];
    fullData=[(1:maxItr)',rawData];

    sheetName=char(algorithmNames(algorithmIndex));
    algorithmFile=sprintf('%s_%s',baseName,sheetName);

    Saving(headers,algoDir,algorithmFile,fileFormat,sheetName,'A1');
    Saving(fullData,algoDir,algorithmFile,fileFormat,sheetName,'A2');
end
end

function layout=getTemplateLayout(nFunction)
layout.algorithmCapacity=15;
layout.algorithmHeaderCell='D2';
layout.summaryStartCell='D3';
layout.aggregateStartRow=nFunction*3+3;
layout.aggregateStartCell=sprintf('D%d',layout.aggregateStartRow);
end

function [bestFunctionCount,equalBestFunctionCount]=calculateBestFunctionCounts( ...
    benchmarkResults,maxItr,maxRun,nFunction,numAlgs,cecName,config)
performanceMatrix=nan(nFunction,numAlgs);
bestFunctionCount=zeros(1,numAlgs);
equalBestFunctionCount=zeros(1,numAlgs);

for functionIndex=1:nFunction
    if cecName==3 && functionIndex==2
        continue;
    end

    complete=true;

    for algorithmIndex=1:numAlgs
        if isempty(benchmarkResults{algorithmIndex,functionIndex})
            complete=false;
            break;
        end

        dataMatrix=benchmarkResults{algorithmIndex,functionIndex};
        if size(dataMatrix,1)<maxItr || size(dataMatrix,2)<maxRun
            complete=false;
            break;
        end

        values=double(dataMatrix(maxItr,1:maxRun));
        values=FixIfBelowFmin(values,functionIndex,cecName);
        values=values(isfinite(values));

        if isempty(values)
            complete=false;
            break;
        end

        if lower(string(config.rankingMetric))=="median"
            performanceValue=median(values);
        else
            performanceValue=mean(values);
        end

        performanceMatrix(functionIndex,algorithmIndex)=FixIfBelowFmin( ...
            performanceValue,functionIndex,cecName);
    end

    if ~complete || ~all(isfinite(performanceMatrix(functionIndex,:)))
        continue;
    end

    functionRanks=rankCompetitionValues( ...
        performanceMatrix(functionIndex,:),config.performanceDirection);
    bestIndices=find(functionRanks==min(functionRanks,[],'omitnan'));

    if numel(bestIndices)==1
        bestFunctionCount(bestIndices)=bestFunctionCount(bestIndices)+1;
    elseif numel(bestIndices)>1
        equalBestFunctionCount(bestIndices)=equalBestFunctionCount(bestIndices)+1;
    end
end
end

function tag=dimTagFromInput(dimVal)
if isnumeric(dimVal)
    if isequal(dimVal,0)
        tag='fixDim';
    else
        tag=sprintf('%dDim',double(dimVal));
    end
    return;
end

value=lower(strtrim(string(dimVal)));

if value=="fix" || value=="fixdim"
    tag='fixDim';
elseif endsWith(value,"dim")
    tag=char(value);
else
    tag=char(value+"Dim");
end
end
