function [] = optimiser_plot(Input_plots)

    % Creating a new figure object to plot graphs in
    fig = figure('Color', 'w');
    
    % Calculates the number of separate graphs to plot
    N_plot = length(Input_plots);
    

    % Finds the graph layout closest to a square layout given the
    % number of separate graphs to plot. 
    % a - number of graphs in each row 
    % b - number of graphs in each col
    % layout is a x b
    a = round(sqrt(N_plot));
    b = ceil(N_plot/a);

    % Creates a tile object - each new axis goes into a unused tile
    % (prevents overlapping axis)
    Tile = tiledlayout(fig, a, b);

    for N = 1:N_plot
        
        % Unpacking the struct containing plotting data
        Current_N = Input_plots(N);
        x = Current_N.x;
        y = Current_N.y;
        x_label = Current_N.x_label;
        y_label = Current_N.y_label;
        Title = Current_N.Title;
        
        % Draws the next axis is in the next available tile in the graph
        % layout
        ax = nexttile(Tile);

        plot(ax, x, y, 'o'); % 'o' means each point is marked by a circle

        % Axes Formatting
        ax.FontName = 'Arial';
        ax.FontSize = 12;
        ax.LineWidth = 1.1;
        ax.TickDir = 'out';
        ax.Box = 'off';
        
        % Labels 
        xlabel(ax, x_label, 'FontSize', 12)
        ylabel(ax, y_label, 'FontSize', 12)
        title(ax, Title, 'FontSize', 13)      
    end    
end