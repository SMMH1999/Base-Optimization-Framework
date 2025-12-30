function [Lower_Bound, Upper_Bound, Dimensions] = CEC_2022_Function(Function_Number)
    switch Function_Number
        case {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
            Lower_Bound = -100;
            Upper_Bound = 100;
            % Dimensions can be 2, 10, 20
            Dimensions = 20;
        otherwise
            disp("Function_Number CEC 2022 Must be in range [1 12]");
    end
end

