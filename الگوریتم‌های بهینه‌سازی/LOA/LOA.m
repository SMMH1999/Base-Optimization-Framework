function [Best_Fitness, Best_Position, Convergence_curve] = LOA( ...
    LB, UB, Dim, SearchAgents_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
% LOA  Lyrebird Optimization Algorithm, standalone implementation
%
% Inputs:
%   LB, UB              – 1×Dim vectors of lower and upper bounds
%   Dim                 – problem dimensionality
%   SearchAgents_no     – population size (number of lyrebirds)
%   Max_iter            – maximum number of iterations
%   Cost_Function       – handle to objective function
%   Function_Number     – optional extra parameter for Cost_Function
%   costFunctionDetails – function handle tag for dispatching
%
% Outputs:
%   Best_Fitness        – best cost found
%   Best_Position       – 1×Dim best solution
%   Convergence_curve   – 1×Max_iter vector of best cost per iteration

    % Algorithm parameters
    crossover_rate = 0.8;
    mutation_rate  = 0.1;
    sigma          = 0.1;

    % Initialize population
    Positions = initialization(SearchAgents_no, Dim, UB, LB);
    fitnessAll        = inf(SearchAgents_no,1);
    Convergence_curve = inf(1,Max_iter);
    Best_Fitness      = inf;
    Best_Position     = zeros(1,Dim);

    % Initial fitness evaluation
    for i = 1:SearchAgents_no
        % Boundary check
        Positions(i,:) = min(max(Positions(i,:), LB), UB);
        % Cost evaluation
        if strcmp(func2str(costFunctionDetails),'CEC_2005_Function') || ...
           strcmp(func2str(costFunctionDetails),'ProbInfo')
            fitnessAll(i) = Cost_Function(Positions(i,:));
        else
            fitnessAll(i) = Cost_Function(Positions(i,:)', Function_Number);
        end
        % Update global best
        if fitnessAll(i) < Best_Fitness
            Best_Fitness  = fitnessAll(i);
            Best_Position = Positions(i,:);
        end
    end

    % Main loop
    for t = 1:Max_iter
        % Sort and select the top half
        [fitnessAll, idx] = sort(fitnessAll);
        Positions = Positions(idx,:);
        halfPop   = floor(SearchAgents_no/2);
        Parents   = Positions(1:halfPop,:);

        % Crossover to refill population
        Offspring = Parents;
        nCross = round(crossover_rate * halfPop);
        for k = 1:nCross
            p1 = Parents(randi(halfPop),:);
            p2 = Parents(randi(halfPop),:);
            alpha  = rand;
            Offspring(end+1,:) = alpha*p1 + (1-alpha)*p2;  %#ok<AGROW>
            Offspring(end+1,:) = (1-alpha)*p1 + alpha*p2;  %#ok<AGROW>
        end
        % Trim or pad to full size
        if size(Offspring,1) > SearchAgents_no
            Positions = Offspring(1:SearchAgents_no,:);
        else
            Positions = [Offspring; initialization(SearchAgents_no-size(Offspring,1),Dim,UB,LB)];
        end

        % Mutation
        nMut = round(mutation_rate * SearchAgents_no);
        for k = 1:nMut
            idxm = randi(SearchAgents_no);
            mutant = Positions(idxm,:) + sigma*randn(1,Dim);
            Positions(idxm,:) = min(max(mutant, LB), UB);
        end

        % Evaluate and update best
        for i = 1:SearchAgents_no
            % Boundary check
            Positions(i,:) = min(max(Positions(i,:), LB), UB);
            % Cost evaluation
            if strcmp(func2str(costFunctionDetails),'CEC_2005_Function') || ...
               strcmp(func2str(costFunctionDetails),'ProbInfo')
                f = Cost_Function(Positions(i,:));
            else
                f = Cost_Function(Positions(i,:)', Function_Number);
            end
            fitnessAll(i) = f;
            if f < Best_Fitness
                Best_Fitness  = f;
                Best_Position = Positions(i,:);
            end
        end

        Convergence_curve(t) = Best_Fitness;
    end
end

%%----------------------------------------------------------------------%%
function X = initialization(N, dim, up, down)
    % Randomly initialize an N×dim matrix within [down, up]
    if isvector(up)
        X = rand(N, dim) .* (up - down) + down;
    else
        X = zeros(N, dim);
        for j = 1:dim
            X(:, j) = rand(N,1)*(up(j)-down(j)) + down(j);
        end
    end
end

%%----------------------------------------------------------------------%%
function o = Levy(d)
    % Generate a Levy flight step of length d
    beta  = 1.5;
    sigma = ( gamma(1+beta)*sin(pi*beta/2) / ...
             ( gamma((1+beta)/2)*beta*2^((beta-1)/2) ) )^(1/beta);
    u = randn(1, d)*sigma;
    v = randn(1, d);
    o = u ./ abs(v).^(1/beta);
end
