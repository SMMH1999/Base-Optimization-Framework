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

    %% Determine project root and set plot directory
    scriptPath  = mfilename('fullpath'); % Path to this script
    moduleDir   = fileparts(scriptPath); % Directory containing this script
    projectDir  = fileparts(moduleDir);  % Parent directory (project root)

    % Safely get CEC name as string scalar
    if isstring(cecNames(cecName)) || ischar(cecNames(cecName))
        cecStr = char(cecNames(cecName));
    else
        error('cecNames(%d) is not a valid string or char.', cecName);
    end

    % Build final plot directory path
    plotDir = fullfile(projectDir, 'results', strcat('CEC', cecStr), strcat('Plot_', num2str(dim)));


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
    plotHandles    = []; % Stores plot handles for legend
    legendEntries  = algorithmsName; % Legend labels

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
            subplot(subplotRows, subplotCols, mod(adjIdx-1, plotsPerFigure) + 1);
            hold on;

            % Plot results for each algorithm
            for alg = 1:size(benchmarkResults, 1)
                dataMat   = tableResult{alg}; % Matrix of results for current algorithm
                meanCurve = dataMat(1:maxItr, maxRun+1); % Mean performance curve

                % Line style: algorithms >= 8 use dashed-dot lines
                if alg >= 8
                    style = '-.';
                else
                    style = '-';
                end

                % Plot curve using semilogarithmic y-axis
                h = semilogy(1:maxItr, meanCurve, 'LineStyle', style, 'LineWidth', 1);

                % Capture plot handle for legend in the first subplot of each figure
                if adjIdx == 1
                    plotHandles(end+1) = h;
                end
            end

            % Set subplot title and axis labels

            %
            %   یادم باشه این بخش رو بعدا جوری اصلاح کنم که برای ستون سمت
            %   چپ و سطر اخر فقط اینا رو قرار بده.
            %

            title(sprintf('CEC%s - F%d', cecNames(cecName), funcIdx));
            xlabel('Iteration');
            ylabel('Fitness');
            hold off;
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
    hL = legend(plotHandles, legendEntries, 'Orientation','horizontal','Location','southoutside');
    set(hL, 'Position',[0.175,0.015,0.68,0.03],'Units','normalized');

    % Add a shared title for the figure
    sgtitle(sprintf('CEC Benchmark Functions %s', cecName));

    % Save figure in SVG and JPG formats
    saveas(gcf, fullfile(path, sprintf('CEC_Plots%d.svg', figureCounter)));
    saveas(gcf, fullfile(path, sprintf('CEC_Plots%d.jpg', figureCounter)));

    % Close figure to free memory
    close(gcf);
end
