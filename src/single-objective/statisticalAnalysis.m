function []=statisticalAnalysis(benchmarkResults,maxItr,maxRun,algorithmNames,nFunction,cecLabel,baseName,resultsDir,fileFormat)
%STATISTICALANALYSIS Compute tests and write only dynamic template cells.

%% Configuration
config=statisticalConfig('get');
algorithmNames=string(algorithmNames(:));
numAlgs=numel(algorithmNames);
alpha=config.alpha;
referenceAlgorithm=config.referenceAlgorithm;
layout=getStatisticalTemplateLayout(nFunction);

if referenceAlgorithm<1 || referenceAlgorithm>numAlgs
    error('statisticalAnalysis:InvalidReference', ...
        'referenceAlgorithm is outside the algorithm list.');
end

if numAlgs>layout.algorithmCapacity
    error('statisticalAnalysis:TemplateCapacityExceeded', ...
        'Statistical template supports at most %d algorithms.', ...
        layout.algorithmCapacity);
end

comparisonAlgorithms=setdiff(1:numAlgs,referenceAlgorithm,'stable');

%% Compute one-sided reference comparisons
[tTestP,tTestH,wilcoxonP,wilcoxonH,wilcoxonStat]=buildReferenceTests( ...
    benchmarkResults,maxItr,maxRun,nFunction,referenceAlgorithm, ...
    comparisonAlgorithms,alpha,config);

%% Compute function ranking and Friedman analysis
friedmanOutput=buildFriedmanOutput( ...
    benchmarkResults,maxItr,maxRun,algorithmNames,nFunction,alpha,config);

%% Save numerical test outputs
if ~isempty(comparisonAlgorithms)
    pairwiseHeaders=buildPairwiseHeaders( ...
        algorithmNames,referenceAlgorithm,comparisonAlgorithms);

    testSheets={'TTest_p','TTest_h','Wilcoxon_p','Wilcoxon_h','Wilcoxon_stat'};
    for sheetIndex=1:numel(testSheets)
        Saving(pairwiseHeaders,resultsDir,baseName,fileFormat, ...
            testSheets{sheetIndex},layout.pairwiseHeaderStart);
    end

    Saving(tTestP,resultsDir,baseName,fileFormat,'TTest_p',layout.pairwiseDataStart);
    Saving(tTestH,resultsDir,baseName,fileFormat,'TTest_h',layout.pairwiseDataStart);
    Saving(wilcoxonP,resultsDir,baseName,fileFormat,'Wilcoxon_p',layout.pairwiseDataStart);
    Saving(wilcoxonH,resultsDir,baseName,fileFormat,'Wilcoxon_h',layout.pairwiseDataStart);
    Saving(wilcoxonStat,resultsDir,baseName,fileFormat,'Wilcoxon_stat',layout.pairwiseDataStart);
end

friedmanHeaders=cellstr(algorithmNames+" Rank")';
Saving(friedmanHeaders,resultsDir,baseName,fileFormat, ...
    'Friedman',layout.friedmanHeaderStart);

saveFriedmanOutput( ...
    friedmanOutput,resultsDir,baseName,fileFormat,layout);
saveExplanation( ...
    algorithmNames(referenceAlgorithm),alpha,config, ...
    resultsDir,baseName,fileFormat);

% Keep these established inputs in the interface for compatibility.
if false %#ok<UNRCH>
    disp(cecLabel);
end
end

function layout=getStatisticalTemplateLayout(nFunction)
layout.algorithmCapacity=15;
layout.pairwiseHeaderStart='B2';
layout.pairwiseDataStart='B3';
layout.friedmanHeaderStart='B2';
layout.friedmanRankStart='B3';
layout.friedmanBestStart='Q3';
layout.friedmanKruskalStart='R3';
layout.friedmanSignificantStart='S3';
layout.friedmanSummaryRow=nFunction+4;
layout.friedmanOverallValueRow=nFunction+8;
layout.friedmanPostHocDataRow=nFunction+13;
end

function saveFriedmanOutput(output,resultsDir,baseName,fileFormat,layout)
nFunction=size(output.rankMatrix,1);

Saving(output.rankMatrix,resultsDir,baseName,fileFormat, ...
    'Friedman',layout.friedmanRankStart);
Saving(cellstr(output.bestAlgorithm),resultsDir,baseName,fileFormat, ...
    'Friedman',layout.friedmanBestStart);
Saving(output.kruskalP,resultsDir,baseName,fileFormat, ...
    'Friedman',layout.friedmanKruskalStart);

significantText=cell(nFunction,1);
for functionIndex=1:nFunction
    if ~output.validFunction(functionIndex) || ~isfinite(output.kruskalP(functionIndex))
        significantText{functionIndex}='Not available';
    elseif output.kruskalSignificant(functionIndex)
        significantText{functionIndex}='Yes';
    else
        significantText{functionIndex}='No';
    end
