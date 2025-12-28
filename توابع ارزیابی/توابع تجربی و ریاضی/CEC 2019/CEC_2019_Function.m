function [Lower_Bound, Upper_Bound, Dimentions] = CEC_2019_Function(Function_Number)
switch Function_Number
    case 1
        Lower_Bound = -8192;
        Upper_Bound = 8192;
        Dimentions = 9;
    case 2
        Lower_Bound = -16384;
        Upper_Bound = 16384;
        Dimentions = 16;
    case 3
        Lower_Bound = -4;
        Upper_Bound = 4;
        Dimentions = 18;
    case {4, 5, 6, 7, 8, 9, 10}
        Lower_Bound = -100;
        Upper_Bound = 100;
        Dimentions = 10;
    otherwise
        disp("Function_Number CEC 2019 Must be in range [1 10]");
end
end

