function []=Saving(data,address,fileName,fileFormat,sheetName,sheetRange)
%SAVING Save data while preserving layout of existing spreadsheet templates.

if exist(address,'dir')~=7
    mkdir(address);
end

filePath=fullfile(address,[fileName '.' fileFormat]);
isSpreadsheet=any(strcmpi(fileFormat,{'xls','xlsx','xlsm','xlsb','ods'}));
isExistingTemplate=isSpreadsheet && exist(filePath,'file')==2;
supportsAutoFitControl=~verLessThan('matlab','9.9'); % R2020b+
preserveColumnWidth=isExistingTemplate && supportsAutoFitControl;

switch class(data)
    case 'cell'
        if preserveColumnWidth
            writecell(data,filePath,'Sheet',sheetName,'Range',sheetRange, ...
                'AutoFitWidth',false);
        else
            writecell(data,filePath,'Sheet',sheetName,'Range',sheetRange);
        end

    case {'double','single'}
        if preserveColumnWidth
            writematrix(data,filePath,'Sheet',sheetName,'Range',sheetRange, ...
                'AutoFitWidth',false);
        else
            writematrix(data,filePath,'Sheet',sheetName,'Range',sheetRange);
        end

    case 'table'
        if preserveColumnWidth
            writetable(data,filePath,'Sheet',sheetName,'Range',sheetRange, ...
                'AutoFitWidth',false);
        else
            writetable(data,filePath,'Sheet',sheetName,'Range',sheetRange);
        end

    otherwise
        error('Saving:UnsupportedDataType','Unsupported data type: %s',class(data));
end
end
