function fit_mods_by_block(dataset_label, fit_flag, fitType, numFitRun)
% input arg
% fitType:
%    'block'     :   fit to individual blocks, finding best-fit params in the step-wise way
%    'blockWhole':   fit to individual blocks, finding best-fit params for each block which yield the overall lowest -LL for the entire session combined

%% fit & sim param

num_sim = 100;                 % number of simulation per block using fitted params
load_fit_output = true;
load_sim_output = true;
pseudorandom_side = false;

%% load datasets
data_file_name = ["preprocessed/all_stats_"+dataset_label+".mat"];
load(data_file_name, 'all_stats');          % load all stats structures

% select schedules of interest only
% if strcmp(dataset_label,"Cohen")    
%     schedule_subsets = ["prob540","prob1040"];
%     all_stats = subset_sessions_rew_probs(all_stats, schedule_subsets);
% end

%% initialize model     
models = initialize_vol_models(dataset_label, fitType, load_fit_output, load_sim_output, numFitRun, pseudorandom_side);

models_list = string;
for m = 1:length(models)
    models_list(m) = models{m}.name;
end
    
%%  loop through each model
for m = 1:length(models)
    tic

    % fitting
    disp(m+". fitting model: " + models{m}.name);
    if sum(models_list==models{m}.extract_initpar_from)==0
        models{m}.extract_initpar_from = 'none';
    end
    if (strcmp(models{m}.extract_initpar_from,'None')||strcmp(models{m}.extract_initpar_from,'none'))
        extracted_model = {};
    else
        extracted_model = models{models_list==models{m}.extract_initpar_from};
        disp("   extracting initial values from "+extracted_model.name);
    end
    models{m} = fit_and_save_Vol(all_stats, dataset_label,fitType, models{m}, extracted_model, fit_flag, numFitRun);

    % simulating
    %output = simulate_and_save_Rtrace(all_stats, dataset_label, models{m}, output, num_sim, sim_flag, pseudorandom_side);

    ET = toc;
    disp("Elasped time is "+ET/60+" minutes");
end    
    disp('Done!');
end