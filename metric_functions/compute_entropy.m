function H_X = compute_entropy(X, numOutcomes)
    % computes H(x) = -[p(x)*log2(x) + p(~x)*log2(~x)]
    if ~exist('numOutcomes','var')
        % numOutcomes = 2; 
        H_X = -(mean(X)*log2(mean(X)) + mean(~X)*log2(mean(~X)));
        if isnan(H_X)
            if mean(~X)==0||mean(X)==0
                H_X = 0;    % this prevents zero*-Inf = NaN
            end
        end
    elseif numOutcomes==4
        %H_X = -[mean(X==0)*logN(mean(X==0),4) + mean(X==1)*logN(mean(X==1),4) + ...
        %    mean(X==2)*logN(mean(X==2),4) + mean(X==3)*logN(mean(X==3),4)] ;
        
        term0 = mean(X==0)*log2(mean(X==0));
        if isinf(log2(mean(X==0))); term0 = 0; end
        
        term1 = mean(X==1)*log2(mean(X==1));
        if isinf(log2(mean(X==1))); term1 = 0; end

        term2 = mean(X==2)*log2(mean(X==2));
        if isinf(log2(mean(X==2))); term2 = 0; end
        
        term3 = mean(X==3)*log2(mean(X==3));
        if isinf(log2(mean(X==3))); term3 = 0; end
        
        H_X = -(term0 + term1 + term2 + term3);
    end
    
end


% function y = logN(x, N)
%     % log with different base
%     
%     y = log(x) / log(N);
% end

% term0 = mean(X==0)*logN(mean(X==0),4);
% if isinf(logN(mean(X==0),4)); term0 = 0; end
% 
% term1 = mean(X==1)*logN(mean(X==1),4);
% if isinf(logN(mean(X==1),4)); term1 = 0; end
% 
% term2 = mean(X==2)*logN(mean(X==2),4);
% if isinf(logN(mean(X==2),4)); term2 = 0; end
% 
% term3 = mean(X==3)*logN(mean(X==3),4);
% if isinf(logN(mean(X==3),4)); term3 = 0; end