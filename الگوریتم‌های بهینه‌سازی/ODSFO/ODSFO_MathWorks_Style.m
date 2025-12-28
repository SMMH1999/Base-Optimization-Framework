function [bestFitness, bestPosition, convergence] = ODSFO_MathWorks_Style(lb, ub, dim, predatorCount, maxIter, costFcn, funcNum, funcDetails)
    % ODSFO  Sailfish–Sardine Foraging Optimization (detailed, commented)
    %
    %   Reference:
    %     — [Paper Title], [Authors], [Year].
    %
    %   Usage example:
    %     lb = -100*ones(1,30);
    %     ub =  100*ones(1,30);
    %     [bf, bp, cc] = odsfo(lb, ub, 30, 10, 500, @myObjective, 1, []);
    %
    %   Input parameters
    %     lb            Lower bound vector (1×dim)
    %     ub            Upper bound vector (1×dim)
    %     dim           Dimensionality of the problem
    %     predatorCount Number of sailfish (predators)
    %     maxIter       Maximum number of iterations
    %     costFcn       Function handle to objective evaluator
    %     funcNum       (Optional) Numeric code for evaluator variants
    %     funcDetails   (Optional) Extra details for certain cost functions
    %
    %   Outputs
    %     bestFitness   Best cost found
    %     bestPosition  Location of best solution
    %     convergence   Convergence curve over iterations

    narginchk(6,8);
    if nargin < 7, funcNum = []; end
    if nargin < 8, funcDetails = []; end

    % Parameters
    preyCount   = 100;          % Number of sardines
    hardLevel   = 20;           % Initial fish scale threshold
    fishScales  = hardLevel * ones(preyCount,1);
    A           = ub/2;         % Maximum attack power
    epsilon     = 2;            % Exponent for attack decay
    F           = 0.5;          % Differential mutation factor
    CR          = 0.9;          % Crossover probability
    convergence = inf(1, maxIter);

    % Initialize sailfish (predators) positions and sardines (prey)
    sailPos = rand(predatorCount, dim).*(ub-lb) + lb;
    sardPos = rand(preyCount, dim).*(ub-lb) + lb;

    % Main optimization loop
    for iter = 1:maxIter
        % Compute prey density ratio
        preyDensity = 1 - predatorCount/(predatorCount + preyCount);

        % Keep agents within search bounds
        sailPos = max(min(sailPos, ub), lb);
        sardPos = max(min(sardPos, ub), lb);

        % Opposition-based learning step on sardines
        sardPos = oppositeLearning(sardPos, lb, ub, costFcn, funcNum, funcDetails);

        % Evaluate fitness for both populations
        sailFit = evaluateCost(sailPos, costFcn, funcNum, funcDetails);
        sardFit = evaluateCost(sardPos, costFcn, funcNum, funcDetails);

        % Sort by fitness ascending
        [sailFit, iS] = sort(sailFit);
        sailPos        = sailPos(iS,:);
        [sardFit, iD] = sort(sardFit);
        sardPos        = sardPos(iD,:);

        % Extract elite (best predator) and the weakest sardine
        bestPredFit  = sailFit(1); bestPredPos  = sailPos(1,:);
        worstSardFit = sardFit(1); worstSardPos = sardPos(1,:);

        % Update global best
        if iter == 1 || bestPredFit < bestFitness
            bestFitness  = bestPredFit;
            bestPosition = bestPredPos;
        end
        convergence(iter) = bestFitness;

        % Encircling update for sailfish
        for p = 1:predatorCount
            lambda = 2*rand()*preyDensity - preyDensity;
            sailPos(p,:) = bestPredPos ...
                - lambda * ((rand()*(bestPredPos+worstSardPos)/2) - sailPos(p,:));
        end

        % Hunting or mutation phase for sardines
        attackPower = A .* (1 - iter/maxIter).^epsilon;
        if all(attackPower <= 1)
            sardPos = huntingPhase(sardPos, bestPredPos, attackPower);
        else
            sardPos = mutationPhase(sardPos, lb, ub, F, CR, costFcn, funcNum, funcDetails);
        end

        % Predator–prey competition
        if bestPredFit > worstSardFit
            sailPos(1,:) = worstSardPos;   % predator replaced by sardine
            sailFit(1)  = worstSardFit;
            if fishScales(iD(1)) == 0
                % Remove eaten sardine
                sardPos(iD(1),:)  = [];
                sardFit(iD(1))    = [];
                fishScales(iD(1)) = [];
                preyCount = preyCount - 1;
                if preyCount == 0
                    disp('All sardines have been consumed.');
                    break;
                end
            else
                fishScales(iD(1)) = fishScales(iD(1)) - 1;
            end
        end
    end
end

%% --- Subfunctions --------------------------------------------------------

function newPop = oppositeLearning(pop, lb, ub, costFcn, funcNum, details)
    % Generate opposite population and keep whichever is better
    oppPop = lb + ub - pop.*rand(size(pop));
    oppPop = max(min(oppPop, ub), lb);
    fitPop = evaluateCost(pop, costFcn, funcNum, details);
    fitOpp = evaluateCost(oppPop, costFcn, funcNum, details);
    mask   = fitOpp < fitPop;
    newPop = pop;
    newPop(mask,:) = oppPop(mask,:);
end

function fitness = evaluateCost(pop, costFcn, funcNum, details)
    % Evaluate cost for each row of pop
    n = size(pop,1);
    fitness = zeros(1,n);
    if isempty(funcNum)
        for i = 1:n
            fitness(i) = costFcn(pop(i,:));
        end
    else
        fitness = costFcn(pop', funcNum);
        fitness = fitness(:)';
    end
end

function sard = huntingPhase(sard, elitePos, attackPower)
    [n, d] = size(sard);
    alpha = mod(n*abs(attackPower), 1);
    beta  = mod(d*abs(attackPower), 1);
    preyIdx = randperm(n, max(round(alpha),1));
    for i = preyIdx
        dims   = randperm(d, max(round(beta),1));
        sard(i,dims) = rand(size(dims)) .* ...
            (elitePos(dims) - sard(i,dims) + attackPower);
    end
end

function sard = mutationPhase(sard, lb, ub, F, CR, costFcn, funcNum, details)
    [n, d] = size(sard);
    for i = 1:n
        idxs = randperm(n,3);
        while any(idxs==i), idxs = randperm(n,3); end
        mutant = sard(idxs(1),:) + F*(sard(idxs(2),:)-sard(idxs(3),:));
        mutant = max(min(mutant, ub), lb);
        jRand  = randi(d);
        trial  = sard(i,:);
        mask   = (rand(1,d)<=CR);
        mask(jRand) = true;
        trial(mask) = mutant(mask);
        if evaluateCost(trial, costFcn, funcNum, details) ...
                < evaluateCost(sard(i,:), costFcn, funcNum, details)
            sard(i,:) = trial;
        end
    end
end
