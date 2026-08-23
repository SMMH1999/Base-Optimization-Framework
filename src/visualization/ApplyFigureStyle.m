function ApplyFigureStyle()
    %APPLYFIGURESTYLE Apply shared axes formatting.
    ax=findall(gcf,'Type','axes');
    set(ax,'FontSize',PlotConfig().fontSize);
end
