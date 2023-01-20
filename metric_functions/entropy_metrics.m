function output = entropy_metrics(choice, reward, hr_opt, str)
% % entropy_metrics %
%PURPOSE:   Compute ERDS, EODS, ERODS, and decompositions 
%AUTHORS:   Ethan Trepka 10/05/2020; Jae Hyung Woo
%DATASET:   Costa Neuron 2016
%
%INPUT ARGUMENTS
%   choice:   choice vector for block/session where -1 = choose cir, 1 = choose sqr. choice should not include NaN trials.
    % if using location option:
    %   c_location: choice vector for block/session where -1 = choose left, 1 = choose right. choice should not include NaN trials.
%   reward:   reward vector for block/session where 1 = reward, 0 = no reward
%   hr_shape:  vector of "better" shape (higher reward probability) in each trial. hr_shape is same length as choice and reward vectors. 
%   str (strategy): stay/switch vector, only REQUIRED when used for running averages
%
%OUTPUT ARGUMENTS
%   output: entropy metrics and decompositions, stored in the following
%       fields: ["ERDS", "ERDS_win", "ERDS_lose", "EODS", "EODS_better",
%       "EODS_worse", "ERODS", "ERODS_winworse", "ERODS_winbetter", 
%       "ERODS_loseworse", "ERODS_losebetter"]

    if ~exist('str', 'var')
        str = choice(1:end-1)==choice(2:end);       % strategy: stay?
    end

    cho = (choice==1);
    rew = reward;
    opt = choice==hr_opt;     % better option

    if length(rew)>length(str)
        rew(end) = [];
        opt(end) = [];
        cho(1) = [];
    end

    rew_and_opt = binary_to_decimal([rew, opt]);
    
    Ent = struct;
    Ent.H_str = compute_entropy(str);
    Ent.H_cho = compute_entropy(cho);
        
    output = copy_field_names(struct, {Ent, ...
        conditional_entropy(str, rew, "ERDS", containers.Map({0,1},{'lose','win'})), ...
        conditional_entropy(cho, rew, "ERDC", containers.Map({0,1},{'lose','win'})), ...
        conditional_entropy(str, opt, "EODS", containers.Map({0,1},{'worse','better'})), ...
        conditional_entropy(cho, opt, "EODC", containers.Map({0,1},{'worse','better'})), ...
        conditional_entropy(str, rew_and_opt, "ERODS", containers.Map({0,1,2,3},{'loseworse','losebetter','winworse','winbetter'})), ...
        mutual_information(str, rew, "MIRS", containers.Map({0,1},{'lose', 'win'})), ...
        mutual_information(cho, rew, "MIRC", containers.Map({0,1},{'lose', 'win'})), ...
        mutual_information(str, opt, "MIOS", containers.Map({0,1},{'worse', 'better'})), ...
        mutual_information(cho, opt, "MIOC", containers.Map({0,1},{'worse','better'})), ...
        mutual_information(str, rew_and_opt, "MIROS", containers.Map({0, 1, 2, 3},{'loseworse','losebetter','winworse','winbetter'})),...
        });
                
end