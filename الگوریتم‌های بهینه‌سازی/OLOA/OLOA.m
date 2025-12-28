function [Best_Fitness, Best_Position, Convergence_curve] = OLOA( ...
    LB, UB, Dim, SearchAgents_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
% OLOA  Opposition-based Lyrebird Optimization Algorithm, standalone
%
% Inputs:
%   LB, UB              – 1×Dim vectors of lower/upper bounds
%   Dim                 – problem dimension
%   SearchAgents_no     – population size
%   Max_iter            – max number of iterations
%   Cost_Function       – handle to objective function
%   Function_Number     – extra param for Cost_Function
%   costFunctionDetails – tag for dispatching cost calls
%
% Outputs:
%   Best_Fitness        – best cost found
%   Best_Position       – 1×Dim best solution
%   Convergence_curve   – 1×Max_iter record of best cost

    % Algorithm parameters
    crossover_rate = 0.8;
    mutation_rate  = 0.3;
    sigma          = 0.9;

    % Initialize population
    Positions        = initialization(SearchAgents_no, Dim, UB, LB);
    fitnessAll       = inf(SearchAgents_no,1);
    Convergence_curve = inf(1,Max_iter);
    Best_Fitness     = inf;
    Best_Position    = zeros(1,Dim);

    % Main loop
    for t = 1:Max_iter
        % 1) Opposition-based replacement
        [Positions, fitnessAll] = Opposite(Positions, LB, UB, ...
                                            Cost_Function, Function_Number, costFunctionDetails);

        % 2) Sort and select top half
        [fitnessAll, idx] = sort(fitnessAll);
        Positions = Positions(idx, :);
        halfPop   = floor(SearchAgents_no/2);
        Parents   = Positions(1:halfPop, :);

        % 3) Crossover to refill
        Offspring = Parents;
        nCross = round(crossover_rate * halfPop);
        for k = 1:nCross
            p1 = Parents(randi(halfPop), :);
            p2 = Parents(randi(halfPop), :);
            alpha  = rand;
            Offspring(end+1, :) = alpha*p1 + (1-alpha)*p2;   %#ok<AGROW>
            Offspring(end+1, :) = (1-alpha)*p1 + alpha*p2;   %#ok<AGROW>
        end
        % Trim or pad to full size
        if size(Offspring,1) >= SearchAgents_no
            Positions = Offspring(1:SearchAgents_no, :);
        else
            extra = initialization(SearchAgents_no - size(Offspring,1), Dim, UB, LB);
            Positions = [Offspring; extra];
        end

        % 4) Mutation
        nMut = round(mutation_rate * SearchAgents_no);
        for k = 1:nMut
            idxm   = randi(SearchAgents_no);
            mutant = Positions(idxm, :) + sigma * randn(1, Dim);
            Positions(idxm, :) = min(max(mutant, LB), UB);
        end

        % 5) Evaluate and update global best
        for i = 1:SearchAgents_no
            fitnessAll(i) = evalCost(Positions(i,:), Cost_Function, Function_Number, costFunctionDetails);
            if fitnessAll(i) < Best_Fitness
                Best_Fitness  = fitnessAll(i);
                Best_Position = Positions(i,:);
            end
        end

        Convergence_curve(t) = Best_Fitness;
    end
end

%%----------------------------------------------------------------------%%
function f = evalCost(x, Cost_Function, Function_Number, costFunctionDetails)
    % Evaluate cost with correct signature
    name = func2str(costFunctionDetails);
    if strcmp(name,'CEC_2005_Function') || strcmp(name,'ProbInfo')
        f = Cost_Function(x);
    else
        f = Cost_Function(x', Function_Number);
    end
end

%%----------------------------------------------------------------------%%
function [Pop, Fit] = Opposite(Pop, LB, UB, Cost_Function, Function_Number, costFunctionDetails)
    % Generate opposite population and select better between each pair
    N = size(Pop,1);
    Opp = LB + UB - Pop .* rand(size(Pop));
    Fit    = zeros(N,1);
    OppFit = zeros(N,1);
    for i = 1:N
        Fit(i)    = evalCost(Pop(i,:),    Cost_Function, Function_Number, costFunctionDetails);
        OppFit(i) = evalCost(Opp(i,:),    Cost_Function, Function_Number, costFunctionDetails);
        if OppFit(i) < Fit(i)
            Pop(i,:) = Opp(i,:);
            Fit(i)   = OppFit(i);
        end
    end
    % Sort for consistency
    [Fit, idx] = sort(Fit);
    Pop = Pop(idx, :);
end

%%----------------------------------------------------------------------%%
function X = initialization(N, dim, up, down)
    % Random initialization in [down, up]
    if isvector(up)
        X = rand(N, dim) .* (up - down) + down;
    else
        X = zeros(N, dim);
        for j = 1:dim
            X(:, j) = rand(N,1) * (up(j) - down(j)) + down(j);
        end
    end
end
