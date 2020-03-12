%% Select data model
% List for selection dialog box
models_selection_list = {
        '1: CHIMERE',...
        '2: EMEP',...
        '3: ENSEMBLE',...
        '4: EURAD-IM',...
        '5: LOTOS-EUROS',...
        '6: MATCH',...
        '7: MOCAGE',...
        '8: SILAM'};
% Create selection dialog box for user to choose which ensemble model
% they want to view.
% indx = index of choice (starting from 1)
% tf = whether a selection was made or user exited the box (Cancel or X)
% PromptString = the description, SelectionMode is default multiple
% Get the options with ListString from the list above (models)
[indx,tf] = listdlg('PromptString',{'Select an ensemble model.',...
    'Only one model can be viewed at a time.',''},...
    'SelectionMode','single','ListString',models_selection_list);
    
% If user did not select a model, create error dialog box to inform
% of invalid selection, then return (to stop script)
if tf == 0
    f = errordlg('No model was selected.','Invalid model.');
    return;
end

% Declare array of strings for models (simple names)
% Important: Need to be in order with the models_selection_list
model_list = ["chimere", "emep", "ensemble", "eurad","lotoseuros", ...
              "match", "mocage", "silam"];

%% Colorblind mode prompt
% Question dialog box for colorblind mode, default OFF.
colorblind = 0;
selection = questdlg("Open in Colorblind mode?",...
    'Colorblind Mode',...
    'Yes',...
    'No',...
    'No'); % default choice (if user clicks X)
switch selection
    case 'Yes'
        colorblind = 1;
    case 'No'
        colorblind = 0;
end
    
%% Load model data
% Set the data file to be used
data_file = 'combined_data.nc';
    
% Get the name of the model from the list using answer index
model_name = model_list(indx);
% Read the model ozone data from the file as double precision array
ozone_data = double(ncread(data_file, sprintf('%s_ozone', model_name)));

%% Load latitude, longitude, no. of data sets and time by hours
% Read the latitude and logitude data from the file as double prec. arr.
% and use it to determine required number of rows and columns for the
% matrix (Matrix dimensions must agree when using pcolor)
latitude = double(ncread(data_file, 'lat'));
longitude = double(ncread(data_file, 'lon'));

% Gets the number of data sets to loop through
data_sets = size(ozone_data);       % data_sets = [700, 400, 25]
data_sets = data_sets(3);           % data_sets = 25

time = ncread(data_file, 'hour');   % array of time in hours from the file

%% Create figure window 
% Capitalize the first letter of the name and set name as figure title
model_name{1}(1) = upper(model_name{1}(1));
figure_name = sprintf('%s Ozone Layer', model_name{1});

% Create figure window, set it as fullscreen.
% figure_name from above is set as the title
% NumberTitle off so only the name will appear as title (no fig. count)
% Unit of measurement = normalized - depends on parent container
% outerposition = location and size of the outer bounds
% [left bottom width height]
f1 = figure('Name', figure_name, 'NumberTitle', 'off', ...
    'units','normalized','outerposition',[0 0 1 1]);
f1.WindowState = 'maximized';         % Account for the taskbar
if colorblind == 1                    % If colorblind is set to true, 
    colormap summer;                  % adjust the colormap 
end

%% Visualization main loop
% 2-D grid coordinates based on vector X and Y coords.
% X matrix - each row is copy of X
% Y matrix - each column is copy of Y
[latitude,longitude] = meshgrid(latitude, longitude);
for t = 1 : data_sets
    % Set current figure window to 'f1' (created above)
    figure(f1)
    
    % Set figure title (for all subplots) as current model and time
    sgtitle(f1, sprintf('Model: %s - Current hour: %d', ...
    model_name{1},time(t)))
    
    %% Display the data on map                                  (subplot 1)
    % Create the map
    sp1 = subplot(12,12,[13,104]);
    worldmap('Europe');                 % set the part of the earth to show
    load coastlines
    plot(coastlat,coastlon)             % plot vs plotm?
    land = shaperead('landareas', 'UseGeoCoords', true);
    geoshow(gca, land, 'FaceColor', [0.5 0.7 0.5])
    lakes = shaperead('worldlakes', 'UseGeoCoords', true);
    geoshow(lakes, 'FaceColor', 'blue')
    rivers = shaperead('worldrivers', 'UseGeoCoords', true);
    geoshow(rivers, 'Color', 'blue')
    cities = shaperead('worldcities', 'UseGeoCoords', true);
    geoshow(cities, 'Marker', '.', 'Color', 'red')

    % Plot the data
    % edge colour outlines the edges, 'FaceAlpha', sets the transparency
    surfm(latitude, longitude, ozone_data(:,:,t), 'EdgeColor', 'none',...
        'FaceAlpha', 0.5) 

    %% Display the raw data                                     (subplot 2)
    sp2 = subplot(12,12,[21,60]);
    mesh(latitude, longitude, ozone_data(:,:,t))
    
    %% Display the contour map data                             (subplot 3)
%      sp3 = subplot(12,12,[81,120]);
%      % Create the map
%      worldmap('Europe'); % set the part of the earth to show
%      load coastlines
%      plot(coastlat,coastlon)
%      land = shaperead('landareas', 'UseGeoCoords', true);
%      geoshow(gca, land, 'FaceColor', [0.5 0.7 0.5])
%      lakes = shaperead('worldlakes', 'UseGeoCoords', true);
%      geoshow(lakes, 'FaceColor', 'blue')
%      rivers = shaperead('worldrivers', 'UseGeoCoords', true);
%      geoshow(rivers, 'Color', 'blue')
%      cities = shaperead('worldcities', 'UseGeoCoords', true);
%      geoshow(cities, 'Marker', '.', 'Color', 'red')
%  
%      % display the data
%      NumContours = 10;
%      contourfm(latitude, longitude, ozone_data(:,:,t), NumContours)
%  
%      % This is a bit advanced, sets the visibility of the various parts of the
%      % plot so the land, cities etc shows through.
%      Plots = findobj(gca,'Type','Axes');
%      Plots.SortMethod = 'depth';
end
% After all data sets were visualized, 
% Wait a few seconds then close the figure window
pause(2);  
close(f1);
