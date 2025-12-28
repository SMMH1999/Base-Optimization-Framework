function [] = Saving(data, address, fileName, fileFormat, sheetName, sheetRange)
    %SAVING Saves data to a specified file in various formats.
    %
    %   SAVING(DATA, ADDRESS, FILENAME, FILEFORMAT, SHEETNAME, SHEETRANGE)
    %   saves the input DATA to a file at the specified ADDRESS, with the
    %   given FILENAME, FILEFORMAT, SHEETNAME, and SHEETRANGE.
    %
    %   INPUTS:
    %       DATA        - Data to be saved (cell array, numeric matrix, or table)
    %       ADDRESS     - Directory path where the file should be saved
    %       FILENAME    - Name of the output file (without extension)
    %       FILEFORMAT  - File extension/format (e.g., 'xlsx', 'csv')
    %       SHEETNAME   - Name of the worksheet (for spreadsheet formats)
    %       SHEETRANGE  - Cell range to write data into (e.g., 'A1')
    %
    %   NOTES:
    %       - If the target directory does not exist, it will be created.
    %       - Supports saving cell arrays, numeric matrices, and tables.
    %       - Ensure that FILEFORMAT is compatible with the write function used.
    %
    %   EXAMPLE:
    %       Saving(myTable, 'C:\Data', 'Results', 'xlsx', 'Sheet1', 'A1');
    %
    %   Author: [Your Name]
    %   Date:   [Date]
    %   ----------------------------------------------------------------------

    %% Create target directory if it doesn't exist
    % Check if the folder exists; if not, create it
    if ~exist(address, 'dir')
        mkdir(address); % Create the directory
    end

    %% Construct full file path
    % Use fullfile for platform-independent path creation
    filePath = fullfile(address, strcat(fileName, '.', fileFormat));

    %% Determine data type and save accordingly
    % The saving function is chosen based on the class of the input data
    switch class(data)
        case 'cell' % If data is a cell array
            writecell(data, filePath, "Sheet", sheetName, "Range", sheetRange);

        case {'double', 'single'} % Numeric matrices (double or single precision)
            writematrix(data, filePath, "Sheet", sheetName, "Range", sheetRange);

        case 'table' % If data is a MATLAB table
            writetable(data, filePath, "Sheet", sheetName, "Range", sheetRange);

        otherwise % Unsupported data types
            error('Unsupported data type: %s', class(data));
    end

end
