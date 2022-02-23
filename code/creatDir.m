function [data_out] = creatDir(file_dir)
% creat folder if there is no folder; by Baiwei Liu
if ~exist(file_dir,'dir'); mkdir(file_dir); end
data_out = file_dir;
end