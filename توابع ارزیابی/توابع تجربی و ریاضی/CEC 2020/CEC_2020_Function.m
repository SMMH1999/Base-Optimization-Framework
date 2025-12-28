function [Lower_Bound, Upper_Bound, Dimensions] = CEC_2020_Function(Function_Number)
    switch Function_Number
        case {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
            Lower_Bound = -100;
            Upper_Bound = 100;
            % Dimensions can be 5, 10, 15, 20
            % (F1 : F5, F8 : F10) are in range [5, 10, 15, 20]
            % (F6, 7F) are in range [10, 15, 20]
            Dimensions = 20;
        otherwise
            disp("Function_Number CEC 2020 Must be in range [1 10]");
    end
end

