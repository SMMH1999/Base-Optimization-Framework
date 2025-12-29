function [Min_Date, Avg_Date, Max_Date, Std_Date] = Results_Toolkit(Date)
    %% Create empty lists to calculate the minimum, average, and maximum in the data
    Min_Date = zeros(size(Date, 1), 1);
    Avg_Date = zeros(size(Date, 1), 1);
    Max_Date = zeros(size(Date, 1), 1);
    Std_Date = zeros(size(Date, 1), 1);

    %% Calculation of the minimum, average and maximum value in each row
    for row = 1 : size(Date,  1)
        counter = 0;
        Sum_Date = 0;

        %% Calculate the number of non-zero or infinite members in each column
        for column = 1 : size(Date, 2)
            if Date(row, column) ~= -1
                counter = counter + 1;
                Sum_Date = Sum_Date + Date(row, column);
            end
        end

        %% Calculation of the minimum, average and maximum value in each row according to non-zero and infinite values
        Min_Date(row) = min(Date(row, :));
        Max_Date(row) = max(Date(row, :));
        Avg_Date(row) = Sum_Date / counter;

        %% Calculation of the Std value in each row according to non-zero and infinite values
        Std_Date(row) = std(Date(row, :));
    end
end