end

Saving(significantText,resultsDir,baseName,fileFormat, ...
    'Friedman',layout.friedmanSignificantStart);
Saving([output.averageRank;output.overallRank], ...
    resultsDir,baseName,fileFormat,'Friedman', ...
    sprintf('B%d',layout.friedmanSummaryRow));

friedmanSummary={ ...
    output.functionCount; ...
    output.friedmanP; ...
    yesNo(output.friedmanSignificant)};
Saving(friedmanSummary,resultsDir,baseName,fileFormat, ...
    'Friedman',sprintf('B%d',layout.friedmanOverallValueRow));

postHocData=postHocToCell(output.postHoc);
if ~isempty(postHocData)
    Saving(postHocData,resultsDir,baseName,fileFormat, ...
        'Friedman',sprintf('A%d',layout.friedmanPostHocDataRow));
end
end

function saveExplanation(referenceAlgorithmName,alpha,config,resultsDir,baseName,fileFormat)
if lower(string(config.performanceDirection))=="max"
    directionText='higher values are better';
    tailText='right-tailed';
else
    directionText='lower values are better';
    tailText='left-tailed';
end

if config.applyHolm
    correctionText='Holm-adjusted across reference comparisons within each function';
else
    correctionText='unadjusted p-values';
end

explanations={ ...
    'Conclusions', ...
    'Mean, standard deviation, CPU time, number of best functions, and overall rank for the current benchmark set and dimension.'; ...
    'TTest_p', ...
    sprintf('%s Welch two-sample t-test p-values. Reference = %s. Values are %s. p < %.3g supports superiority of the reference algorithm.', ...
        tailText,char(referenceAlgorithmName),correctionText,alpha); ...
    'TTest_h', ...
    sprintf('Decision corresponding to TTest_p: 1 = reference superiority is statistically supported at alpha = %.3g; 0 = superiority is not established.',alpha); ...
    'Wilcoxon_p', ...
    sprintf('%s Wilcoxon rank-sum (Mann-Whitney) p-values for independent runs. Reference = %s. Values are %s.', ...
        tailText,char(referenceAlgorithmName),correctionText); ...
    'Wilcoxon_h', ...
    sprintf('Decision corresponding to Wilcoxon_p: 1 = reference superiority is statistically supported at alpha = %.3g; 0 = superiority is not established.',alpha); ...
    'Wilcoxon_stat', ...
    'Wilcoxon rank-sum statistic W. This is a technical test statistic; use Wilcoxon_p and Wilcoxon_h for interpretation.'; ...
    'Friedman', ...
    ['Per-function algorithm ranks are shown together with the Kruskal-Wallis p-value for that function. ' ...
     'The lower rank is better. The overall Friedman test evaluates rank differences across all benchmark functions, ' ...
     'followed by reference-only Holm post-hoc comparisons when the overall test is significant.']; ...
    'Direction', ...
    sprintf('Optimization interpretation: %s.',directionText)};

Saving(explanations,resultsDir,baseName,fileFormat,'Explanation','A1');
end
function headers=buildPairwiseHeaders(algorithmNames,referenceAlgorithm,comparisonAlgorithms)
headers=cell(1,numel(comparisonAlgorithms));
referenceName=char(algorithmNames(referenceAlgorithm));

for comparisonIndex=1:numel(comparisonAlgorithms)
    comparatorName=char(algorithmNames(comparisonAlgorithms(comparisonIndex)));
    headers{comparisonIndex}=sprintf('%s vs %s',referenceName,comparatorName);
end
end

function [tP,tH,wP,wH,wStat]=buildReferenceTests(benchmarkResults,maxItr,maxRun,nFunction,referenceAlgorithm,comparisonAlgorithms,alpha,config)
numComparisons=numel(comparisonAlgorithms);
tRaw=nan(nFunction,numComparisons);
wRaw=nan(nFunction,numComparisons);
wStat=nan(nFunction,numComparisons);

if lower(string(config.performanceDirection))=="max"
    tail='right';
else
    tail='left';
end

for functionIndex=1:nFunction
    if isempty(benchmarkResults{referenceAlgorithm,functionIndex})
        continue;
    end

    referenceValues=getFinalValues( ...
        benchmarkResults{referenceAlgorithm,functionIndex},maxItr,maxRun);

    for comparisonIndex=1:numComparisons
        comparatorAlgorithm=comparisonAlgorithms(comparisonIndex);
        if isempty(benchmarkResults{comparatorAlgorithm,functionIndex})
            continue;
        end

        comparatorValues=getFinalValues( ...
            benchmarkResults{comparatorAlgorithm,functionIndex},maxItr,maxRun);

        tRaw(functionIndex,comparisonIndex)=safeWelchP( ...
            referenceValues,comparatorValues,tail,alpha);

        [wRaw(functionIndex,comparisonIndex),wStat(functionIndex,comparisonIndex)]= ...
            safeRankSum(referenceValues,comparatorValues,tail,alpha);
    end
