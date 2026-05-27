T = allMetrics;
fid = fopen('allMetrics_prec4.csv', 'w');

% write header
vars = T.Properties.VariableNames;
fprintf(fid, '%s', vars{1});
for k = 2:numel(vars)
    fprintf(fid, ',%s', vars{k});
end
fprintf(fid, '\n');

% prepare format string per column (adjust for integers/strings if needed)
fmtCols = cell(1,numel(vars));
for k = 1:numel(vars)
    if isnumeric(T{1,k})
        fmtCols{k} = '%.4f';    % numeric precision
    else
        fmtCols{k} = '%s';      % text
    end
end
rowFmt = strjoin(fmtCols, ',');
rowFmt = [rowFmt '\n'];

% write row by row
for r = 1:height(T)
    vals = cell(1,numel(vars));
    for k = 1:numel(vars)
        v = T{r,k};
        if isnumeric(v)
            vals{k} = v;        % numeric stays numeric for fprintf
        else
            vals{k} = string(v);% ensure string/cellstr for %s
        end
    end
    fprintf(fid, rowFmt, vals{:});
end

fclose(fid);
