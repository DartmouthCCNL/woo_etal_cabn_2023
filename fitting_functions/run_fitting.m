% run fitting

Datasets = {'Cohen','Schultz'};

fit_flag = 1;
fitType = 'block';
numFitRun = 100;


for d = 1:numel(Datasets)
    dataset_label = Datasets{d};
    
    % run fit
    fit_mods_by_block(dataset_label, fit_flag, fitType, numFitRun);
end
