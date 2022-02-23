function data_out = get_subFiles(file_dir, varargin)
% Baiwei Liu, vu, 2021

if ~isempty(varargin)
    file_core = varargin{1};
else
    file_core = '*.mat';
end
    
cd(file_dir)

sublist=dir(file_core);
sublist={sublist.name}; 
data_out ={};
for i = 1:length(sublist)
    
    if ~strcmp(sublist{i}(1),'.')
        data_out{end+1} = [file_dir filesep sublist{i}];
    end
end
end