function [negloglike, nlls, V1, V2] = funRL2(xpar,dat,initVals)
% % funDQ_RPE % 
%PURPOSE:   Function for maximum likelihood estimation, called by fit_fun().
%
%INPUT ARGUMENTS
%   xpar:       alpha, beta, alpha2
%   dat:        data
%               dat(:,1) = choice stimulus vector
%               dat(:,2) = reward vector
%               dat(:,3) = choice location vector
%
%OUTPUT ARGUMENTS
%   negloglike:      the negative log-likelihood to be minimized
%% 
alpha = xpar(1);
beta = xpar(2);
alpha2 = xpar(3);
decay_rate = xpar(4);
decay_base = 0; %xpar(5);

nt = size(dat,1);
negloglike = 0;
nlls = zeros(1,nt);
V1 = nan(nt,1); V2 = nan(nt,1);

choice = dat(:,1);
reward = dat(:,2);
    
if ~exist('initVals','var')
    v_1 = 0.5;
    v_2 = 0.5;
else
    initV = initVals{1};
    v_1 = initV(1);
    v_2 = initV(2);
end

for k = 1:nt
    % obtain final choice probabilities for Left and Right side
    [p_1, p_2] = DecisionRule(v_1,v_2,beta);
    V1(k) = v_1;
    V2(k) = v_2;
    
    %compare with actual choice to calculate log-likelihood
    [nlls(k), negloglike] = NegLogLike(p_1,p_2,choice(k),negloglike);
    
    % update decision values and other traces for the performed action
    if choice(k)==1        %chose sqr/right
        rpe = reward(k) - v_2;
        if reward(k)>0
            v_2 = v_2 + alpha*rpe;
        else
            v_2 = v_2 + alpha2*rpe;
        end
        v_1 = v_1 + decay_rate*(decay_base-v_1);
    elseif choice(k)==-1   %chose cir/left
        rpe = reward(k) - v_1;
        if reward(k)>0
            v_1 = v_1 + alpha*rpe;
        else
            v_1 = v_1 + alpha2*rpe;
        end
        v_2 = v_2 + decay_rate*(decay_base-v_2);
    elseif choice(k)==0     % no choice was made
        v_1 = v_1 + decay_rate*(decay_base-v_1);
        v_2 = v_2 + decay_rate*(decay_base-v_2);
    end
    
end

end