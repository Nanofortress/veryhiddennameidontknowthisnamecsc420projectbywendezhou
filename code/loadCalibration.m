function [veloToCam, K, calib] = loadCalibration(calibfile)
% LOADCALIBRATION provides all needed coordinate system transformations
% returns the pre-computed velodyne to cam (gray and color) projection

% get the velodyne to camera calibration
%Tr_velo_to_cam = loadCalibrationRigid(fullfile(dir,'calib_velo_to_cam.txt'));

% get the camera intrinsic and extrinsic calibration
calib = loadCalib(calibfile);
if isfield(calib, 'Tr_velo_to_cam')
Tr_velo_to_cam = calib.Tr_velo_to_cam;
Tr_velo_to_cam(4,:) = [0,0,0,1];

% create 4x4 matrix from rectifying rotation matrix 
R_rect00 = calib.R_rect{1};
R_rect00(4,4) = 1;

% compute extrinsics from first to i'th rectified camera
T0 = eye(4); T0(1,4) = calib.P_rect{1}(1,4)/calib.P_rect{1}(1,1);
T1 = eye(4); T1(1,4) = calib.P_rect{2}(1,4)/calib.P_rect{2}(1,1);
T2 = eye(4); T2(1,4) = calib.P_rect{3}(1,4)/calib.P_rect{3}(1,1);
T3 = eye(4); T3(1,4) = calib.P_rect{4}(1,4)/calib.P_rect{4}(1,1);

% transformation: velodyne -> rectified camera coordinates
veloToCam{1} = T0 * R_rect00 * Tr_velo_to_cam;
veloToCam{2} = T1 * R_rect00 * Tr_velo_to_cam;
veloToCam{3} = T2 * R_rect00 * Tr_velo_to_cam;
veloToCam{4} = T3 * R_rect00 * Tr_velo_to_cam;
else
    veloToCam = [];
end;

% calibration matrix after rectification (equal for all cameras)
K = calib.P_rect{1}(:,1:3);
end


function calib = loadCalib(calibfile)
    
calib = getcam(calibfile);

end

function [calib] = getcam(calibfile, f)

% f is the image resize factor

if nargin < 3
    f = 1;
end;
   fid = fopen(calibfile);
  % load 3x4 projection matrix
    C = textscan(fid,'%s %f %f %f %f %f %f %f %f %f %f %f %f',4);
  calib = [];
  for j = 0 : 3
     P = [];
     for i=0:11
       P(floor(i/4)+1,mod(i,4)+1) = C{i+2}(j+1);
     end
     calib.P_rect{j+1} = P;
  end;
  C = textscan(fid,'%s %f %f %f %f %f %f %f %f %f',1);
  
  % load R_rect
%   C = textscan(fid,'%s %f %f %f %f %f %f %f %f %f',1);
  
  % load velo_to_cam
%   C = textscan(fid,'%s %f %f %f %f %f %f %f %f %f %f %f %f');
  
  fclose(fid);
end
