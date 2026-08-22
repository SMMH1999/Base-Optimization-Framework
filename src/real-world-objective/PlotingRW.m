function PlotingRW(benchmarkResults,maxItr,maxRun,algorithmFileAddress,dim)
%PLOTINGRW Plot convergence curves for real-world engineering problems.
%
% The layout mirrors the single-objective CEC convergence output: up to
% sixteen problems per figure, one curve per algorithm, adaptive log scaling,
% and a terminal-overlap inset when endpoints are visually indistinguishable.

[algorithmNames,~]=Get_algorithm(algorithmFileAddress);
algorithmNames=string(algorithmNames(:));
ctx=ProjectContext('get');
dimTag=dimTagFromInput(dim);
plotDir=fullfile(ctx.resultsRoot,'Real World Problems',plotSubFromDimTag(dimTag));
if exist(plotDir,'dir')~=7
    mkdir(plotDir);
end

subplotRows=4;
subplotCols=4;
plotsPerFigure=subplotRows*subplotCols;
figureCounter=0;
currentFigure=[];
legendHandles=gobjects(0);
legendEntries=strings(0,1);
insetIterationCount=5;
overlapTolerance=0.08;
logScaleThreshold=1e3;

numProblems=size(benchmarkResults,2);
numAlgorithms=size(benchmarkResults,1);

for problemIndex=1:numProblems
    if mod(problemIndex-1,plotsPerFigure)==0
        if ~isempty(currentFigure) && isgraphics(currentFigure,'figure')
            finalizeFigure(currentFigure,plotDir,figureCounter,legendHandles,legendEntries);
        end
        figureCounter=figureCounter+1;
        currentFigure=figure('Units','normalized','OuterPosition',[0 0 1 1]);
        legendHandles=gobjects(0);
        legendEntries=strings(0,1);
    end

    subplotIndex=mod(problemIndex-1,plotsPerFigure)+1;
    figure(currentFigure);
    ax=subplot(subplotRows,subplotCols,subplotIndex);
    hold(ax,'on');

    curves=nan(maxItr,numAlgorithms);
    for algorithmIndex=1:numAlgorithms
        dataMatrix=benchmarkResults{algorithmIndex,problemIndex};
        if isempty(dataMatrix) || size(dataMatrix,1)<1
            continue;
        end

        % Median best-so-far trajectory across independent runs. Unlike a
        % pointwise minimum envelope, every point is a robust run aggregate.
        curves(:,algorithmIndex)=medianRunCurve(dataMatrix,maxItr,maxRun);
    end

    useLogScale=shouldUseLogScale(curves,logScaleThreshold);
    localHandles=gobjects(0);
    localAlgorithms=[];

    for algorithmIndex=1:numAlgorithms
        curve=curves(:,algorithmIndex);
        if ~any(isfinite(curve))
            continue;
        end

        if algorithmIndex>=8
            lineStyle='-.';
        else
            lineStyle='-';
        end

        h=plot(ax,1:maxItr,curve,'LineStyle',lineStyle,'LineWidth',1);
        localHandles(end+1)=h; %#ok<AGROW>
        localAlgorithms(end+1)=algorithmIndex; %#ok<AGROW>

        if subplotIndex==1
            legendHandles(end+1)=h; %#ok<AGROW>
            legendEntries(end+1,1)=algorithmNames(algorithmIndex); %#ok<AGROW>
        end
    end

    if useLogScale
        set(ax,'YScale','log');
    else
        set(ax,'YScale','linear');
    end

    problem=EngineeringProblem(problemIndex);
    title(ax,sprintf('P%d - %s',problemIndex,problem.name),'Interpreter','none');
    xlabel(ax,'Iteration');
    ylabel(ax,'Fitness');
    grid(ax,'on');
    box(ax,'on');
    hold(ax,'off');

    addOverlapInset(ax,curves,localHandles,localAlgorithms,maxItr, ...
        insetIterationCount,overlapTolerance);
end

if ~isempty(currentFigure) && isgraphics(currentFigure,'figure')
    finalizeFigure(currentFigure,plotDir,figureCounter,legendHandles,legendEntries);
end
end


function curve=medianRunCurve(dataMatrix,maxItr,maxRun)
curve=nan(maxItr,1);
rowCount=min(maxItr,size(dataMatrix,1));
runCount=min(maxRun,size(dataMatrix,2));
for rowIndex=1:rowCount
    values=dataMatrix(rowIndex,1:runCount);
    values=values(isfinite(values));
    if ~isempty(values)
        curve(rowIndex)=median(values);
    end
end
end

function finalizeFigure(fig,plotDir,figureCounter,plotHandles,legendEntries)
if ~isempty(plotHandles)
    hLegend=legend(plotHandles,cellstr(legendEntries), ...
        'Orientation','horizontal','Location','southoutside');
    set(hLegend,'Position',[0.175,0.015,0.68,0.03],'Units','normalized');
end

if exist('sgtitle','file')==2
    figure(fig);
    sgtitle('Real-World Engineering Benchmark Convergence');
else
    annotation(fig,'textbox',[0 0.965 1 0.03], ...
        'String','Real-World Engineering Benchmark Convergence', ...
        'EdgeColor','none','HorizontalAlignment','center','FontWeight','bold');
