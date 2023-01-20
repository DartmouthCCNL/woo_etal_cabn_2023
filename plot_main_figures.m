%% Plot main figures
clearvars; clc; close all
datasets = {'Cohen','Schultz'};
animalCols = {[.83 .07 .35],[.27 .67 .6]};  % red/teal

allOutput = struct;
for d = 1:numel(datasets)
    dataset_label = datasets{d};
    animal_colors.(dataset_label) = animalCols{d}; 
    if strcmp(dataset_label,'Cohen')
        plot_setting_v = 2;
            % 0 = include 40/5 & 40/10 schedules only
            % 1 = include all 
            % 2 = include two-prob task only
        lastN_trials = 30;
    elseif strcmp(dataset_label,'Schultz')
        plot_setting_v = 3;  
            % 3 = exclude L of single-block sessions
        lastN_trials = 20;
    end
    
    disp(dataset_label+": Last "+lastN_trials+" trials metrics");
    fname = "output/"+dataset_label+"_subjects_output_last"+lastN_trials+".mat";

    if exist(fname,'file')
        % load processed data
        load(fname,'metricOutput');
    else
        % compute output
        run_analysis;
        save(fname,'metricOutput');
    end
    
    allOutput.(dataset_label) = metricOutput;
    plot_settings.(dataset_label) = plot_setting_v;
end

gca_fontsize = 12;

%% Fig2.C/D Choice behavior, E/F P(Better) and Information Entropy
close all

Fig2_example_session(animal_colors);

%% Fig3. A-C: Before and after reversal metrics, distributions & running averages
clc; close all
trial_length = 15;  % N trials before/after

Fig3_BeforeAfter_reversal(trial_length, plot_settings, animal_colors, gca_fontsize);

%% Fig4 and Fig5. Behavior of each species
close all

def_versions(1) = "deltaP";   
def_versions(2) = "gammaE0.1"; 

Fig4_and_5_by_species(allOutput, plot_settings, def_versions, animal_colors, gca_fontsize);

%% Fig.6, 7. RL models
close all; clc
clear def_versions

def_versions(1) = "gammaE0.1";   % BLPE
def_versions(2) = "deltaP";      % Uncertainty   

Fig6_and_7_RL(allOutput, plot_settings, def_versions, animal_colors, gca_fontsize);


