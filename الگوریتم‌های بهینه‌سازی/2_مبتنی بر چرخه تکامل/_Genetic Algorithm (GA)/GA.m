function [bestFitness, bestPosition, convergenceCcurve] = GA(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)
    % GA_Original  Simple Genetic Algorithm (Goldberg‑style, 1‑point crossover, uniform mutation, elitism)
    %   Implements the canonical GA introduced by Goldberg (1989) adapted to
    %   continuous variables (real coding) but *without* SBX/Polynomial operators.
    %   Selection is Roulette‑Wheel on **rank‑based fitness** to suit
    %   minimisation problems. One elite individual is preserved each
    %   generation.
    % -------------------------------------------------------------------------

    %% --- Parameters --------------------------------------------------------
    pc         = 0.8;          % crossover probability
    pm         = 0.01;         % mutation probability per gene
    eliteCnt   = 1;            % keep best chromosome

    % Vectorise bounds
    if isscalar(LB), LB = LB*ones(1,Dim); end
    if isscalar(UB), UB = UB*ones(1,Dim); end

    convergenceCcurve = inf(1,maxItr);
    fitness           = inf(popSize,1);

    %% --- Cost wrapper ------------------------------------------------------
    evalCostFn = @(x) evalCost(x, Cost_Function, Function_Number, costFunctionDetails);

    %% --- Initial population ------------------------------------------------
    pop = rand(popSize,Dim) .* (UB-LB) + LB;

    %% --- Evaluate ----------------------------------------------------------
    for i=1:popSize
        fitness(i) = evalCostFn(pop(i,:));
    end
    [fitness,ord] = sort(fitness); pop = pop(ord,:);
    bestFitness   = fitness(1); bestPosition = pop(1,:);

    %% --- Main loop ---------------------------------------------------------
    for t = 1:maxItr
        convergenceCcurve(t) = bestFitness;

        %% ---- Elitism ------------------------------------------------------
        elites = pop(1:eliteCnt,:);

        %% ---- Selection (Roulette on rank) ---------------------------------
        ranks       = popSize - (1:popSize)' + 1;   % best rank = popSize
        selProb     = ranks / sum(ranks);
        cumProb     = cumsum(selProb);
        matingPool  = zeros(popSize-eliteCnt, Dim);
        for k=1:size(matingPool,1)
            r = rand; idx = find(cumProb>=r,1,'first');
            matingPool(k,:) = pop(idx,:);
        end

        %% ---- Crossover (1‑point) -----------------------------------------
        offspring = matingPool;
        for i=1:2:size(matingPool,1)-1
            if rand < pc
                cp = randi([1,Dim-1]);
                offspring(i,cp+1:end)   = matingPool(i+1,cp+1:end);
                offspring(i+1,cp+1:end) = matingPool(i,cp+1:end);
            end
        end

        %% ---- Mutation (Uniform) ------------------------------------------
        for i=1:size(offspring,1)
            for j=1:Dim
                if rand < pm
                    offspring(i,j) = LB(j) + rand*(UB(j)-LB(j));
                end
            end
        end

        %% ---- Form next generation ---------------------------------------
        pop = [elites; offspring];

        %% ---- Clip bounds, evaluate --------------------------------------
        pop = max(min(pop,UB),LB);
        for i=1:popSize
            fitness(i) = evalCostFn(pop(i,:));
        end
        [fitness,ord] = sort(fitness); pop = pop(ord,:);

        %% ---- Update global best -----------------------------------------
        if fitness(1) < bestFitness
            bestFitness  = fitness(1);
            bestPosition = pop(1,:);
        end
    end

    convergenceCcurve = cummin(convergenceCcurve);
end
