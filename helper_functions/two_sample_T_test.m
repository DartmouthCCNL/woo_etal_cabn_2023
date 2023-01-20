function [tpv1, D, astT, stats] = two_sample_T_test(Sample1, Sample2, multcomp, tail_type)
    % parametric test
    [~,tpv1,~,stats] = ttest2(Sample1, Sample2,'tail',tail_type); 
    D = computeCohen_d(Sample1, Sample2);
    
    astT = "n.s.";
    if tpv1<.05/multcomp; astT = "∗";
%         if tpv1 <.01/multcomp; astT = "∗∗"; 
%             if tpv1<.001/multcomp; astT = "∗∗∗"; end; end
    end
end