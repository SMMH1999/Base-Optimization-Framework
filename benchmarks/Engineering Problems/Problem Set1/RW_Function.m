function [LB, UB, Dim] = RW_Function(functionNo)
% Returns bounds & dimension for RW problems, compatible with RunBenchmarkSuite.

    [Dim, LB, UB] = ProbInfo(functionNo);

    % Ensure row vectors (some algorithms prefer 1xD)
    LB = LB(:).';
    UB = UB(:).';
end
