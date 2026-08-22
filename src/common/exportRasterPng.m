function exportRasterPng(fig,filePath,resolution,maxRasterDimension)
%EXPORTRASTERPNG Export a PNG with compatibility and bounded raster size.
%
% The raster copy is a convenience preview. Publication-quality scalable
% output is provided separately by exportVectorSvg.

if nargin<3 || isempty(resolution)
    resolution=300;
end
if nargin<4 || isempty(maxRasterDimension)
    maxRasterDimension=12000;
end

if ~isgraphics(fig,'figure')
    error('exportRasterPng:InvalidFigure', ...
        'fig must be a valid MATLAB figure handle.');
end
validateattributes(resolution,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(maxRasterDimension,{'numeric'},{'scalar','real','finite','positive'});

filePath=char(string(filePath));
[parentDir,~,extension]=fileparts(filePath);
if ~strcmpi(extension,'.png')
    error('exportRasterPng:InvalidExtension', ...
        'PNG export requires a .png file extension.');
end
if ~isempty(parentDir) && exist(parentDir,'dir')~=7
    mkdir(parentDir);
end

resolution=boundedResolution(fig,double(resolution),double(maxRasterDimension));

if exist('exportgraphics','file')==2
    try
        exportgraphics(fig,filePath,'Resolution',resolution);
        return;
    catch
        % Fall through to the legacy PNG backend.
    end
end

print(fig,filePath,'-dpng',sprintf('-r%d',round(resolution)));
end

function resolution=boundedResolution(fig,desiredResolution,maxRasterDimension)
originalUnits=get(fig,'Units');
cleanup=onCleanup(@() restoreUnits(fig,originalUnits)); %#ok<NASGU>
set(fig,'Units','pixels');
position=double(get(fig,'Position'));
figureSpan=max(position(3:4));

if ~isfinite(figureSpan) || figureSpan<=0
    resolution=desiredResolution;
    return;
end

screenPpi=double(get(groot,'ScreenPixelsPerInch'));
if ~isfinite(screenPpi) || screenPpi<=0
    screenPpi=96;
end

maxResolution=floor(maxRasterDimension*screenPpi/figureSpan);
resolution=min(desiredResolution,max(72,maxResolution));
end

function restoreUnits(fig,unitsValue)
if isgraphics(fig,'figure')
    set(fig,'Units',unitsValue);
end
end