end

if config.applyHolm
    tP=nan(size(tRaw));
    wP=nan(size(wRaw));

    for functionIndex=1:nFunction
        tP(functionIndex,:)=holmAdjust(tRaw(functionIndex,:));
        wP(functionIndex,:)=holmAdjust(wRaw(functionIndex,:));
    end
else
    tP=tRaw;
    wP=wRaw;
end

tH=double(tP<alpha);
wH=double(wP<alpha);
tH(~isfinite(tP))=NaN;
wH(~isfinite(wP))=NaN;
end

function p=safeWelchP(x,y,tail,alpha)
x=x(isfinite(x));
y=y(isfinite(y));

if numel(x)<2 || numel(y)<2
    p=NaN;
    return;
end

if all(x==x(1)) && all(y==y(1))
    if x(1)==y(1)
        p=1;
    elseif strcmpi(tail,'left')
        p=double(x(1)>y(1));
    else
        p=double(x(1)<y(1));
    end
    return;
end

[~,p]=ttest2(x,y,'Alpha',alpha,'Tail',tail,'Vartype','unequal');
end

function [p,statistic]=safeRankSum(x,y,tail,alpha)
x=x(isfinite(x));
y=y(isfinite(y));

if isempty(x) || isempty(y)
    p=NaN;
    statistic=NaN;
    return;
end

if all(x==x(1)) && all(y==y(1)) && x(1)==y(1)
    p=1;
    combinedRanks=tiedrank([x(:);y(:)]);
    statistic=sum(combinedRanks(1:numel(x)));
    return;
end

[p,~,stats]=ranksum(x,y,'alpha',alpha,'tail',tail);
statistic=stats.ranksum;
end

function output=buildFriedmanOutput(benchmarkResults,maxItr,maxRun,algorithmNames,nFunction,alpha,config)
numAlgs=numel(algorithmNames);
performanceMatrix=nan(nFunction,numAlgs);
rankMatrix=nan(nFunction,numAlgs);
kruskalP=nan(nFunction,1);
kruskalSignificant=false(nFunction,1);
bestAlgorithm=strings(nFunction,1);
validFunction=false(nFunction,1);

for functionIndex=1:nFunction
    runMatrix=nan(maxRun,numAlgs);
    complete=true;

    for algorithmIndex=1:numAlgs
        if isempty(benchmarkResults{algorithmIndex,functionIndex})
            complete=false;
            break;
        end

        values=getFinalValues( ...
            benchmarkResults{algorithmIndex,functionIndex},maxItr,maxRun);

        if numel(values)~=maxRun || any(~isfinite(values))
            complete=false;
            break;
        end

        runMatrix(:,algorithmIndex)=values(:);

        if lower(string(config.rankingMetric))=="median"
            performanceMatrix(functionIndex,algorithmIndex)=median(values);
        else
            performanceMatrix(functionIndex,algorithmIndex)=mean(values);
        end
    end

    if ~complete
        bestAlgorithm(functionIndex)="Not available";
        continue;
    end

    validFunction(functionIndex)=true;

    if lower(string(config.performanceDirection))=="max"
        rankMatrix(functionIndex,:)=tiedrank(-performanceMatrix(functionIndex,:));
    else
        rankMatrix(functionIndex,:)=tiedrank(performanceMatrix(functionIndex,:));
    end

    bestAlgorithm(functionIndex)=formatBestAlgorithms( ...
        rankMatrix(functionIndex,:),algorithmNames);

    kruskalP(functionIndex)=safeKruskalWallis(runMatrix);
    kruskalSignificant(functionIndex)= ...
        isfinite(kruskalP(functionIndex)) && kruskalP(functionIndex)<alpha;
end

validRanks=rankMatrix(validFunction,:);
validPerformance=performanceMatrix(validFunction,:);
functionCount=size(validRanks,1);

if functionCount>0
    averageRank=mean(validRanks,1,'omitnan');
    overallRank=tiedrank(averageRank);
else
    averageRank=nan(1,numAlgs);
    overallRank=nan(1,numAlgs);
end

friedmanP=NaN;
if functionCount>=2 && numAlgs>=2
    if all(validPerformance(:)==validPerformance(1))
        friedmanP=1;
    else
        friedmanP=friedman(validPerformance,1,'off');
    end
