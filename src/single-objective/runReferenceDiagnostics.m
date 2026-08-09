function runReferenceDiagnostics(benchmarkResults,maxItr,maxRun,populationNo, ...
    costFunctionDetails,algorithms,algorithmNames,dimOverride,cecIndex,dimTag)
%RUNREFERENCEDIAGNOSTICS Replay representative reference runs after CEC benchmarking.
%
% The diagnostic phase starts only after the normal CEC2005 benchmark output
% stage has completed. Selected functions are replayed using the deterministic
% seed of their median final-fitness run. Independent diagnostic functions are
% executed with parfor when the project parallel switch is enabled.

%% Configuration
config=referenceDiagnosticConfig('get');
statsConfig=statisticalConfig('get');
referenceAlgorithm=statsConfig.referenceAlgorithm;
algorithmNames=string(algorithmNames(:));
nFunction=size(benchmarkResults,2);

if ~config.enabled || cecIndex~=config.cecIndex
    return;
end

if cecIndex~=1
    error('runReferenceDiagnostics:UnsupportedBenchmark', ...
        'The current diagnostic baseline is restricted to CEC2005.');
end

if referenceAlgorithm<1 || referenceAlgorithm>numel(algorithms)
    error('runReferenceDiagnostics:InvalidReference', ...
        'The configured reference algorithm is outside the algorithm list.');
end

