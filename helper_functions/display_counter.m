
function display_counter(cnt)

    % display counter
    if cnt<=1
        fprintf(' %d', cnt);
    elseif cnt<=10
        fprintf('\b\b %d', cnt);
    elseif cnt <=100
        fprintf('\b\b\b %d', cnt);
    elseif cnt<=1000
        fprintf('\b\b\b\b %d', cnt);
    else
        fprintf('\b\b\b\b\b %d', cnt);
    end 

end