function [Best_Fitness, Best_Position, Convergence_curve] = WOA( ...
    LB, UB, Dim, SearchAgents_no, Max_iter, Cost_Function, Function_Number, costFunctionDetails)
% WOA  Whale Optimization Algorithm, standalone implementation
%
% Inputs:
%   LB, UB              – 1×Dim vectors of lower and upper bounds
%   Dim                 – problem dimension
%   SearchAgents_no     – number of whales
%   Max_iter            – maximum number of iterations
%   Cost_Function       – handle to objective function
%   Function_Number     – extra parameter for Cost_Function
%   costFunctionDetails – tag to dispatch cost calls
%
% Outputs:
%   Best_Fitness        – best objective value found
%   Best_Position       – 1×Dim best solution
%   Convergence_curve   – 1×Max_iter vector of best fitness per iteration

    % Algorithm constant
    b = 1;  

    % Initialization
    Positions         = initialization(SearchAgents_no, Dim, UB, LB);
    Best_Fitness      = inf;
    Best_Position     = zeros(1, Dim);
    Convergence_curve = inf(1, Max_iter);

    % Main loop
    for t = 1:Max_iter
        a = 2 - t * (2 / Max_iter);  % a decreases from 2 to 0

        % 1) Evaluate fitness and update leader
        for i = 1:SearchAgents_no
            % Enforce bounds
            Positions(i,:) = min(max(Positions(i,:), LB), UB);
            % Compute fitness
            fit = evalCost(Positions(i,:), Cost_Function, Function_Number, costFunctionDetails);
            if fit < Best_Fitness
                Best_Fitness  = fit;
                Best_Position = Positions(i,:);
            end
        end
        Convergence_curve(t) = Best_Fitness;

        % 2) Update positions of whales
        for i = 1:SearchAgents_no
            r1 = rand(); r2 = rand();
            A  = 2*a*r1 - a;
            C  = 2*r2;
            l  = -1 + 2*rand();  % in [-1,1]
            p  = rand();

            for j = 1:Dim
                if p < 0.5
                    if abs(A) >= 1
                        % Exploration: randomly select a whale
                        rand_idx = randi(SearchAgents_no);
                        X_rand   = Positions(rand_idx, :);
                        D_X_rand = abs(C * X_rand(j) - Positions(i, j));
                        Positions(i, j) = X_rand(j) - A * D_X_rand;
                    else
                        % Exploitation: encircle the leader
                        D_Leader = abs(C * Best_Position(j) - Positions(i, j));
                        Positions(i, j) = Best_Position(j) - A * D_Leader;
                    end
                else
                    % Exploitation: spiral update
                    D_Leader = abs(Best_Position(j) - Positions(i, j));
                    Positions(i, j) = D_Leader * exp(b * l) * cos(2 * pi * l) + Best_Position(j);
                end
            end
        end
    end
end

%%----------------------------------------------------------------------%%
function f = evalCost(x, Cost_Function, Function_Number, costFunctionDetails)
    % Dispatch cost evaluation based on costFunctionDetails
    name = func2str(costFunctionDetails);
    if strcmp(name, 'CEC_2005_Function') || strcmp(name, 'ProbInfo')
        f = Cost_Function(x);
    else
        f = Cost_Function(x', Function_Number);
    end
end

%%----------------------------------------------------------------------%%
function X = initialization(N, dim, UB, LB)
    % Randomly initialize an N×dim matrix within [LB, UB]
    if isvector(UB)
        X = rand(N, dim) .* (UB - LB) + LB;
    else
        X = zeros(N, dim);
        for k = 1:dim
            X(:, k) = rand(N, 1) * (UB(k) - LB(k)) + LB(k);
        end
    end
end
