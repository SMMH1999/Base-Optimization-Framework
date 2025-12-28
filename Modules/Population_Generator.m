function Population = Population_Generator(SearchAgents_no, Dim, UB, LB)
    %% Initialize the positions of search agents

    %% Single Objective Bound
    if size(UB, 2) == 1
        Population = rand(SearchAgents_no, Dim) .* (UB - LB) + LB;
    end

    %% Multiple Objective Bound
    if size(UB, 2) > 1
        for i = 1 : Dim
            UB_i = UB(i);
            LB_i = LB(i);
            Population(:, i) = rand(SearchAgents_no, 1) .* (UB_i - LB_i) + LB_i;
        end
    end
end