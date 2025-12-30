function [bestFitness, bestPosition, convergenceCcurve] = CMAES(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)
% CMA_ES  Covariance Matrix Adaptation Evolution Strategy
%
% [bestFitness, bestPosition, convergenceCcurve] = CMA_ES(LB, UB, Dim, popSize, maxItr, Cost_Function, Function_Number, costFunctionDetails)

    % Ensure bounds vectors
    LB_vec = icreateBoundVec(LB, Dim);
    UB_vec = icreateBoundVec(UB, Dim);

    % Strategy parameters
    lambda = popSize;
    mu     = round(lambda/2);
    w      = log(mu+0.5) - log(1:mu);
    w      = w / sum(w);
    mu_eff = 1 / sum(w.^2);

    % Step-size control
    sigma0 = 0.3 * (UB_vec - LB_vec);
    cs     = (mu_eff + 2) / (Dim + mu_eff + 5);
    ds     = 1 + cs + 2*max(sqrt((mu_eff-1)/(Dim+1))-1, 0);
    ENN    = sqrt(Dim) * (1 - 1/(4*Dim) + 1/(21*Dim^2));

    % Covariance update parameters
    cc       = (4 + mu_eff/Dim) / (4 + Dim + 2*mu_eff/Dim);
    c1       = 2 / ((Dim + 1.3)^2 + mu_eff);
    alpha_mu = 2;
    cmu      = min(1 - c1, alpha_mu * (mu_eff - 2 + 1/mu_eff) / ((Dim + 2)^2 + alpha_mu*mu_eff/2));
    hth      = (1.4 + 2/(Dim+1)) * ENN;

    % Initialize dynamic variables
    ps      = zeros(1,Dim);
    pc      = zeros(1,Dim);
    C       = eye(Dim);
    sigma   = sigma0;

    % Initial mean and best solution
    xmean   = LB_vec + (UB_vec-LB_vec).*rand(1,Dim);
    f0      = iEvalCost(xmean, LB_vec, UB_vec, Cost_Function, Function_Number, costFunctionDetails);
    bestFitness       = f0;
    bestPosition      = xmean;
    convergenceCcurve = zeros(maxItr,1);

    % Main loop
    for g = 1:maxItr
        pop   = repmat(struct('Position',[],'Step',[],'Cost',[]), lambda, 1);
        steps = mvnrnd(zeros(1,Dim), C, lambda);
        for i = 1:lambda
            pop(i).Step    = steps(i,:);
            x             = xmean + sigma .* pop(i).Step;
            x             = min(max(x, LB_vec), UB_vec);
            pop(i).Position = x;
            pop(i).Cost     = iEvalCost(x, LB_vec, UB_vec, Cost_Function, Function_Number, costFunctionDetails);
            if pop(i).Cost < bestFitness
                bestFitness  = pop(i).Cost;
                bestPosition = x;
            end
        end
        % sort
        [~, idx] = sort([pop.Cost]);
        pop      = pop(idx);
        convergenceCcurve(g) = bestFitness;
        % recombination
        xold = xmean;
        zmean = zeros(1,Dim);
        for j = 1:mu
            zmean = zmean + w(j).*pop(j).Step;
        end
        xmean   = xold + sigma .* zmean;
        xmean   = min(max(xmean, LB_vec), UB_vec);
        % update paths
        ps      = (1-cs)*ps + sqrt(cs*(2-cs)*mu_eff) * (zmean) / chol(C)';
        sigma   = sigma .* exp((cs/ds)*(norm(ps)/ENN - 1)).^0.3;
        % update cov
        hs      = norm(ps)/sqrt(1-(1-cs)^(2*g)) < hth;
        delta   = (1-hs) * cc * (2-cc);
        pc      = (1-cc)*pc + hs*sqrt(cc*(2-cc)*mu_eff).*zmean;
        C       = (1-c1-cmu)*C + c1*(pc'*pc + delta*C);
        for j = 1:mu
            C = C + cmu*w(j)*(pop(j).Step')*pop(j).Step;
        end
        % ensure PD
        C = (C+C')/2;
        [V, E] = eig(C);
        C = V*diag(max(diag(E),eps))*V';
    end
end

function v = icreateBoundVec(b, Dim)
    if isscalar(b)
        v = b*ones(1,Dim);
    else
        v = reshape(b,1,Dim);
    end
end

function f = iEvalCost(x, LB, UB, Cost_Function, Function_Number, costFunctionDetails)
    name = func2str(costFunctionDetails);
    if strcmp(name,'CEC_2005_Function') || strcmp(name,'ProbInfo')
        xnorm = (x - LB)./(UB - LB);
        xnorm = min(max(xnorm,0),1);
        f = Cost_Function(xnorm);
    else
        f = Cost_Function(x', Function_Number);
    end
end
