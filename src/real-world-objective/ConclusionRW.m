function []=ConclusionRW(benchmarkResults,maxItr,maxRun,algorithmFileAddress,nFunction,cecName,dim,bestSolutionResults)
%CONCLUSIONRW Save Real-World benchmark outputs, rankings, and decision vectors.

suiteName="Real World Problems";
[algorithmNames,~]=Get_algorithm(algorithmFileAddress);
algorithmNames=string(algorithmNames(:));
numAlgs=numel(algorithmNames);

ctx=ProjectContext('get');
resultsDir=fullfile(ctx.resultsRoot,char(suiteName));
algoDir=fullfile(resultsDir,'algorithms');

if exist(resultsDir,'dir')~=7
    mkdir(resultsDir);
end
if exist(algoDir,'dir')~=7
    mkdir(algoDir);
end

fileFormat='xlsx';
baseName=dimTagFromInput(dim);
workbookPath=fullfile(resultsDir,[baseName '.' fileFormat]);
shouldSkip=@(cecNameVal,functionIndex) cecNameVal==3 && functionIndex==2;

%% Save Conclusions numeric values and automatic ranking
summaryMetricCount=4;   % Min, Mean, Max, Std
rankingMetricCount=3;   % Min, Mean, Max only
summaryValues=nan(summaryMetricCount*nFunction,numAlgs);

for algorithmIndex=1:numAlgs
    for functionIndex=1:nFunction
        if isempty(benchmarkResults{algorithmIndex,functionIndex}) || ...
                shouldSkip(cecName,functionIndex)
            continue;
        end

        dataMatrix=benchmarkResults{algorithmIndex,functionIndex};
        minColumn=maxRun+1;
        meanColumn=maxRun+2;
        maxColumn=maxRun+3;
        stdColumn=maxRun+4;
        finalRow=min(size(dataMatrix,1),maxItr);
        rowStart=(functionIndex-1)*summaryMetricCount+1;

        if size(dataMatrix,2)>=minColumn
            summaryValues(rowStart,algorithmIndex)=dataMatrix(finalRow,minColumn);
        end
        if size(dataMatrix,2)>=meanColumn
            summaryValues(rowStart+1,algorithmIndex)=dataMatrix(finalRow,meanColumn);
        end
        if size(dataMatrix,2)>=maxColumn
            summaryValues(rowStart+2,algorithmIndex)=dataMatrix(finalRow,maxColumn);
        end
        if size(dataMatrix,2)>=stdColumn
            summaryValues(rowStart+3,algorithmIndex)=dataMatrix(finalRow,stdColumn);
        end
    end
end

globalOptima=readGlobalOptima(workbookPath,nFunction,summaryMetricCount);
[bestFunctionCount,overallRank]=calculateRealWorldRanking( ...
    summaryValues,globalOptima,nFunction,numAlgs, ...
    summaryMetricCount,rankingMetricCount);

bestCountStartRow=3+nFunction*summaryMetricCount;
overallRankStartRow=bestCountStartRow+rankingMetricCount;

algorithmHeaders=cellstr(algorithmNames).';
Saving(algorithmHeaders,resultsDir,baseName,fileFormat,'Conclusions','C2');
Saving(summaryValues,resultsDir,baseName,fileFormat,'Conclusions','C3');
Saving(bestFunctionCount,resultsDir,baseName,fileFormat,'Conclusions', ...
    sprintf('C%d',bestCountStartRow));
Saving(overallRank,resultsDir,baseName,fileFormat,'Conclusions', ...
    sprintf('C%d',overallRankStartRow));

%% Save dynamic BestSolutions rows
solutionTable=buildBestSolutionTable(bestSolutionResults,algorithmNames);
Saving(solutionTable,resultsDir,baseName,fileFormat,'BestSolutions','A3');

%% Save raw iteration curves per algorithm
headers=[{'Iteration'},arrayfun(@(x) sprintf('P%d',x),1:nFunction, ...
    'UniformOutput',false)];
iterationColumn=(1:maxItr)';

for algorithmIndex=1:numAlgs
    rawData=nan(maxItr,nFunction);

    for functionIndex=1:nFunction
        if isempty(benchmarkResults{algorithmIndex,functionIndex}) || ...
                shouldSkip(cecName,functionIndex)
            continue;
        end

        dataMatrix=benchmarkResults{algorithmIndex,functionIndex};
        bestColumn=maxRun+1;
        rowCount=min(maxItr,size(dataMatrix,1));

        if size(dataMatrix,2)>=bestColumn
            rawData(1:rowCount,functionIndex)=dataMatrix(1:rowCount,bestColumn);
        end
    end

    fullData=[iterationColumn,rawData];
    sheetName=sanitizeSheetName(algorithmNames(algorithmIndex));
    algorithmFile=sprintf('%s_%s',baseName,sheetName);

    Saving(headers,algoDir,algorithmFile,fileFormat,sheetName,'A1');
    Saving(fullData,algoDir,algorithmFile,fileFormat,sheetName,'A2');
