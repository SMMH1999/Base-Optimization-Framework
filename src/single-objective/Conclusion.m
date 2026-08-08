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

%% Correct final values below benchmark minima
benchmarkResultsFixed=benchmarkResults;

for algorithmIndex=1:numAlgs
    for functionIndex=1:nFunction
        if isempty(benchmarkResults{algorithmIndex,functionIndex}) || ...
                shouldSkip(cecName,functionIndex)
            continue;
        end

        dataMatrix=benchmarkResults{algorithmIndex,functionIndex};

        if size(dataMatrix,1)>=maxItr && size(dataMatrix,2)>=maxRun
            for runIndex=1:maxRun
                dataMatrix(maxItr,runIndex)=FixIfBelowFmin( ...
                    dataMatrix(maxItr,runIndex),functionIndex,cecName);
            end
        end

        benchmarkResultsFixed{algorithmIndex,functionIndex}=dataMatrix;
    end
end

%% Save Conclusions values into the existing template
summaryValues=nan(nFunction*3,numAlgs);

for functionIndex=1:nFunction
    if shouldSkip(cecName,functionIndex)
        continue;
    end

    outputRow=(functionIndex-1)*3+1;

    for algorithmIndex=1:numAlgs
        if isempty(benchmarkResultsFixed{algorithmIndex,functionIndex})
            continue;
        end

        dataMatrix=benchmarkResultsFixed{algorithmIndex,functionIndex};
        if size(dataMatrix,1)<maxItr+1 || size(dataMatrix,2)<maxRun
            continue;
        end

        finalValues=dataMatrix(maxItr,1:maxRun);
        cpuValues=dataMatrix(maxItr+1,1:maxRun);

        summaryValues(outputRow,algorithmIndex)=mean(finalValues,'omitnan');
        summaryValues(outputRow+1,algorithmIndex)=std(finalValues,0,'omitnan');
        summaryValues(outputRow+2,algorithmIndex)=mean(cpuValues,'omitnan');
    end
end

config=statisticalConfig('get');
[bestFunctionCount,overallRank]=calculateAggregateRanking( ...
    benchmarkResultsFixed,maxItr,maxRun,nFunction,numAlgs,cecName,config);

fprintf('  Saving formatted results... ');
saveTimer=tic;

% Same storage model as the original framework: write only dynamic ranges
% into the template copy created by ProjectContext.
Saving(cellstr(algorithmNames)',resultsDir,baseName,fileFormat, ...
    'Conclusions',layout.algorithmHeaderCell);
Saving(summaryValues,resultsDir,baseName,fileFormat, ...
    'Conclusions',layout.summaryStartCell);
Saving([bestFunctionCount;overallRank],resultsDir,baseName,fileFormat, ...
    'Conclusions',layout.aggregateStartCell);

if config.enabled
    statisticalAnalysis( ...
        benchmarkResultsFixed,maxItr,maxRun,algorithmNames,nFunction, ...
        cecLabel,baseName,resultsDir,fileFormat);
end

fprintf('done (%.2f s).\n',toc(saveTimer));

%% Save mean convergence curves to separate algorithm files
for algorithmIndex=1:numAlgs
    rawData=nan(maxItr,nFunction);

    for functionIndex=1:nFunction
        if isempty(benchmarkResultsFixed{algorithmIndex,functionIndex}) || ...
                shouldSkip(cecName,functionIndex)
            continue;
        end

        dataMatrix=benchmarkResultsFixed{algorithmIndex,functionIndex};
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

function [bestFunctionCount,overallRank]=calculateAggregateRanking( ...
    benchmarkResults,maxItr,maxRun,nFunction,numAlgs,cecName,config)
performanceMatrix=nan(nFunction,numAlgs);
rankMatrix=nan(nFunction,numAlgs);
validFunction=false(nFunction,1);

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

        values=dataMatrix(maxItr,1:maxRun);
        values=values(isfinite(values));

        if isempty(values)
            complete=false;
            break;
        end

        if lower(string(config.rankingMetric))=="median"
            performanceMatrix(functionIndex,algorithmIndex)=median(values);
        else
            performanceMatrix(functionIndex,algorithmIndex)=mean(values);
        end
    end

    if ~complete || ~all(isfinite(performanceMatrix(functionIndex,:)))
        continue;
    end

    validFunction(functionIndex)=true;

    if lower(string(config.performanceDirection))=="max"
        rankMatrix(functionIndex,:)=tiedrank(-performanceMatrix(functionIndex,:));
    else
        rankMatrix(functionIndex,:)=tiedrank(performanceMatrix(functionIndex,:));
    end
end

bestFunctionCount=sum(rankMatrix==1,1);

if any(validFunction)
    averageRank=mean(rankMatrix(validFunction,:),1,'omitnan');
    overallRank=tiedrank(averageRank);
else
    overallRank=nan(1,numAlgs);
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
