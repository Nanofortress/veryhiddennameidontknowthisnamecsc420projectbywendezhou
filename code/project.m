% Note to self: To Setup the environment before running...
% Run excute addpath(genpath(pwd)) on folder /code to add path, then
% run compile.m inside folder code/dmp to setup DPM. 
% Execute run('vlfeat-0.9.20/toolbox/vl_setup') on folder /code to setup 
% SIFT.


% 2.5D Occlusion Filling. (beta)

close all;
clearvars;

% Read the test images, where source is the image with occlusion, data is
% the image without occlusion.
source = imread('../data/project/source.jpg');
data = imread('../data/project/data.jpg');
recompute = 0;

% Use DPM to detect the objects (Cars). If it has not yet being detected 
% before. Results are stored in the folder /results.
if (recompute == 1 || exist('results/ds_source.mat', 'file') == 0 || ...
    exist('results/ds_data.mat', 'file') == 0)
    dataCar = getData([], [], 'detector-car');
    model = dataCar.model;
    
    % Detect object (Cars) on source image.
    
    % Resize the data image, it works better for detecting small objects in
    % DPM.
    f = 3;
    sourcer = imresize(source,f);

    % Detect car objects.
    % You may need to reduce the threshold if you want more detections.
    model.thresh = model.thresh*0.3;
    [ds, bs] = imgdetect(sourcer, model, model.thresh);
    % Non-maximum suppression to eliminate overlapping object detection.
    nms_thresh = 0.3;
    top = nms(ds, nms_thresh);
    if model.type == model_types.Grammar
        bs = [ds(:,1:4) bs];
    end
    if ~isempty(ds)
        % resize back
        ds(:, 1:end-2) = ds(:, 1:end-2)/f;
        bs(:, 1:end-2) = bs(:, 1:end-2)/f;
    end
    ds_source = ds(top, :);

    % Save ds in results folder.
    filename = sprintf('ds_source.mat');
    save(['results/' filename],'ds_source');
    
    % Detect object (Cars) on data image.

    % Resize the data image, it works better for detecting small objects in
    % DPM.
    f = 3;
    datar = imresize(data,f);

    % Detect car objects.
    % You may need to reduce the threshold if you want more detections.
    model.thresh = model.thresh*0.8;
    [ds, bs] = imgdetect(datar, model, model.thresh);
    % Non-maximum suppression to eliminate overlapping object detection.
    nms_thresh = 0.3;
    top = nms(ds, nms_thresh);
    if model.type == model_types.Grammar
        bs = [ds(:,1:4) bs];
    end
    if ~isempty(ds)
        % Resize back.
        ds(:, 1:end-2) = ds(:, 1:end-2)/f;
        bs(:, 1:end-2) = bs(:, 1:end-2)/f;
    end
    ds_data = ds(top, :);

    % Save ds in results folder.
    filename = sprintf('ds_data.mat');
    save(['results/' filename],'ds_data');

% The DPM has already been computed.    
else
    ds_source = importdata('results/ds_source.mat');
    ds_data = importdata('results/ds_data.mat');
end

% Visualize the segmented objects on source and data images.
% Note: the objects detected might be different, due to the Non-maximum 
% suppression.
figure;
image(source); 
axis image;
axis off;
showboxes(source, ds_source, 'r', 'Car');
figure;
image(data); 
axis image;
axis off;
showboxes(data, ds_data, 'r', 'Car');

% Use SIFT to find all matching key points on the two images.
source_grey = single(rgb2gray(source));
data_grey = single(rgb2gray(data));

% Extract key points and features
[F_source_grey, D_source_grey] = vl_sift(source_grey);
[F_data_grey, D_data_grey] = vl_sift(data_grey);

% Find keypoint matching pairs.
% distances is the the two smallest distance between a point in D_source_grey with all
% points in D_data_grey. Indices of indices tells which vertex in Df is being
% matched, and each indices(:, ?) tells the indices of the two smallest
% distance of D_data_grey.
[distances, indices] = pdist2(transpose(D_data_grey), transpose(D_source_grey), ...
    'euclidean', 'Smallest',2);
