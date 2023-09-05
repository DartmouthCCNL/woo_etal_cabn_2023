function [negloglike, nlls, V1, V2] = funRW1(xpar,dat,initVals)
% % funDQ_RPE % 
%PURPOSE:   Function for maximum likelihood estimation, called by fit_fun().
%
%INPUT ARGUMENTS
%   xpar:       alpha, beta, alpha2, side_bias
%   dat:        data
%               dat(:,1) = choice (stimulus) vector: cir=-1, sqr=1
%               dat(:,2) = reward vector
%               dat(:,3) = choice location vector: L=-1, R=1
%OUTPUT ARGUMENTS
%   negloglike:      the negative log-likelihood to be minimized

%%
alpha = xpar(1);
beta = xpar(2);

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
    
    
    %compare with actual choice (location) to calculate log-likelihood
    [nlls(k), negloglike] = NegLogLike(p_1,p_2,choice(k),negloglike);    
    
    % update decision value for the performed action
    if choice(k)==1        % chose right
        % rpe = reward(k) - v_2;
        v_2 = v_2 + alpha*(reward(k) - v_2);
    elseif choice(k)==-1   %chose left
        %rpe = reward(k) - v_1;
        v_1 = v_1 + alpha*(reward(k) - v_1);
    else
        % error('choice vector error'); % no choice was made, skip learning        
    end
    
end

end
