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
colorblind_mode = 0;
selection = questdlg("Open in Colorblind mode?",...
    'Colorblind Mode',...
    'Yes',...
    'No',...
    'No'); % default choice (if user clicks X)
switch selection
    case 'Yes'
        colorblind_mode = 1;
    case 'No'
        colorblind_mode = 0;
end
   
%% Contour or simple map prompt
% Question dialog box for contour (long) or simple map
contour_map = 0;
selection = questdlg([
    "For the additional map, view in simple or contour mode?" ... 
    "IMPORTANT: CONTOUR MAP MAY TAKE A LONG TIME TO DRAW."],...
    'Additional Map View Mode',...
    'Simple',...
    'Contour',...
    'Simple'); % default choice (if user clicks X)
switch selection
    case 'Contour'
        contour_map = 1;
    case 'Simple'
        contour_map = 0;
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
if colorblind_mode == 1               % If colorblind is set to true, 
    colormap summer                   % adjust the colormap 
end

%% Create directory for saving the data
% Get the date and time and convert it to a char array
d = datetime('now');
d_string = datestr(d, 'yyyy.mm.dd HH.MM.ss'); 
d_string = sprintf('%s %s', d_string, model_name{1});
% If no data history folder exists, make one
if ~exist('data_history', 'dir')
    mkdir('data_history')
end
% Set the path with the child directory as the current datetime
dir_path = fullfile('data_history', d_string);
mkdir('data_history', d_string);         % create the directory

%% Visualization main loop
% Save original lat & lon values for pcolor
orig_lat = latitude;
orig_lon = longitude;
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
    sp1 = subplot(12,12,[25,116]);
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
    
    title(sp1, 'Regional Map Data')

    %% Display the raw data                                     (subplot 2)
    sp2 = subplot(12,12,[21,60]);
    mesh(latitude, longitude, ozone_data(:,:,t))
    title(sp2, 'Raw Data Mesh')

    %% Display the contour or simple map data                   (subplot 3)
    sp3 = subplot(12,12,[81,144]);
    % Create the map
    if contour_map == 1
         title('Contour Map')
         worldmap('Europe'); % set the part of the earth to show
         load coastlines
         plot(coastlat,coastlon)
         land = shaperead('landareas', 'UseGeoCoords', true);
         geoshow(gca, land, 'FaceColor', [0.5 0.7 0.5])
         lakes = shaperead('worldlakes', 'UseGeoCoords', true);
         geoshow(lakes, 'FaceColor', 'blue')
         rivers = shaperead('worldrivers', 'UseGeoCoords', true);
         geoshow(rivers, 'Color', 'blue')
         cities = shaperead('worldcities', 'UseGeoCoords', true);
         geoshow(cities, 'Marker', '.', 'Color', 'red')

         % Display the data
         contourfm(latitude, longitude, ozone_data(:,:,t))

         % Sets the visibility of the various parts of the
         % plot so the land, cities etc shows through.
         Plots = findobj(gca,'Type','Axes');
         Plots.SortMethod = 'depth';
    else
        title(sp3, 'Simple Map')
        % Creates pseudocolor plot using the latitude and longitude
        % as x & y coordinates for vertices, and the current data set
        % as the matrix with the values
        % A copy of the transposed data matrix is used for pcolor
        % (rows and cols swapped), in order for the simple map to 
        % display correctly
        transposed_data = ozone_data(:,:,t)';
        showmap = pcolor(orig_lon,orig_lat,transposed_data);
        showmap.EdgeAlpha = 0;        % sets edge line to max transparency

        % get long and lat variables for plotting the region's map
        load coast;

        % retains plots in the current axes so that 
        % new plots added to the axes do not delete existing plots
        hold on;
        plot(long, lat, 'k')

        showmap;
    end
    %% Save data to files
    % Capture the figure (screenshot) data, then write the image data to
    % the specified file
    fig_capture = getframe(f1);
    file = fullfile(dir_path, sprintf('%d.png',t));
    imwrite(fig_capture.cdata, file)
end
% After all data sets were visualized, 
% Wait a few seconds then close the figure window
pause(2);  
close(f1);
