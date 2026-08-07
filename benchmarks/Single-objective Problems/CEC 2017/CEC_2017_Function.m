function [Lower_Bound, Upper_Bound, Dimensions] = CEC_2017_Function(Function_Number)
switch Function_Number
    case {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30}
        Lower_Bound = -100;
        Upper_Bound = 100;
        % Dimensions can be 10, 30, 50, 100
        Dimensions = 10;
    otherwise
        disp("Function_Number CEC 2017 Must be in range [1 30]");
end
end

