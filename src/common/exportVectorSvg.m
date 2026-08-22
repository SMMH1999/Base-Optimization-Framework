function exportVectorSvg(fig,filePath)
%EXPORTVECTORSVG Export a figure to SVG without changing the requested format.
%
% R2025a+ first uses exportgraphics with vector content requested explicitly.
% If that route fails, or on older MATLAB releases, the helper retries with
% the painters SVG device. EPS is never substituted for SVG.

validateInputs(fig,filePath);
filePath=char(filePath);
[parentDir,~,extension]=fileparts(filePath);
if ~strcmpi(extension,'.svg')
    error('exportVectorSvg:InvalidExtension', ...
        'Output file must use the .svg extension.');
end
if ~isempty(parentDir) && exist(parentDir,'dir')~=7
    mkdir(parentDir);
end

attemptMessages={};

if ~verLessThan('matlab','25.1')
    try
        exportgraphics(fig,filePath,'ContentType','vector');
        verifyCreatedFile(filePath);
        return;
    catch caughtError
        attemptMessages{end+1}=['exportgraphics: ' caughtError.message]; %#ok<AGROW>
        deleteIfPresent(filePath);
    end
end

originalRenderer=get(fig,'Renderer');
cleanup=onCleanup(@() restoreRenderer(fig,originalRenderer)); %#ok<NASGU>
try
    set(fig,'Renderer','painters');
    print(fig,filePath,'-dsvg','-painters');
    verifyCreatedFile(filePath);
    return;
catch caughtError
    attemptMessages{end+1}=['painters/print: ' caughtError.message]; %#ok<AGROW>
    deleteIfPresent(filePath);
end

error('exportVectorSvg:ExportFailed', ...
    'Unable to export SVG "%s". Attempts: %s', ...
    filePath,strjoin(attemptMessages,' | '));
end

function validateInputs(fig,filePath)
if ~isgraphics(fig,'figure')
    error('exportVectorSvg:InvalidFigure', ...
        'fig must be a valid MATLAB figure handle.');
end
if ~(ischar(filePath) || (isstring(filePath) && isscalar(filePath)))
    error('exportVectorSvg:InvalidFilePath', ...
        'filePath must be a character vector or string scalar.');
end
end

function verifyCreatedFile(filePath)
fileInfo=dir(filePath);
if exist(filePath,'file')~=2 || isempty(fileInfo) || fileInfo.bytes<=0
    error('exportVectorSvg:EmptyOutput', ...
        'SVG export did not create a non-empty file: %s',filePath);
end
end

function restoreRenderer(fig,rendererValue)
if isgraphics(fig,'figure')
    try
        set(fig,'Renderer',rendererValue);
    catch
        % Cleanup must not mask the original export failure.
    end
end
end

function deleteIfPresent(filePath)
if exist(filePath,'file')==2
    try
        delete(filePath);
    catch
        % Best-effort cleanup only.
    end
end
end
