function [models] = initialize_vol_models(dataset_label, fitType, load_fit_output, load_sim_output, numfitruns)

    if ~exist("load_fit_output",'var')
        load_fit_output = true;
    end
    if ~exist("load_sim_output",'var')
        load_fit_output = false;
    end
    if ~exist('numfitruns','var')
       numfitruns = 100; 
    end
    
    if ischar(dataset_label)
        dataset_label = convertCharsToStrings(dataset_label);
    end

include_RW1 = 1;
include_RW2 = 1;

include_RL1 = 1;
include_RL2 = 1;

include_wRev = 0;

sort_order_by_names = 0;

%% Control models: Rescorla-Wagner, RL1, RL2
models = {};
if include_RW1    
    m = length(models) + 1;
    models{m}.name = 'RW1';
    models{m}.algo = 'algoRW1';       
    models{m}.fun = 'funRW1';     
    models{m}.initpar=[.5  5];   
    models{m}.lb     =[ 0  1];   
    models{m}.ub     =[ 1 100];
    models{m}.label = "RW1: Rescorla-Wagner";
    models{m}.behav_flag = 0;
    models{m}.plabels = ["\alpha", "\beta"];
    models{m}.simfunc = 'predictAgentSimulationLocation';
    models{m}.extract_initpar_from = 'none';
end
if include_RW2    
    m = length(models) + 1;
    models{m}.name = 'RW2';
    models{m}.algo = 'algoRW2';       
    models{m}.fun = 'funRW2';     
    models{m}.initpar=[.5  5 .5];   
    models{m}.lb     =[ 0  1  0];   
    models{m}.ub     =[ 1 100 1];
    models{m}.label = "RW2: Rescorla-Wagner+decay";
    models{m}.behav_flag = 0;
    models{m}.plabels = ["\alpha", "\beta","decay"];
    models{m}.simfunc = 'predictAgentSimulationLocation';
    models{m}.extract_initpar_from = 'RW1';
end
if include_RL1
    m = length(models) + 1;
    models{m}.name = 'RL1';
    models{m}.algo = 'algoRL1';       
    models{m}.fun = 'funRL1';     
    models{m}.initpar=[.5  5  .5];   
    models{m}.lb     =[ 0  1   0];   
    models{m}.ub     =[ 1 100  1];
    models{m}.label = "RL1: Return-based";
    models{m}.behav_flag = 0;
    models{m}.plabels = ["\alpha_{rew}", "\beta", "\alpha_{unrew}"];
    models{m}.simfunc = 'predictAgentSimulationLocation';
    models{m}.extract_initpar_from = 'RW1';
end
if include_RL2
    m = length(models) + 1;
    models{m}.name = 'RL2';
    models{m}.algo = 'algoRL2';       
    models{m}.fun = 'funRL2';     
    models{m}.initpar=[.5  5  .5 .5];   
    models{m}.lb     =[ 0  1   0  0];   
    models{m}.ub     =[ 1 100  1  1];
    models{m}.label = "RL2: Income-based";
    models{m}.behav_flag = 0;
    models{m}.plabels = ["\alpha_{rew}", "\beta", "\alpha_{unrew}","decay"];
    models{m}.simfunc = 'predictAgentSimulationLocation';
    models{m}.extract_initpar_from = 'RL1';
end

%% check for errors

numfields = numel(fieldnames(models{1}));
Names_set = strings;
Labels_set = strings;

for m = 1:length(models)
    if ~models{m}.behav_flag
        if numel(models{m}.initpar)~=numel(models{m}.plabels)
            error([models{m}.name+": Error in number of parameters"]);
        end
        if numel(fieldnames(models{m}))~=numfields
            error("Check number of fields : Model "+m);
        end
    end
    Names_set(m) = convertCharsToStrings(models{m}.name);
    Labels_set(m) = convertCharsToStrings(models{m}.label);
    ffunc = models{m}.fun;
    sfunc = models{m}.algo;
    if load_fit_output&&~(exist(ffunc,'file'))
        error(m+". "+ffunc+": corresponding model fit function does not exist")
    end
%     if load_sim_output&&~(exist(sfunc,'file'))
%         error(sfunc+": corresponding model sim function does not exist")
%     end
end
if numel(unique(Names_set))~=numel(models)
   error('Error: should assign unique file name to each model');
end
if numel(unique(Labels_set))~=numel(models)
   error('Error: should assign unique label to each model');
end

if sort_order_by_names
    [~,sortIdx] = sort(Names_set);
    models = models(sortIdx);
end

%% load existing output
% if the saved output file exists, flag and load the data

output_dir = "output/model/"+dataset_label+"/"+fitType+"/";

for m = 1:length(models)
    % fitting data
    fitfname = strcat(output_dir,'/',models{m}.name,'.mat');    
    if exist(fitfname, 'file') && load_fit_output
        load(fitfname, 'model_struct'); 
        orig_struct = model_struct;
        models{m}.fit_exists = 1;
        field_names = fieldnames(orig_struct);
        for cnt = 1:length(field_names)
            if ~isfield(models{m}, field_names{cnt})
                models{m}.(field_names{cnt}) = orig_struct.(field_names{cnt});
            end
        end
    else
        models{m}.fit_exists = 0;
    end
    
    % simulation data
    simfname = strcat(output_dir,'/sim/',models{m}.name,'.mat');
    if exist(simfname, 'file') && load_sim_output
        load(simfname, 'model_output');
        output.(models{m}.name) = model_output;
        models{m}.sim_exists = 1;
    else
        models{m}.sim_exists = 0;
    end
    
    % cross-validation data
    cvfname = strcat(output_dir,'/crossval/',models{m}.name,'.mat');   
    if exist(cvfname, 'file')
        models{m}.cv_exists = 1;
        load(cvfname, 'model_struct');
        field_names = fieldnames(model_struct);
        for cnt = 1:length(field_names)
            if ~isfield(models{m}, field_names{cnt})
                models{m}.(field_names{cnt}) = model_struct.(field_names{cnt});
            end
        end
    else
        models{m}.cv_exists = 0;
    end
    
end

%% generate initial value pool for evenly spaced search space

for m = 1:length(models)
    initparpool = nan(numfitruns-1,length(models{m}.initpar));     
    
    for p = 1:length(models{m}.initpar)
        initpars = linspace(models{m}.lb(p),models{m}.ub(p),numfitruns-1);
        initpars = initpars(randperm(length(initpars)));    %randomize order
        initparpool(:,p) = initpars;
    end
    
    models{m}.initparpool = mat2cell(initparpool,ones(numfitruns-1,1),length(models{m}.initpar));
    models{m}.initparpool{numfitruns} = models{m}.initpar;
end

%% display info
disp(">> "+ numel(models)+" models initialized:"); 
for m = 1:numel(models)
    disp(m+". "+models{m}.name);
end
disp('-----------------');  

end