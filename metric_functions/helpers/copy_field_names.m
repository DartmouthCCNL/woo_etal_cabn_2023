function struct1 = copy_field_names(struct1, struct2s)
% INPUT:
    % struct1: struct
    % struct2s: cell array of structs
% OUTPUT:
    % struct1: new struct with copied values from each field of struct2s
    
    for i = 1:length(struct2s)
        struct2 = struct2s{i};
        
        for fields = fieldnames(struct2)'
            struct1.(fields{1}) = struct2.(fields{1});
        end
    end
    
end