end

svgPath=fullfile(plotDir,sprintf('RW_Plots%d.svg',figureCounter));
jpgPath=fullfile(plotDir,sprintf('RW_Plots%d.jpg',figureCounter));
exportVectorSvg(fig,svgPath);
saveas(fig,jpgPath);
close(fig);
end

function tf=shouldUseLogScale(curveData,dynamicRangeThreshold)
values=curveData(isfinite(curveData));
if isempty(values) || any(values<=0)
    tf=false;
    return;
end
minValue=min(values);
maxValue=max(values);
tf=(maxValue/minValue)>=dynamicRangeThreshold;
end

function addOverlapInset(mainAx,curveData,lineHandles,algorithmIndices,maxItr,iterationCount,overlapTolerance)
if maxItr<1 || isempty(curveData) || numel(lineHandles)<2
    return;
end

[selectedColumns,selectedHandleIndices]=findTerminalOverlap( ...
    mainAx,curveData,algorithmIndices,overlapTolerance);
if numel(selectedColumns)<2
    return;
end

tailStart=max(1,maxItr-iterationCount+1);
tailX=tailStart:maxItr;
tailData=curveData(tailX,selectedColumns);

originalUnits=get(mainAx,'Units');
set(mainAx,'Units','normalized');
mainPosition=get(mainAx,'Position');
set(mainAx,'Units',originalUnits);

insetPosition=[mainPosition(1)+0.54*mainPosition(3), ...
    mainPosition(2)+0.53*mainPosition(4), ...
    0.42*mainPosition(3),0.39*mainPosition(4)];
parentFigure=ancestor(mainAx,'figure');
insetAx=axes('Parent',parentFigure,'Units','normalized', ...
    'Position',insetPosition,'Box','on','FontSize',5,'LineWidth',0.6);
hold(insetAx,'on');

for index=1:numel(selectedColumns)
    handleIndex=selectedHandleIndices(index);
    plot(insetAx,tailX,tailData(:,index), ...
        'Color',get(lineHandles(handleIndex),'Color'), ...
        'LineStyle',get(lineHandles(handleIndex),'LineStyle'), ...
        'LineWidth',1);
end

set(insetAx,'YScale','linear','XTick',tailX);
xlim(insetAx,tailXLimits(tailStart,maxItr));
setTightYLimits(insetAx,tailData);
title(insetAx,'Final overlap','FontSize',6);
hold(insetAx,'off');
end

function [selectedColumns,selectedHandleIndices]=findTerminalOverlap(mainAx,curveData,algorithmIndices,overlapTolerance)
selectedColumns=[];
selectedHandleIndices=[];
if isempty(algorithmIndices)
    return;
end

finalValues=curveData(end,algorithmIndices);
finiteMask=isfinite(finalValues);
if nnz(finiteMask)<2
    return;
end

yScale=get(mainAx,'YScale');
yLimits=get(mainAx,'YLim');
if strcmpi(yScale,'log')
    finiteMask=finiteMask & finalValues>0;
    if nnz(finiteMask)<2 || any(yLimits<=0)
        return;
    end
    displayValues=log10(finalValues);
    displayLimits=log10(yLimits);
else
    displayValues=finalValues;
    displayLimits=yLimits;
end

axisSpan=displayLimits(2)-displayLimits(1);
if ~isfinite(axisSpan) || axisSpan<=0
    return;
end

validHandleIndices=find(finiteMask);
validColumns=algorithmIndices(finiteMask);
normalizedValues=(displayValues(finiteMask)-displayLimits(1))./axisSpan;
[sortedValues,order]=sort(normalizedValues);
sortedColumns=validColumns(order);
sortedHandleIndices=validHandleIndices(order);

bestStart=1;
bestEnd=1;
left=1;
for right=1:numel(sortedValues)
    while sortedValues(right)-sortedValues(left)>overlapTolerance
        left=left+1;
    end
    if (right-left)>(bestEnd-bestStart)
        bestStart=left;
        bestEnd=right;
    end
end

if bestEnd-bestStart+1>=2
    selectedColumns=sortedColumns(bestStart:bestEnd);
    selectedHandleIndices=sortedHandleIndices(bestStart:bestEnd);
end
end

function limits=tailXLimits(firstIteration,lastIteration)
if firstIteration==lastIteration
    limits=[firstIteration-0.5,lastIteration+0.5];
else
    limits=[firstIteration,lastIteration];
end
end

function setTightYLimits(ax,data)
values=data(isfinite(data));
if isempty(values)
    return;
end
minValue=min(values);
maxValue=max(values);
if minValue==maxValue
    padding=max(abs(minValue)*0.05,eps(max(1,abs(minValue))));
else
    padding=0.08*(maxValue-minValue);
end
ylim(ax,[minValue-padding,maxValue+padding]);
end

function tag=dimTagFromInput(dimVal)
if isempty(dimVal)
    tag='fixDim';
    return;
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

function sub=plotSubFromDimTag(dimTag)
value=lower(string(dimTag));
if value=="fixdim"
    sub='Plot_fix';
else
    numberText=regexprep(string(dimTag),"Dim","");
    sub=char("Plot_"+numberText);
end
end
