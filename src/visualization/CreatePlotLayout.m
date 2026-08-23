function layout=CreatePlotLayout(rows,cols,titleText)
    %CREATEPLOTLAYOUT Create common tiled figure layout.
    if nargin<1, rows=3; end
    if nargin<2, cols=4; end
    if nargin<3, titleText=""; end
    figure('Units','normalized','OuterPosition',[0 0 1 1]);
    layout=tiledlayout(rows,cols,'TileSpacing','compact','Padding','compact');
    if strlength(titleText)>0
        title(layout,titleText);
    end
end
