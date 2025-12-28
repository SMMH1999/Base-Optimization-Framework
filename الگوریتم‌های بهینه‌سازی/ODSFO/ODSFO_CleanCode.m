function [bestFitness, bestPosition, convergence] = ODSFO_CleanCode(lb, ub, dim, predatorCount, maxIter, costFcn, funcNum, funcDetails)
    %ODSFO   Optimized Sailfish–Sardine Foraging Optimization
    %   [bestFitness, bestPosition, convergence] = odsfo(lb, ub, dim, predatorCount, maxIter, costFcn, funcNum, funcDetails)
    %   Inputs:
    %     lb            – 1×dim vector of lower bounds
    %     ub            – 1×dim vector of upper bounds
    %     dim           – problem dimension
    %     predatorCount – number of sailfish (predators)
    %     maxIter       – maximum number of iterations
    %     costFcn       – handle to objective function
    %     funcNum       – (optional) function index for batched evaluators
    %     funcDetails   – (optional) additional details for some cost functions
    %
    %   Outputs:
    %     bestFitness   – best objective value found
    %     bestPosition  – 1×dim vector of best solution
    %     convergence   – 1×maxIter vector of bestFitness per iteration

    %% Validate inputs
    narginchk(6,8);
    if nargin < 7, funcNum = []; end
    if nargin < 8, funcDetails = []; end

    %% Algorithm parameters
    preyCount     = 100;
    hardLevel     = 20;
    fishScales    = hardLevel * ones(preyCount,1);
    A             = ub/2;
    epsilon       = 2;
    F             = 0.5;
    CR            = 0.9;
    convergence   = inf(1, maxIter);

    %% Initialize populations
    sailPos       = rand(populateSize(predatorCount,dim), dim).*(ub-lb) + lb;
    sardPos       = rand(preyCount,dim).*(ub-lb) + lb;

    %% Main loop
    for iter = 1:maxIter
        preyDensity = 1 - predatorCount/(predatorCount + preyCount);

        %% Enforce bounds
        sailPos = clamp(sailPos, lb, ub);
        sardPos = clamp(sardPos, lb, ub);

        %% Optional: opposition-based learning on sardines
        sardPos = applyOpposition(sardPos, lb, ub, costFcn, funcNum, funcDetails);

        %% Evaluate fitness
        sailFit = evaluate(costFcn, sailPos, funcNum, funcDetails);
        sardFit = evaluate(costFcn, sardPos, funcNum, funcDetails);

        %% Sort and select elites
        [sailFit, sIdx] = sort(sailFit);
        sailPos = sailPos(sIdx,:);
        [sardFit, dIdx] = sort(sardFit);
        sardPos = sardPos(dIdx,:);

        eliteFit = sailFit(1);    elitePos = sailPos(1,:);
        weakFit  = sardFit(1);    weakPos  = sardPos(1,:);

        if iter == 1 || eliteFit < bestFitness
            bestFitness  = eliteFit;
            bestPosition = elitePos;
        end
        convergence(iter) = bestFitness;

        %% Encircle
        for p = 1:predatorCount
            lambda = 2*rand()*preyDensity - preyDensity;
            sailPos(p,:) = elitePos ...
                - lambda*((rand()*(elitePos+weakPos)/2) - sailPos(p,:));
        end

        %% Hunt / Mutate sardines
        attackPower = A .* (1 - iter/maxIter).^epsilon;
        if all(attackPower <= 1)
            sardPos = huntPhase(sardPos, elitePos, attackPower);
        else
            sardPos = mutatePhase(sardPos, lb, ub, F, CR, costFcn, funcNum, funcDetails);
        end

        %% Predator–prey exchange
        if eliteFit > weakFit
            sailPos(1,:) = weakPos;
            sailFit(1) = weakFit;
            if fishScales(dIdx(1)) == 0
                sardPos(dIdx(1),:)   = [];
                sardFit(dIdx(1))     = [];
                fishScales(dIdx(1))  = [];
                preyCount = preyCount - 1;
                if preyCount == 0
                    warning('All sardines have been consumed.');
                    break
                end
            else
                fishScales(dIdx(1)) = fishScales(dIdx(1)) - 1;
            end
        end
    end
end

%% Helper functions

function X = clamp(X, lb, ub)
    X = min(max(X, lb), ub);
end

function fitness = evaluate(costFcn, P, funcNum, details)
    % Dispatch evaluation depending on signature
    if isempty(funcNum)
        fitness = arrayfun(@(i) costFcn(P(i,:)), 1:size(P,1));
    else
        fitness = costFcn(P', funcNum);
        fitness = fitness(:)';
    end
end

function P2 = applyOpposition(P, lb, ub, costFcn, funcNum, details)
    oppP = lb + ub - P .* rand(size(P));
    oppP = clamp(oppP, lb, ub);
    % Evaluate both and keep better
    fitP    = evaluate(costFcn, P,    funcNum, details);
    fitOpp  = evaluate(costFcn, oppP,  funcNum, details);
    keepOpp = fitOpp < fitP;
    P2 = P;
    P2(keepOpp,:) = oppP(keepOpp,:);
end

function sard = huntPhase(sard, elitePos, attackPower)
    [n, dim] = size(sard);
    alpha = mod(n * abs(attackPower),1);
    beta  = mod(dim * abs(attackPower),1);
    idxPrey = randperm(n, max(round(alpha),1));
    for i = idxPrey
        idxDim = randperm(dim, max(round(beta),1));
        sard(i, idxDim) = rand(size(idxDim)) .* ...
            (elitePos(idxDim) - sard(i,idxDim) + attackPower);
    end
end

function sard = mutatePhase(sard, lb, ub, F, CR, costFcn, funcNum, details)
    [n, dim] = size(sard);
    for i = 1:n
        idxs = randperm(n,3);
        while any(idxs==i)
            idxs = randperm(n,3);
        end
        mutant = sard(idxs(1),:) + F*(sard(idxs(2),:)-sard(idxs(3),:));
        mutant = clamp(mutant, lb, ub);

        % Binomial crossover
        jRand = randi(dim);
        trial = sard(i,:);
        mask = (rand(1,dim)<=CR);
        mask(jRand) = true;
        trial(mask) = mutant(mask);

        % Selection
        fitOrig = evaluate(costFcn, sard(i,:),  funcNum, details);
        fitTrial= evaluate(costFcn, trial,     funcNum, details);
        if fitTrial < fitOrig
            sard(i,:) = trial;
        end
    end
end