% matches stores the matching pair.
matches = [];
% threshold is usually 0.8
thrshold = 0.3;
for i = 1:size(indices, 2)
    smallest = distances(1, i);
    secSmallest = distances(2, i);
    matchVal = smallest/secSmallest;
    if thrshold > matchVal
        matches = [matches; i indices(1, i) matchVal];
    end
end

% matchedPoints1, and matchedPoints1 are pair of matched points pointed
% from matches.
matchedPoints1 = zeros(size(matches, 1), 2);
matchedPoints2 = zeros(size(matches, 1), 2);
for i = 1:size(matches, 1)
    currMatch = matches(i, :, :);
    matchedPoints1(i, :) = [F_source_grey(1, currMatch(1)), F_source_grey(2, currMatch(1))];
    matchedPoints2(i, :) = [F_data_grey(1, currMatch(2)), F_data_grey(2, currMatch(2))];
end
% Show the matched pairs.
figure; ax = axes;
showMatchedFeatures(source,data,matchedPoints1,matchedPoints2, ...
    'montage','Parent', ax)

% For each object detected in the data image, find 4 key points corners
% such that they are the smallest bounds of the location of the object.
for i = 1:size(ds_data, 1)
    top_left = [0 size(data, 1)];
    top_right = [size(data, 2) size(data, 1)];
    bottom_left = [0 0];
    bottom_right = [size(data, 2) 0];
    top_left_source = top_left;
    top_right_source = top_right;
    bottom_left_source = bottom_left;
    bottom_right_source = bottom_left;
    obj_max_y = ds_data(i,4);
    obj_min_y = ds_data(i,2);
    obj_max_x = ds_data(i,3);
    obj_min_x = ds_data(i,1);
    top_left_dist = abs(pdist([top_left; obj_min_x obj_max_y]));
    top_right_dist = abs(pdist([top_right; obj_max_x obj_max_y]));
    bottom_left_dist = abs(pdist([bottom_left; obj_min_x obj_min_y]));
    bottom_right_dist = abs(pdist([bottom_right; obj_max_x obj_min_y]));
    flag = [0 0 0 0];
    %{
    for j = 1:size(matchedPoints2, 1)
        curr_y = matchedPoints2(j , 2);
        curr_x = matchedPoints2(j , 1);
        if ((top_left(2) > curr_y) &&  ...
            (curr_y > obj_max_y) && ...
            (top_left(1) < curr_x) &&  ...
            (curr_x < obj_min_x))
            top_left = matchedPoints2(j, :);
            top_left_source = matchedPoints1(j, :);
        end
        if ((top_right(2) > curr_y) &&  ...
            (curr_y > obj_max_y) && ...
            (top_right(1) > curr_x) &&  ...
            (curr_x > obj_max_x))
            top_right = matchedPoints2(j, :);
            top_right_source = matchedPoints1(j, :);
        end
        if ((bottom_left(2) < curr_y) &&  ...
            (curr_y < obj_min_y) && ...
            (bottom_left(1) < curr_x) &&  ...
            (curr_x < obj_min_x))
            bottom_left = matchedPoints2(j, :);
            bottom_left_source = matchedPoints1(j, :);
        end
        if ((bottom_right(2) < curr_y) &&  ...
            (curr_y < obj_min_y) && ...
            (bottom_right(1) > curr_x) &&  ...
            (curr_x > obj_max_x))
            bottom_right = matchedPoints2(j, :);
            bottom_right_source = matchedPoints1(j,:);
        end
    end
    %}
    %{
    for j = 1:size(matchedPoints2, 1)
        curr_y = matchedPoints2(j , 2);
        curr_x = matchedPoints2(j , 1);
        if ((top_left_dist > abs(pdist([obj_min_x obj_max_y; curr_x curr_y]))) &&  ...
            (curr_y > obj_max_y) && ...
            (curr_x < obj_min_x))
            top_left = matchedPoints2(j, :);
            top_left_source = matchedPoints1(j, :);
            top_left_dist = abs(pdist([obj_min_x obj_max_y; curr_x curr_y]));
            flag(1) = 1;
        end
        if ((top_right_dist > abs(pdist([obj_max_x obj_max_y; curr_x curr_y]))) &&  ...
            (curr_y > obj_max_y) && ...
            (curr_x > obj_max_x))
            top_right = matchedPoints2(j, :);
            top_right_source = matchedPoints1(j, :);
            top_right_dist = abs(pdist([obj_max_x obj_max_y; curr_x curr_y]));
            flag(2) = 1;
        end
        if ((bottom_left_dist > abs(pdist([obj_min_x obj_min_y; curr_x curr_y]))) &&  ...
            (curr_y < obj_min_y) && ...
            (curr_x < obj_min_x))
            bottom_left = matchedPoints2(j, :);
            bottom_left_source = matchedPoints1(j, :);
            bottom_left_dist = abs(pdist([obj_min_x obj_min_y; curr_x curr_y]));
            flag(3) = 1;
        end
        if ((bottom_right_dist > abs(pdist([obj_max_x obj_min_y; curr_x curr_y]))) &&  ...
            (curr_y < obj_min_y) && ...
            (curr_x > obj_max_x))
            bottom_right = matchedPoints2(j, :);
            bottom_right_source = matchedPoints1(j,:);
            bottom_right_dist = abs(pdist([obj_max_x obj_min_y; curr_x curr_y]));
            flag(4) = 1;
        end
    end
    %}
    
    for j = 1:size(matchedPoints2, 1)
        curr_y = matchedPoints2(j , 2);
        curr_x = matchedPoints2(j , 1);
        if ((top_left_dist > abs(pdist([obj_min_x obj_max_y; curr_x curr_y]))) )
            top_left = matchedPoints2(j, :);
            top_left_source = matchedPoints1(j, :);
            top_left_dist = abs(pdist([obj_min_x obj_max_y; curr_x curr_y]));
            flag(1) = 1;
        end
        if ((top_right_dist > abs(pdist([obj_max_x obj_max_y; curr_x curr_y]))) )
            top_right = matchedPoints2(j, :);
            top_right_source = matchedPoints1(j, :);
            top_right_dist = abs(pdist([obj_max_x obj_max_y; curr_x curr_y]));
            flag(2) = 1;
        end
        if ((bottom_left_dist > abs(pdist([obj_min_x obj_min_y; curr_x curr_y])))  )
            bottom_left = matchedPoints2(j, :);
            bottom_left_source = matchedPoints1(j, :);
            bottom_left_dist = abs(pdist([obj_min_x obj_min_y; curr_x curr_y]));
            flag(3) = 1;
        end
        if ((bottom_right_dist > abs(pdist([obj_max_x obj_min_y; curr_x curr_y])))  )
            bottom_right = matchedPoints2(j, :);
            bottom_right_source = matchedPoints1(j,:);
            bottom_right_dist = abs(pdist([obj_max_x obj_min_y; curr_x curr_y]));
            flag(4) = 1;
        end
    end
    
    
    
    
    
    
    
    
    
    figure; imshow(data)
    hold on
    line([top_left(1), top_right(1), bottom_right(1), bottom_left(1), top_left(1)], ...
        [top_left(2), top_right(2), bottom_right(2), bottom_left(2), top_left(2)], ...
        'color', 'green', 'LineWidth',3) 
  
    hold off
    
    
    % Use those 4 key points and find the transformation matrix, from
    % data image to source image.
    % Construct P and Pp.
    if (~(flag(1) == 1 && flag(2) == 1 && flag(3) ==1 && flag(4) ==1))
        continue
    end
    k = 4;
    P = zeros(2*k, 6);
    Pp = zeros(2*k, 1);
    P(1, :) = [top_left(1), top_left(2), 1, 0, 0, 0];
    P(2, :) = [0, 0, 0,top_left(1), top_left(2), 1];
    P(3, :) = [top_right(1), top_right(2), 1, 0, 0, 0];
    P(4, :) = [0, 0, 0,top_right(1), top_right(2), 1];
    P(5, :) = [bottom_left(1), bottom_left(2), 1, 0, 0, 0];
    P(6, :) = [0, 0, 0,bottom_left(1), bottom_left(2), 1];
    P(7, :) = [bottom_right(1), bottom_right(2), 1, 0, 0, 0];
    P(8, :) = [0, 0, 0,bottom_right(1), bottom_right(2), 1];
    Pp(1) = top_left_source(1);
    Pp(2) = top_left_source(2);
    Pp(3) = top_right_source(1);
    Pp(4) = top_right_source(2);
    Pp(5) = bottom_left_source(1);
    Pp(6) = bottom_left_source(2);
    Pp(7) = bottom_right_source(1);
    Pp(8) = bottom_right_source(2);
    a = (inv(transpose(P)*P))*transpose(P)*Pp;
    a = reshape(a, 3,2).';
    
    % Find the centre point of the object, and project it with the
    % transformation matrix 'a' to see if the object exist in the source
    % image.
    obj_centre = [obj_min_x + (obj_max_x + obj_min_x)/2; ...
        obj_min_y + (obj_max_y + obj_min_y)/2; ...
        1];
    obj_centre_proj = a*obj_centre;
    % Check if obj_centre_proj is within any object boundaries in source
    % image. 
    has_obj_projection = 0;
    for ii = 1:size(ds_source, 1)
        obj_max_y = ds_source(ii,4);
        obj_min_y = ds_source(ii,2);
        obj_max_x = ds_source(ii,3);
        obj_min_x = ds_source(ii,1);
        if ((obj_max_x > obj_centre_proj(1)) && ...
            (obj_centre_proj(1) > obj_min_x) && ...
            (obj_max_y > obj_centre_proj(2)) && ...
            (obj_centre_proj(2) > obj_min_y))
            has_obj_projection = 1;
        end
    end
    % If not it means that there does not exist an object in
    % computer vision (meaning the object is occluded), thus we can start
    % filling the occlusion using the object in the data image.
    if has_obj_projection == 0
        obj_max_y = round(ds_data(i,4));
        obj_min_y = round(ds_data(i,2));
        obj_max_x = round(ds_data(i,3));
        obj_min_x = round(ds_data(i,1));
        for n = obj_min_x:obj_max_x
            for m = obj_min_y:obj_max_y
                pixel = [n; m; 1];
                pixel = round(a*pixel);
                source(pixel(2), pixel(1), :) = data(m, n, :);
            end
        end
    end
end

% Visualize the result.
figure; imshow(source)














% Custom function to show the rectagle boxes labeling the objects. 
% Note: this is a modified version of the function showboxes (same name) in 
%       the file code/showboxesMy.m 
function showboxes(im, boxes, col, label)
    cwidth = 2;
    if ~isempty(boxes)
          % draw the boxes with the detection window on top (reverse order)
          if 1
              %for i = numfilters:-1:1
              for i = 1:1
                    x1 = boxes(:,1+(i-1)*4);
                    y1 = boxes(:,2+(i-1)*4);
                    x2 = boxes(:,3+(i-1)*4);
                    y2 = boxes(:,4+(i-1)*4);
                    % remove unused filters
                    del = find(((x1 == 0) .* (x2 == 0) .* (y1 == 0) .* (y2 == 0)) == 1);
                    x1(del) = [];
                    x2(del) = [];
                    y1(del) = [];
                    y2(del) = [];
                    if i == 1
                      c = col; %[160/255 0 0];
                      s = '-';
                    else
                      c = 'b';
                      s = '-';
                    end
                    text(x1,y1-20,label,'Color',c,'FontSize',14)
                    line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', c, ...
                        'linewidth', cwidth, 'linestyle', s);
             end
         end
    end
end