end

friedmanSignificant=isfinite(friedmanP) && friedmanP<alpha;
postHoc=buildFriedmanHolmPostHoc( ...
    averageRank,functionCount,algorithmNames,config.referenceAlgorithm, ...
    alpha,friedmanSignificant);

output=struct();
output.rankMatrix=rankMatrix;
output.kruskalP=kruskalP;
output.kruskalSignificant=kruskalSignificant;
output.bestAlgorithm=bestAlgorithm;
output.averageRank=averageRank;
output.overallRank=overallRank;
output.friedmanP=friedmanP;
output.friedmanSignificant=friedmanSignificant;
output.validFunction=validFunction;
output.functionCount=functionCount;
output.postHoc=postHoc;
end

function data=postHocToCell(postHoc)
rowCount=height(postHoc);
data=cell(rowCount,4);

for rowIndex=1:rowCount
    data{rowIndex,1}=char(postHoc.Comparison(rowIndex));
    data{rowIndex,2}=postHoc.AdjustedP(rowIndex);

    if postHoc.Significant(rowIndex)
        data{rowIndex,3}='Yes';
    else
        data{rowIndex,3}='No';
    end

    data{rowIndex,4}=char(postHoc.Result(rowIndex));
end
end

function p=safeKruskalWallis(runMatrix)
finiteValues=runMatrix(isfinite(runMatrix));

if isempty(finiteValues)
    p=NaN;
    return;
end

if all(finiteValues==finiteValues(1))
    p=1;
    return;
end

p=kruskalwallis(runMatrix,[],'off');
end

function bestText=formatBestAlgorithms(ranks,algorithmNames)
bestIndices=find(ranks==min(ranks,[],'omitnan'));

if isempty(bestIndices)
    bestText="Not available";
    return;
end

bestText=strjoin(algorithmNames(bestIndices)," / ");
end

function postHoc=buildFriedmanHolmPostHoc(averageRank,functionCount,algorithmNames,referenceAlgorithm,alpha,friedmanSignificant)
numAlgs=numel(algorithmNames);
comparisonAlgorithms=setdiff(1:numAlgs,referenceAlgorithm,'stable');
comparisonCount=numel(comparisonAlgorithms);
comparison=strings(comparisonCount,1);
adjustedP=nan(comparisonCount,1);
significant=false(comparisonCount,1);
result=strings(comparisonCount,1);

for comparisonIndex=1:comparisonCount
    comparator=comparisonAlgorithms(comparisonIndex);
    comparison(comparisonIndex)= ...
        algorithmNames(referenceAlgorithm)+" vs "+algorithmNames(comparator);
end

if ~friedmanSignificant || functionCount<2 || numAlgs<2
    result(:)="Not evaluated: overall Friedman test is not significant";
    postHoc=table(comparison,adjustedP,significant,result, ...
        'VariableNames',{'Comparison','AdjustedP','Significant','Result'});
    return;
end

standardError=sqrt(numAlgs*(numAlgs+1)/(6*functionCount));
rawP=nan(1,comparisonCount);

for comparisonIndex=1:comparisonCount
    comparator=comparisonAlgorithms(comparisonIndex);
    z=(averageRank(referenceAlgorithm)-averageRank(comparator))/standardError;
    rawP(comparisonIndex)=normcdf(z);
end

adjustedP=holmAdjust(rawP)';
significant=adjustedP<alpha;

for comparisonIndex=1:comparisonCount
    comparator=comparisonAlgorithms(comparisonIndex);

    if significant(comparisonIndex) && ...
            averageRank(referenceAlgorithm)<averageRank(comparator)
        result(comparisonIndex)="Reference significantly better";
    else
        result(comparisonIndex)="Reference superiority not established";
    end
end

postHoc=table(comparison,adjustedP,significant,result, ...
    'VariableNames',{'Comparison','AdjustedP','Significant','Result'});
end

function values=getFinalValues(dataMatrix,maxItr,maxRun)
values=dataMatrix(maxItr,1:maxRun);
values=double(values(:)');
end

function adjusted=holmAdjust(pValues)
adjusted=nan(size(pValues));
valid=find(isfinite(pValues));

if isempty(valid)
    return;
end

[sortedP,order]=sort(pValues(valid),'ascend');
count=numel(sortedP);
adjustedSorted=zeros(size(sortedP));

for index=1:count
    adjustedSorted(index)=min(1,(count-index+1)*sortedP(index));

    if index>1
        adjustedSorted(index)=max( ...
            adjustedSorted(index),adjustedSorted(index-1));
    end
end

adjusted(valid(order))=adjustedSorted;
end

function text=yesNo(value)
if value
    text='Yes';
else
    text='No';
end
end