functionIndices=unique(config.functionIndices(:)','stable');
invalidFunctions=functionIndices(functionIndices<1 | functionIndices>nFunction);
if ~isempty(invalidFunctions)
    error('runReferenceDiagnostics:InvalidFunctionIndices', ...
        'Configured function indices exceed the available CEC2005 functions: %s', ...
        mat2str(invalidFunctions));
end

%% Output directory
ctx=ProjectContext('get');
resultsDir=fullfile(ctx.resultsRoot,'CEC2005','diagnostics','baseline');
plotDir=fullfile(resultsDir,'plots');

if exist(resultsDir,'dir')~=7
    mkdir(resultsDir);
end
if exist(plotDir,'dir')~=7
    mkdir(plotDir);
end

algorithm=algorithms{referenceAlgorithm};
algorithmName=algorithmNames(referenceAlgorithm);

%% Build diagnostic tasks
numRequestedFunctions=numel(functionIndices);
tasks=cell(numRequestedFunctions,1);
taskCount=0;

for functionIndex=functionIndices
    resultMatrix=benchmarkResults{referenceAlgorithm,functionIndex};
    if isempty(resultMatrix) || size(resultMatrix,1)<maxItr || ...
            size(resultMatrix,2)<maxRun
        warning('runReferenceDiagnostics:MissingBenchmarkResult', ...
            'Skipping F%d because its reference benchmark result is unavailable.', ...
            functionIndex);
        continue;
    end

    [lb,ub,dim,costFunction]=costFunctionDetails(functionIndex);
    if ~isempty(dimOverride)
        dim=dimOverride;
    end

    storedRawFitness=double(resultMatrix(maxItr,1:maxRun));
    storedFitness=storedRawFitness;
    for runIndex=1:maxRun
        storedFitness(runIndex)=FixIfBelowFmin( ...
            storedFitness(runIndex),functionIndex,cecIndex);
    end

    [selectedRun,medianFitness]=selectMedianRun(storedFitness);

    taskCount=taskCount+1;
    task=struct();
    task.functionIndex=functionIndex;
    task.lowerBound=lb;
    task.upperBound=ub;
    task.dimension=dim;
    task.costFunction=costFunction;
    task.algorithm=algorithm;
    task.algorithmIndex=referenceAlgorithm;
    task.algorithmName=algorithmName;
    task.selectedRun=selectedRun;
    task.medianFitness=medianFitness;
    task.storedRawFitnessRuns=storedRawFitness;
    task.storedFitnessRuns=storedFitness;
    task.storedRawFitness=storedRawFitness(selectedRun);
    task.storedFitness=storedFitness(selectedRun);
    task.replaySeed=1000000*cecIndex+10000*dim+100*functionIndex+ ...
        referenceAlgorithm+selectedRun;
    tasks{taskCount}=task;
end

tasks=tasks(1:taskCount);
if isempty(tasks)
    return;
end

%% Replay selected functions
parallelEnabled=isDiagnosticParallelEnabled(taskCount);
results=cell(taskCount,1);

if parallelEnabled
    fprintf('  Running CEC2005 diagnostics in PARALLEL mode (%d functions)...\n',taskCount);
    parfor taskIndex=1:taskCount
        results{taskIndex}=runDiagnosticTask( ...
            tasks{taskIndex},config,maxItr,maxRun,populationNo,cecIndex,dimTag);
    end
else
    fprintf('  Running CEC2005 diagnostics in SERIAL mode (%d functions)...\n',taskCount);
    for taskIndex=1:taskCount
        results{taskIndex}=runDiagnosticTask( ...
            tasks{taskIndex},config,maxItr,maxRun,populationNo,cecIndex,dimTag);
    end
end

%% Export figures and replay data
summaryRows=cell(taskCount,1);
summaryCount=0;

for taskIndex=1:taskCount
    result=results{taskIndex};
    if isempty(result)
        continue;
    end

    diagnosticData=result.diagnosticData;

    if config.saveReplayData
        fileName=sprintf('F%d_%s_MedianRun%d.mat', ...
            diagnosticData.functionIndex, ...
            sanitizeFileName(diagnosticData.algorithmName), ...
            diagnosticData.selectedRun);
        save(fullfile(resultsDir,fileName),'diagnosticData');
    end

    summaryCount=summaryCount+1;
    summaryRows{summaryCount}=table( ...
        diagnosticData.functionIndex,diagnosticData.dimension, ...
        diagnosticData.algorithmIndex,diagnosticData.algorithmName, ...
        diagnosticData.selectedRun,diagnosticData.seed, ...
        diagnosticData.medianFitness,diagnosticData.storedFitness, ...
        diagnosticData.replayFitness,diagnosticData.replayMatchesStored, ...
        diagnosticData.functionEvaluations,diagnosticData.replayTime, ...
        diagnosticData.capturedEvaluations,diagnosticData.captureTruncated, ...
        parallelEnabled, ...
        'VariableNames',{'Function','Dimension','AlgorithmIndex','Algorithm', ...
        'SelectedRun','Seed','MedianFitness','StoredFitness','ReplayFitness', ...
        'ReplayMatchesStored','FunctionEvaluations','ReplayTime', ...
        'CapturedEvaluations','CaptureTruncated','ParallelDiagnostic'});

    fprintf('    F%d | %s | median run %d | replay match: %s | %.3f s\n', ...
        diagnosticData.functionIndex,char(diagnosticData.algorithmName), ...
        diagnosticData.selectedRun,yesNo(diagnosticData.replayMatchesStored), ...
        diagnosticData.replayTime);
end

%% Export combined diagnostic figure
if config.exportFigures
    exportCombinedDiagnosticFigure(results,plotDir,config,algorithmName);
end

%% Save summary
if summaryCount>0
    summaryTable=vertcat(summaryRows{1:summaryCount});
    save(fullfile(resultsDir,'DiagnosticBaselineSummary.mat'),'summaryTable');
    writetable(summaryTable,fullfile(resultsDir,'DiagnosticBaselineSummary.csv'));
end
end

function result=runDiagnosticTask(task,config,maxItr,maxRun,populationNo,cecIndex,dimTag)
%RUNDIAGNOSTICTASK Replay one function and calculate plot data.
rng(task.replaySeed,"twister");

maxFEs=1000000;
counter=EvalCounter(maxFEs);
recorder=DiagnosticRecorder(config.maxCapturedEvaluations);
objectiveRun=@(x) recordedObjective( ...
    task.costFunction,x,counter,recorder,populationNo);

tStart=tic;
[replayRawFitness,bestPosition,convergenceCurve]=task.algorithm( ...
    task.lowerBound,task.upperBound,task.dimension,populationNo,maxItr,objectiveRun);
replayTime=toc(tStart);

convergenceCurve=double(convergenceCurve(:));
if numel(convergenceCurve)~=maxItr
    error('runReferenceDiagnostics:InvalidCurveLength', ...
        'F%d replay returned %d convergence values; expected %d.', ...
        task.functionIndex,numel(convergenceCurve),maxItr);
end

replayFitness=FixIfBelowFmin(replayRawFitness,task.functionIndex,cecIndex);
replayMatchesStored=numericallyEqual(replayRawFitness,task.storedRawFitness);

if config.validateReplay && ~replayMatchesStored
    warning('runReferenceDiagnostics:ReplayMismatch', ...
        ['CEC2005 F%d median run %d did not reproduce the stored raw fitness. ' ...
         'Stored = %.17g, replay = %.17g.'], ...
        task.functionIndex,task.selectedRun,task.storedRawFitness,replayRawFitness);
end

[capturedPositions,capturedFitness,capturedCount,captureTruncated]=recorder.snapshot();
[averageFitnessCurve,trajectory1D]=buildDiagnosticCurves( ...
    capturedPositions,capturedFitness,maxItr,bestPosition);

lbVec=expandBounds(task.lowerBound,task.dimension);
ubVec=expandBounds(task.upperBound,task.dimension);
anchorPoint=buildAnchorPoint(bestPosition,lbVec,ubVec,task.dimension);
[gridX,gridY,gridZ]=buildSurfaceData( ...
    task.costFunction,lbVec,ubVec,anchorPoint,config.surfaceGridSize);

diagnosticData=struct();
diagnosticData.cecIndex=cecIndex;
diagnosticData.cecName="CEC2005";
diagnosticData.functionIndex=task.functionIndex;
diagnosticData.dimension=task.dimension;
diagnosticData.lowerBound=double(task.lowerBound);
diagnosticData.upperBound=double(task.upperBound);
diagnosticData.algorithmIndex=task.algorithmIndex;
diagnosticData.algorithmName=task.algorithmName;
diagnosticData.selectionMethod=string(config.runSelection);
diagnosticData.selectedRun=task.selectedRun;
diagnosticData.seed=task.replaySeed;
diagnosticData.medianFitness=task.medianFitness;
diagnosticData.storedRawFitnessRuns=task.storedRawFitnessRuns;
diagnosticData.storedFitnessRuns=task.storedFitnessRuns;
diagnosticData.storedRawFitness=task.storedRawFitness;
diagnosticData.storedFitness=task.storedFitness;
diagnosticData.replayRawFitness=double(replayRawFitness);
diagnosticData.replayFitness=double(replayFitness);
diagnosticData.replayMatchesStored=replayMatchesStored;
diagnosticData.bestPosition=double(bestPosition(:)');
diagnosticData.convergenceCurve=convergenceCurve;
diagnosticData.functionEvaluations=counter.count;
diagnosticData.replayTime=replayTime;
diagnosticData.populationNo=populationNo;
diagnosticData.maxItr=maxItr;
diagnosticData.maxRun=maxRun;
diagnosticData.dimTag=string(dimTag);
diagnosticData.capturedPositions=capturedPositions;
diagnosticData.capturedFitness=capturedFitness;
diagnosticData.capturedEvaluations=capturedCount;
diagnosticData.captureTruncated=captureTruncated;
diagnosticData.averageFitnessCurve=averageFitnessCurve;
diagnosticData.trajectory1D=trajectory1D;

result=struct();
result.diagnosticData=diagnosticData;
result.gridX=gridX;
result.gridY=gridY;
result.gridZ=gridZ;
end

function value=recordedObjective(costFunction,x,counter,recorder,populationNo)
%RECORDEDOBJECTIVE Evaluate the objective and record lightweight telemetry.
value=costFunction(x);
counter.count=counter.count+1;

if ~counter.warned && counter.count>counter.maxFEs
    counter.warned=true;
    counter.warnItr=ceil(counter.count/max(populationNo,1));
    warning('CEC:FEsExceeded', ...
        'FEs exceeded: %d > %d (estimated itr: %d)', ...
        counter.count,counter.maxFEs,counter.warnItr);
end

recorder.add(x,value);
end

function [averageFitnessCurve,trajectory1D]=buildDiagnosticCurves( ...
    positions,fitnessValues,maxItr,bestPosition)
%BUILDDIAGNOSTICCURVES Derive average fitness and x1 best-so-far trajectory.
fitnessValues=double(fitnessValues(:));
numCaptured=numel(fitnessValues);
averageFitnessCurve=nan(maxItr,1);
trajectory1D=nan(maxItr,1);

if numCaptured<1
    bestRow=normalizePositionRow(bestPosition,max(2,numel(bestPosition)));
    trajectory1D(:)=bestRow(1);
    return;
end

cumulativeBestIndex=buildCumulativeBestIndex(fitnessValues);
edges=round(linspace(0,numCaptured,maxItr+1));

for iterationIndex=1:maxItr
    idxStart=edges(iterationIndex)+1;
    idxEnd=edges(iterationIndex+1);

    if idxStart>numCaptured
        idxStart=numCaptured;
    end
    if idxEnd<idxStart
        idxEnd=idxStart;
    end

    values=fitnessValues(idxStart:idxEnd);
    finiteValues=values(isfinite(values));
    if ~isempty(finiteValues)
        averageFitnessCurve(iterationIndex)=mean(finiteValues);
    elseif iterationIndex>1
        averageFitnessCurve(iterationIndex)=averageFitnessCurve(iterationIndex-1);
    end

    bestIdx=cumulativeBestIndex(idxEnd);
    if bestIdx>=1 && bestIdx<=size(positions,1) && isfinite(positions(bestIdx,1))
        trajectory1D(iterationIndex)=positions(bestIdx,1);
    elseif iterationIndex>1
        trajectory1D(iterationIndex)=trajectory1D(iterationIndex-1);
    end
end

if ~isfinite(trajectory1D(1))
    bestRow=normalizePositionRow(bestPosition,max(2,numel(bestPosition)));
    trajectory1D(~isfinite(trajectory1D))=bestRow(1);
end

if ~isfinite(averageFitnessCurve(1))
    finiteAll=fitnessValues(isfinite(fitnessValues));
    if ~isempty(finiteAll)
        averageFitnessCurve(~isfinite(averageFitnessCurve))=mean(finiteAll);
    end
end
end

function cumulativeBestIndex=buildCumulativeBestIndex(fitnessValues)
%BUILDCUMULATIVEBESTINDEX Track the index of the best finite value so far.
numValues=numel(fitnessValues);
cumulativeBestIndex=ones(numValues,1);
bestValue=inf;
bestIndex=1;
foundFinite=false;

for valueIndex=1:numValues
    currentValue=fitnessValues(valueIndex);
    if isfinite(currentValue) && (~foundFinite || currentValue<bestValue)
        bestValue=currentValue;
        bestIndex=valueIndex;
        foundFinite=true;
    end
    cumulativeBestIndex(valueIndex)=bestIndex;
end
end

function exportCombinedDiagnosticFigure(results,plotDir,config,algorithmName)
%EXPORTCOMBINEDDIAGNOSTICFIGURE Export all selected functions in one figure.
validMask=~cellfun(@isempty,results);
validResults=results(validMask);

if isempty(validResults)
    return;
end

numFunctions=numel(validResults);
figureHeight=max(1000,360*numFunctions);
fig=figure('Visible','off','Color','w','Position',[50 50 2500 figureHeight]);
tl=tiledlayout(fig,numFunctions,5,'Padding','compact','TileSpacing','compact');
sgtitle(tl,sprintf('Qualitative Search Behavior Analysis of %s',char(algorithmName)), ...
    'FontWeight','bold','FontSize',16);

for rowIndex=1:numFunctions
    result=validResults{rowIndex};
    diagnosticData=result.diagnosticData;

    nexttile(tl,(rowIndex-1)*5+1);
    plotParameterSpace(result.gridX,result.gridY,result.gridZ, ...
        diagnosticData.functionIndex,diagnosticData.selectedRun);

    nexttile(tl,(rowIndex-1)*5+2);
    plotSearchHistory(result.gridX,result.gridY,result.gridZ, ...
        diagnosticData,config.maxDisplayedPoints);

    nexttile(tl,(rowIndex-1)*5+3);
    plotAverageFitness(diagnosticData.averageFitnessCurve);

    nexttile(tl,(rowIndex-1)*5+4);
    plotTrajectory1D(diagnosticData.trajectory1D);

    nexttile(tl,(rowIndex-1)*5+5);
    plotConvergence(diagnosticData.convergenceCurve);
end

fileStem=sprintf('CEC2005_%s_DiagnosticSummary',sanitizeFileName(algorithmName));
exportgraphics(fig,fullfile(plotDir,[fileStem '.png']),'Resolution',300);
exportgraphics(fig,fullfile(plotDir,[fileStem '.svg']),'ContentType','vector');
close(fig);
end

function [gridX,gridY,gridZ]=buildSurfaceData(costFunction,lbVec,ubVec,anchorPoint,gridSize)
%BUILDSURFACEDATA Evaluate the objective on an x1-x2 mesh.
if numel(lbVec)<2 || numel(ubVec)<2
    error('runReferenceDiagnostics:InsufficientDimensions', ...
        'At least two dimensions are required for surface visualization.');
end

xValues=linspace(lbVec(1),ubVec(1),gridSize);
yValues=linspace(lbVec(2),ubVec(2),gridSize);
[gridX,gridY]=meshgrid(xValues,yValues);
gridZ=nan(gridSize,gridSize);

for rowIndex=1:gridSize
    for colIndex=1:gridSize
        candidate=anchorPoint;
        candidate(1)=gridX(rowIndex,colIndex);
        candidate(2)=gridY(rowIndex,colIndex);
        gridZ(rowIndex,colIndex)=double(costFunction(candidate));
    end
end
end

function tf=isDiagnosticParallelEnabled(taskCount)
%ISDIAGNOSTICPARALLELENABLED Follow the project parallel execution switch.
global RUN_PARALLEL;
pool=gcp('nocreate');
tf=~isempty(RUN_PARALLEL) && RUN_PARALLEL && ...
    ~isempty(pool) && pool.NumWorkers>1 && taskCount>1;
end

function plotParameterSpace(gridX,gridY,gridZ,functionIndex,selectedRun)
%PLOTPARAMETERSPACE Draw surface and contour view.
surfc(gridX,gridY,gridZ,'EdgeColor','none');
shading interp;
colormap(gca,'parula');
view(42,30);
grid on;
box on;
title(sprintf('F%d | Objective Landscape | Run %d',functionIndex,selectedRun));
xlabel('x_1');
ylabel('x_2');
zlabel('f(x)');
end

function plotSearchHistory(gridX,gridY,gridZ,diagnosticData,maxDisplayedPoints)
%PLOTSEARCHHISTORY Draw contour and captured search points.
contour(gridX,gridY,gridZ,12,'LineWidth',1);
hold on;
points=diagnosticData.capturedPositions;
numPoints=size(points,1);

if numPoints>0
    sampleIndex=sampleIndices(numPoints,maxDisplayedPoints);
    scatter(points(sampleIndex,1),points(sampleIndex,2),10,'k','filled', ...
        'MarkerFaceAlpha',0.45,'MarkerEdgeAlpha',0.45);
end

bestPosition=normalizePositionRow( ...
    diagnosticData.bestPosition,diagnosticData.dimension);
scatter(bestPosition(1),bestPosition(2),90,'r','filled');
hold off;
axis tight;
grid on;
box on;
title('Search History');
xlabel('x_1');
ylabel('x_2');
end

function plotAverageFitness(averageFitnessCurve)
%PLOTAVERAGEFITNESS Draw the per-iteration average fitness curve.
plot(averageFitnessCurve,'LineWidth',1.5,'Color',[0.85 0.33 0.10]);
grid on;
box on;
title('Mean Fitness');
xlabel('Iteration');
ylabel('Function value');
end

function plotTrajectory1D(trajectory1D)
%PLOTTRAJECTORY1D Draw the x1 trajectory of the best-so-far point.
plot(trajectory1D,'LineWidth',1.5,'Color',[0.00 0.45 0.74]);
grid on;
box on;
title('Trajectory of 1st Dim');
xlabel('Iteration');
ylabel('x_1');
end

function plotConvergence(convergenceCurve)
%PLOTCONVERGENCE Draw the convergence curve with a stable scale choice.
curve=double(convergenceCurve(:));
if all(isfinite(curve)) && all(curve>0)
    semilogy(curve,'LineWidth',1.8,'Color',[0.00 0.70 0.20]);
else
    plot(curve,'LineWidth',1.8,'Color',[0.00 0.70 0.20]);
end
grid on;
box on;
title('Convergence');
xlabel('Iteration');
ylabel('Best fitness');
end

function [selectedRun,medianFitness]=selectMedianRun(fitnessValues)
%SELECTMEDIANRUN Return the run closest to the median final fitness.
validMask=isfinite(fitnessValues);
if ~any(validMask)
    error('runReferenceDiagnostics:NoFiniteFitness', ...
        'No finite final fitness values are available for median-run selection.');
end

validRuns=find(validMask);
validValues=fitnessValues(validMask);
medianFitness=median(validValues);
[~,localIndex]=min(abs(validValues-medianFitness));
selectedRun=validRuns(localIndex);
end

function tf=numericallyEqual(a,b)
%NUMERICALLYEQUAL Compare deterministic replay results with scale-aware tolerance.
a=double(a);
b=double(b);

if isnan(a) && isnan(b)
    tf=true;
    return;
end

if ~isfinite(a) || ~isfinite(b)
    tf=isequal(a,b);
    return;
end

tolerance=1e-12*max(1,max(abs([a,b])));
tf=abs(a-b)<=tolerance;
end

function output=sanitizeFileName(inputText)
%SANITIZEFILENAME Replace characters invalid in common file systems.
output=regexprep(char(string(inputText)),'[<>:"/\\|?*]','_');
end

function text=yesNo(value)
if value
    text='yes';
else
    text='no';
end
end

function row=normalizePositionRow(x,dim)
%NORMALIZEPOSITIONROW Convert an input candidate to a 1-by-dim row vector.
row=zeros(1,dim);
flat=double(x(:)');
if isempty(flat)
    return;
end

copyCount=min(dim,numel(flat));
row(1:copyCount)=flat(1:copyCount);
if copyCount<dim
    row(copyCount+1:end)=flat(copyCount);
end
end

function boundsVec=expandBounds(bounds,dim)
%EXPANDBOUNDS Expand scalar/vector bounds to a 1-by-dim vector.
boundsVec=double(bounds(:)');
if isempty(boundsVec)
    boundsVec=zeros(1,dim);
elseif isscalar(boundsVec)
    boundsVec=repmat(boundsVec,1,dim);
elseif numel(boundsVec)<dim
    boundsVec=[boundsVec repmat(boundsVec(end),1,dim-numel(boundsVec))];
else
    boundsVec=boundsVec(1:dim);
end
end

function anchorPoint=buildAnchorPoint(bestPosition,lbVec,ubVec,dim)
%BUILDANCHORPOINT Choose the anchor used for x1-x2 surface projection.
anchorPoint=normalizePositionRow(bestPosition,dim);
midPoint=(lbVec+ubVec)./2;
invalidMask=~isfinite(anchorPoint);
anchorPoint(invalidMask)=midPoint(invalidMask);
end

function idx=sampleIndices(totalCount,maxDisplayedPoints)
%SAMPLEINDICES Uniformly sample up to maxDisplayedPoints indices.
if totalCount<=maxDisplayedPoints
    idx=(1:totalCount)';
else
    idx=round(linspace(1,totalCount,maxDisplayedPoints))';
    idx=unique(idx,'stable');
end
end
