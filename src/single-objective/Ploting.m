function [] = Ploting(benchmarkResults, maxItr, maxRun, algorithmFileAddress, cecName, dim)
    %% Initialization
    % Supported CEC benchmark years
    cecNames = ["2005","2014","2017","2019","2020","2022"];

    % Load algorithm names from file
    [algorithmsName, ~] = Get_algorithm(algorithmFileAddress);

    % Convert numeric dimension to string if necessary
    if isnumeric(dim)
        dim = num2str(dim);
    end

    %% Determine versioned plot directory (centralized)
    ctx = ProjectContext('get');

    % Safely get CEC name as string scalar
    cecStr = char(string(cecNames(cecName)));

    % Normalize plot subfolder from dim
    dimTag  = dimTagFromInput(dim);
    plotSub = plotSubFromDimTag(dimTag);

    plotDir = fullfile(ctx.resultsRoot, ['CEC' cecStr], plotSub);
% Ensure plotDir is a simple 1D char vector
    plotDir = char(plotDir(:)');  % row vector

    % Create directory if it doesn't exist
    if ~exist(plotDir, 'dir')
        mkdir(plotDir);
    end

    % Plot grid configuration
    subplotRows    = 4; % Number of subplot rows per figure
    subplotCols    = 4; % Number of subplot columns per figure
    plotsPerFigure = subplotRows * subplotCols; % Total plots per figure
    figureCounter  = 1; % Tracks figure numbering
    plotHandles       = []; % Stores plot handles for legend
    legendEntries     = algorithmsName; % Legend labels
    insetIterationCount = 5; % Number of final iterations shown in the zoom inset
    overlapTolerance = 0.08; % Endpoint distance considered visually indistinguishable on the main axis
    logScaleThreshold = 1e3; % Minimum positive dynamic range for logarithmic scaling

    %% Plotting Loop
    totalFuncs = size(benchmarkResults, 2); % Number of benchmark functions
    for funcIdx = 1:totalFuncs
        tableResult = benchmarkResults(:, funcIdx); % Results for this function

        % Skip special case: CEC 2017, F2 (index 3, func 2)
        if ~(cecName == 3 && funcIdx == 2)
            % Adjust index for CEC 2017 (skipping F2)
            adjIdx = funcIdx;
            if cecName == 3 && funcIdx > 2
                adjIdx = funcIdx - 1;
            end

            % Create new figure if starting a new batch of plots
            if mod(adjIdx-1, plotsPerFigure) == 0
                if adjIdx > 1
                    % Save and close previous figure
                    finalizeFigure(plotDir, figureCounter, cecNames(cecName), plotHandles, legendEntries);
                    figureCounter = figureCounter + 1;
                end
                % Create a new figure for the next batch of subplots
                figure('Units','normalized','OuterPosition',[0 0 1 1]);
                plotHandles = [];
            end

            % Create subplot for current function
            subplotIndex = mod(adjIdx-1, plotsPerFigure) + 1;
            mainAx = subplot(subplotRows, subplotCols, subplotIndex);
            hold(mainAx, 'on');

            % Collect mean curves before plotting to determine a suitable y-axis scale
            algorithmCount = size(benchmarkResults, 1);
            meanCurves = nan(maxItr, algorithmCount);
            for alg = 1:algorithmCount
                dataMat = tableResult{alg};
                meanCurves(:, alg) = dataMat(1:maxItr, maxRun+1);
            end

            useLogScale = shouldUseLogScale(meanCurves, logScaleThreshold);
            currentHandles = [];

            % Plot results for each algorithm
            for alg = 1:algorithmCount
                meanCurve = meanCurves(:, alg);

                % Line style: algorithms >= 8 use dashed-dot lines
                if alg >= 8
                    style = '-.';
                else
                    style = '-';
                end

                h = plot(mainAx, 1:maxItr, meanCurve, 'LineStyle', style, 'LineWidth', 1);
                currentHandles(end+1) = h; %#ok<AGROW>

                % Capture plot handles from the first subplot of each figure
                if subplotIndex == 1
                    plotHandles(end+1) = h; %#ok<AGROW>
                end
            end

            if useLogScale
                set(mainAx, 'YScale', 'log');
            else
                set(mainAx, 'YScale', 'linear');
            end

            % Apply consistent scientific frame formatting.
            grid(mainAx,'on');
            box(mainAx,'on');
            mainAx.GridAlpha = 0.15;

            % Set subplot title and axis labels

            %
            % TODO: Improve axis labeling rules (e.g., left column & last row only).
            %
            %

            title(mainAx, sprintf('CEC%s - F%d', cecNames(cecName), funcIdx));
            xlabel(mainAx, 'Iteration');
            ylabel(mainAx, 'Fitness');
            hold(mainAx, 'off');

            % Zoom only the terminal group that is visually indistinguishable on the main axes
            addOverlapInset(mainAx, meanCurves, currentHandles, maxItr, insetIterationCount, overlapTolerance);
        end
    end

    % Finalize the last figure after loop ends
    finalizeFigure(plotDir, figureCounter, cecNames(cecName), plotHandles, legendEntries);
end

function [] = finalizeFigure(path, figureCounter, cecName, plotHandles, legendEntries)
    % FINALIZEFIGURE
    % Adds legend, sets title, and saves the figure to disk.
    %
    % Inputs:
    %   path          - Output directory
    %   figureCounter - Current figure index
    %   cecName       - CEC benchmark year
    %   plotHandles   - Handles to plotted curves
    %   legendEntries - Labels for legend entries

    % Create a horizontal legend below the plots
    hL = legend(plotHandles, legendEntries, 'Orientation','horizontal','Location','none');
    set(hL, 'Position',[0.175,0.015,0.68,0.03],'Units','normalized');

    % Add a fixed figure-level title without triggering axes re-layout.
    % sgtitle changes subplot geometry after inset axes are created.
    annotation(gcf,'textbox',[0 0.965 1 0.03], ...
        'String',sprintf('CEC Benchmark Functions %s', cecName), ...
        'EdgeColor','none','HorizontalAlignment','center', ...
        'FontWeight','bold');

    % Save a pure-vector SVG when supported (EPS fallback otherwise) plus a raster JPG preview.
    exportVectorSvg(gcf, fullfile(path, sprintf('CEC_Plots%d.svg', figureCounter)));
    saveas(gcf, fullfile(path, sprintf('CEC_Plots%d.jpg', figureCounter)));

    % Close figure to free memory
    close(gcf);
end


% ===== Helper functions =====
function tf = shouldUseLogScale(curveData, dynamicRangeThreshold)
%SHOULDUSELOGSCALE Select log scale only for strictly positive wide-range data.
    values = curveData(isfinite(curveData));

    if isempty(values) || any(values <= 0)
        tf = false;
        return;
    end

    minValue = min(values);
    maxValue = max(values);
    tf = (maxValue / minValue) >= dynamicRangeThreshold;
end

function addOverlapInset(mainAx, curveData, lineHandles, maxItr, iterationCount, overlapTolerance)
%ADDOVERLAPINSET Zoom the terminal cluster that overlaps visually on the main axes.
    if maxItr < 1 || isempty(curveData) || isempty(lineHandles)
        return;
    end

    selectedAlgorithms = findTerminalOverlap(mainAx, curveData, overlapTolerance);
    if numel(selectedAlgorithms) < 2
        return;
    end

    tailStart = max(1, maxItr-iterationCount+1);
    tailX = tailStart:maxItr;
    tailData = curveData(tailX, selectedAlgorithms);

    % Resolve pending graphics layout before computing inset position.
    drawnow;

    originalUnits = get(mainAx, 'Units');
    set(mainAx, 'Units', 'normalized');
    mainPosition = get(mainAx, 'Position');
    set(mainAx, 'Units', originalUnits);

    insetPosition = [mainPosition(1)+0.54*mainPosition(3), ...
        mainPosition(2)+0.53*mainPosition(4), ...
        0.42*mainPosition(3), 0.39*mainPosition(4)];

    parentFigure = ancestor(mainAx, 'figure');
    insetAx = axes('Parent', parentFigure, 'Units', 'normalized', ...
        'Position', insetPosition, 'Box', 'on', 'FontSize', 5, 'LineWidth', 0.6);
    hold(insetAx, 'on');

    for idx = 1:numel(selectedAlgorithms)
        alg = selectedAlgorithms(idx);
        lineColor = get(lineHandles(alg), 'Color');
        lineStyle = get(lineHandles(alg), 'LineStyle');
        plot(insetAx, tailX, tailData(:, idx), ...
            'Color', lineColor, ...
            'LineStyle', lineStyle, ...
            'LineWidth', 1);
    end

    set(insetAx, 'YScale', 'linear', 'XTick', tailX);
    xlim(insetAx, tailXLimits(tailStart, maxItr));
    setTightYLimits(insetAx, tailData);
    title(insetAx, 'Final overlap', 'FontSize', 6);
    hold(insetAx, 'off');
end

function selectedAlgorithms = findTerminalOverlap(mainAx, curveData, overlapTolerance)
%FINDTERMINALOVERLAP Find the densest visually indistinguishable endpoint cluster.
    finalValues = curveData(end, :);
    finiteMask = isfinite(finalValues);
    selectedAlgorithms = [];

    if nnz(finiteMask) < 2
        return;
    end

    yScale = get(mainAx, 'YScale');
    yLimits = get(mainAx, 'YLim');

    if strcmpi(yScale, 'log')
        finiteMask = finiteMask & finalValues > 0;
        if nnz(finiteMask) < 2 || any(yLimits <= 0)
            return;
        end
        displayValues = log10(finalValues);
        displayLimits = log10(yLimits);
    else
        displayValues = finalValues;
        displayLimits = yLimits;
    end

    axisSpan = displayLimits(2)-displayLimits(1);
    if ~isfinite(axisSpan) || axisSpan <= 0
        return;
    end

    validAlgorithms = find(finiteMask);
    validValues = displayValues(finiteMask);
    normalizedValues = (validValues-displayLimits(1)) ./ axisSpan;
    [sortedValues, order] = sort(normalizedValues);

    bestStart = 1;
    bestEnd = 1;
    bestCount = 1;
    bestMean = inf;
    left = 1;

    for right = 1:numel(sortedValues)
        while sortedValues(right)-sortedValues(left) > overlapTolerance
            left = left + 1;
        end

        currentCount = right-left+1;
        currentMean = mean(sortedValues(left:right));
        if currentCount > bestCount || (currentCount == bestCount && currentMean < bestMean)
            bestStart = left;
            bestEnd = right;
            bestCount = currentCount;
            bestMean = currentMean;
        end
    end

    if bestCount >= 2
        selectedAlgorithms = validAlgorithms(order(bestStart:bestEnd));
    end
end

function limits = tailXLimits(tailStart, maxItr)
%TAILXLIMITS Return valid x-axis limits for the tail inset.
    if tailStart == maxItr
        limits = [maxItr-0.5, maxItr+0.5];
    else
        limits = [tailStart, maxItr];
    end
end

function setTightYLimits(ax, data)
%SETTIGHTYLIMITS Apply padded linear limits using finite tail values only.
    values = data(isfinite(data));
    if isempty(values)
        return;
    end

    minValue = min(values);
    maxValue = max(values);

    if minValue == maxValue
        padding = max(0.05*abs(minValue), eps(max(abs(minValue), 1)));
    else
        padding = 0.08 * (maxValue-minValue);
    end

    ylim(ax, [minValue-padding, maxValue+padding]);
end

function tag = dimTagFromInput(dimVal)
%DIMTAGFROMINPUT Normalize dimension tag for folder naming.
    if isnumeric(dimVal)
        if isempty(dimVal) || dimVal == 0
            tag = 'fixDim';
        else
            tag = sprintf('%dDim', dimVal);
        end
        return;
    end

    s = lower(string(dimVal));
    s = strtrim(s);

    if s == "fix" || s == "fixdim"
        tag = 'fixDim';
    elseif endsWith(s, "dim")
        tag = char(s);
    else
        tag = char(s + "Dim");
    end
end

function sub = plotSubFromDimTag(dimTag)
%PLOTSUBFROMDIMTAG Map dimension tag to plot subfolder name.
%   '10Dim' -> 'Plot_10'
%   'fixDim'-> 'Plot_fix'
    s = lower(string(dimTag));
    if s == "fixdim"
        sub = 'Plot_fix';
    else
        numStr = regexprep(string(dimTag), "Dim", "");
        sub = char("Plot_" + numStr);
    end
end