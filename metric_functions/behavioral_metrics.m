function output = behavioral_metrics(choice, reward, hr_option, stay)
% % behavioral_metrics %
%PURPOSE:   Compute behavioral metrics
%AUTHORS:   Ethan Trepka 10/05/2020; Edit Jae Hyung Woo 9/15/2021
%
%
%INPUT ARGUMENTS
%   choice:   choice vector for block/session where -1 = choose circle, 1 = choose square. choice should not include NaN trials.
%   c_location: choice vector for block/session where -1 = choose left, 1 = choose right. choice should not include NaN trials.
%   reward:   reward vector for block/session where 1 = reward, 0 = no reward
%   hr_option:  vector of higher reward option in each trial. Could be either location (hr_side) or stimulli identity (hr_shape)
%   stay: stay vector, only REQUIRED for running average plots 
%
%
%OUTPUT ARGUMENTS
%   output: range of behavioral metrics, see code

    better = choice==hr_option;       % does choice corresponds to better shape/side?
    Cir = choice==-1;
    
    if ~exist('stay', 'var')
        stay = choice(1:end-1)==choice(2:end);
        rewardR = reward(1:end-1);
        betterR = better(1:end-1);
        CirR = Cir(1:end-1);
    else
        rewardR = reward;
        betterR = better;
        CirR = Cir;
    end
    
    output.pbetter = mean(better);      %prob(choose better option)
    output.pstay = mean(stay);          %prob(staying on the same option in the next trial)
    output.pwin = mean(reward);         %prob(winning a reward---regardless of choosing hr option)
    output.pwinR = mean(rewardR);       %prob(winning a reward, excluding the last trial---because it's computing for existence ofprevious rewards)
    output.ploseR = 1-output.pwinR;
    output.pbetterR = mean(betterR);
    output.pworseR = 1-output.pbetterR;
    output.betterstay = conditional_probability(stay, betterR); 
    output.worseswitch = conditional_probability(~stay, ~betterR);
    
    output.winbetter = mean(better&reward);
    output.losebetter = mean(better&~reward);
    output.winworse = mean(~better&reward);
    output.loseworse = mean(~better&~reward);
    
    output.winstaybetter = conditional_probability(stay, betterR&rewardR);
    output.loseswitchbetter = conditional_probability(~stay, betterR&~rewardR);
    output.winstayworse = conditional_probability(stay, ~betterR&rewardR);
    output.loseswitchworse = conditional_probability(~stay, ~betterR&~rewardR);
    
    output.winstay = conditional_probability(stay, rewardR);    % prob(staying | rewarded on previous trials)
    output.winswitch = conditional_probability(~stay, rewardR);
    output.loseswitch = conditional_probability(~stay, ~rewardR);   %prob(switching | not rewarded on previous trial)
    output.losestay = conditional_probability(stay, ~rewardR);
    
    
    %
    output.delta_winstay_losestay = output.winstay - conditional_probability(stay, ~rewardR);
    output.choice_fraction = mean(choice == -1)/(mean(choice==-1) + mean(choice==1));
    output.reward_fraction = (mean(reward==1&choice==-1))/(mean(reward==1&choice==-1) + mean(reward==1&choice==1));
    output.matching_measure = output.choice_fraction - output.reward_fraction;
    output.matching_measure(output.reward_fraction<0.5) = -output.matching_measure(output.reward_fraction<0.5);
    
    output.choice_fraction_run = mean(better)/(mean(better)+mean(~better));
    output.reward_fraction_run = (mean(reward&better))/(mean(reward&better) + mean(reward&~better));
    output.matching_measure_run = output.choice_fraction_run-output.reward_fraction_run;
    output.matching_measure_run(output.reward_fraction_run<0.5) = -output.matching_measure_run(output.reward_fraction_run<0.5);

%    output.matching_measure = (output.choice_fraction-output.reward_fraction)*sign(output.reward_fraction-0.5);  

    output.RI_BW = output.pstay - (output.pbetter^2+(1-output.pbetter)^2); % p(staying) - [p(better)^2 + p(worse)^2]
    output.RI_B = mean(stay&betterR) - output.pbetter^2;
    output.RI_W = mean(stay&~betterR) - (1-output.pbetter)^2;
    
    % RI_CS: Repetition Index based on Shape (or Option if using hr_shape)
    output.pCir = mean(Cir);   
    output.RI_CS = output.pstay - (output.pCir^2 + (1-output.pCir)^2);
    output.RI_C = mean(stay&CirR) - output.pCir^2;
    output.RI_S = mean(stay&~CirR) - (1-output.pCir)^2;
    
end