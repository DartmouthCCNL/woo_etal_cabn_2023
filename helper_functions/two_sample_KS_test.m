function [KS_pval, ks2_D, astK] = two_sample_KS_test(Sample1, Sample2, multcomp, tail_type)
    if ~exist('tail_type','var')||strcmp(tail_type,'both')
        tail_dir = 'unequal';
    elseif strcmp(tail_type,'left')
        tail_dir = 'larger';
    elseif strcmp(tail_type,'right')
        tail_dir = 'smaller';
    end

    [~,KS_pval,ks2_D] = kstest2(Sample1, Sample2,'tail',tail_dir);

%     astK = "n.s.";
    astK = "";
    if KS_pval<.05/multcomp; astK = "∗"; 
%         if KS_pval <.01/multcomp; astK = "∗∗"; 
%             if KS_pval<.001/multcomp; astK = "∗∗∗"; end; end
    end 
            
end