end
end

function [bestFunctionCount,overallRank]=calculateRealWorldRanking(summaryValues,globalOptima,nFunction,numAlgs,summaryMetricCount,rankingMetricCount)
%CALCULATEREALWORLDRANKING Rank Min/Mean/Max by distance to global optimum.
rankCube=nan(nFunction,numAlgs,rankingMetricCount);

for functionIndex=1:nFunction
    for metricIndex=1:rankingMetricCount
        row=(functionIndex-1)*summaryMetricCount+metricIndex;
        values=summaryValues(row,:);

        if ~all(isfinite(values))
            continue;
        end

        score=abs(values-globalOptima(functionIndex));
        rankCube(functionIndex,:,metricIndex)=rankEqAscending(score);
    end
end

bestFunctionCount=nan(rankingMetricCount,numAlgs);
overallRank=nan(rankingMetricCount,numAlgs);

for metricIndex=1:rankingMetricCount
    metricRanks=rankCube(:,:,metricIndex);
    validFunction=all(isfinite(metricRanks),2);

    if ~any(validFunction)
        continue;
    end

    validRanks=metricRanks(validFunction,:);
    bestFunctionCount(metricIndex,:)=sum(validRanks==1,1);
    averageRank=mean(validRanks,1,'omitnan');
    overallRank(metricIndex,:)=rankEqAscending(averageRank);
end
end

function ranks=rankEqAscending(values)
%RANKEQASCENDING Competition ranking equivalent to RANK.EQ ascending.
ranks=nan(size(values));
finiteMask=isfinite(values);
finiteValues=values(finiteMask);
finiteIndices=find(finiteMask);

for indexPosition=1:numel(finiteIndices)
    valueIndex=finiteIndices(indexPosition);
    ranks(valueIndex)=1+sum(finiteValues<values(valueIndex));
end
end

function globalOptima=readGlobalOptima(workbookPath,nFunction,summaryMetricCount)
%READGLOBALOPTIMA Read one fixed Global Optimum per problem from the template.
dataStartRow=3;
lastRow=dataStartRow+nFunction*summaryMetricCount-1;
range=sprintf('R%d:R%d',dataStartRow,lastRow);
rawValues=readmatrix(workbookPath,'Sheet','Conclusions','Range',range);
globalOptima=rawValues(1:summaryMetricCount:end);
globalOptima=globalOptima(:);

if numel(globalOptima)~=nFunction || any(~isfinite(globalOptima))
    error('ConclusionRW:InvalidGlobalOptimum', ...
        'Conclusions must contain one finite Global Optimum for each problem.');
end
end

function output=buildBestSolutionTable(bestSolutionResults,algorithmNames)
%BUILDBESTSOLUTIONTABLE Build dynamic Problem/Algorithm rows and result values.
[algorithmCount,functionCount]=size(bestSolutionResults);
variableCapacity=11;
output=cell(algorithmCount*functionCount,5+variableCapacity);
rowIndex=0;

for functionIndex=1:functionCount
    for algorithmIndex=1:algorithmCount
        rowIndex=rowIndex+1;
        output{rowIndex,1}=sprintf('Problem %d',functionIndex);
        output{rowIndex,2}=char(algorithmNames(algorithmIndex));

        if isempty(bestSolutionResults{algorithmIndex,functionIndex})
            continue;
        end

        result=bestSolutionResults{algorithmIndex,functionIndex};
        position=result.position(:).';
        positionCount=numel(position);

        if positionCount>variableCapacity
            error('ConclusionRW:BestSolutionDimensionExceeded', ...
                ['BestSolutions template supports %d decision-variable columns, ' ...
                 'but Problem %d / algorithm %s returned %d.'], ...
                variableCapacity,functionIndex,char(algorithmNames(algorithmIndex)), ...
                positionCount);
        end

        output{rowIndex,3}=result.fitness;
        output{rowIndex,4}=result.run;
        output{rowIndex,5}=positionCount;

        for variableIndex=1:positionCount
            output{rowIndex,5+variableIndex}=position(variableIndex);
        end
    end
end
end

function tag=dimTagFromInput(dimVal)
if isempty(dimVal)
    tag='fixDim';
    return;
end

if iscell(dimVal) && ~isempty(dimVal)
    try
        firstValue=string(dimVal{1});
        if lower(strtrim(firstValue))=="fixdim" || lower(strtrim(firstValue))=="fix"
            tag='fixDim';
            return;
        end
    catch
    end
end

if isnumeric(dimVal)
    if dimVal==0
        tag='fixDim';
    else
        tag=sprintf('%dDim',dimVal);
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

function sheetName=sanitizeSheetName(sheetName)
sheetName=char(string(sheetName));
sheetName=regexprep(sheetName,'[:\\/?*\[\]]','_');
if numel(sheetName)>31
    sheetName=sheetName(1:31);
end
if isempty(sheetName)
    sheetName='Sheet1';
end
end
