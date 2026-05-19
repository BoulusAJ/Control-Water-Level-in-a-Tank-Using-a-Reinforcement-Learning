function datasetToCSV(simout, filename)
if nargin < 2 || isempty(filename), filename = 'simout.csv'; end
if ~isa(simout,'Simulink.SimulationData.Dataset'), error('First input must be a Dataset'); end

n = numElements(simout); % number of elements
names = cell(n,1);
times = cell(n,1);
data  = cell(n,1);

for k = 1:n
    elem = simout{k};           % use curly braces (1-based)
    names{k} = matlab.lang.makeValidName(elem.Name);
    % values stored in Values or Values (timeseries)
    vals = elem.Values;
    if isa(vals,'timeseries')
        times{k} = vals.Time(:);
        data{k}  = vals.Data(:);
    elseif isstruct(vals) && isfield(vals,'Time') && isfield(vals,'Data')
        times{k} = vals.Time(:);
        data{k}  = vals.Data(:);
    else
        error('Unsupported Value type for element %d (%s)', k, names{k});
    end
    % if multi-col data, take first column
    if size(data{k},2) > 1
        data{k} = data{k}(:,1);
    end
end

% if all times equal, use that, else union + interp
allEqual = true;
refT = times{1};
for k = 2:n
    if numel(times{k}) ~= numel(refT) || any(times{k} ~= refT)
        allEqual = false; break
    end
end

if allEqual
    Tcommon = refT;
    M = numel(Tcommon);
    mat = nan(M,n);
    for k = 1:n, mat(:,k) = double(data{k}); end
else
    Tcommon = unique(vertcat(times{:}));
    M = numel(Tcommon);
    mat = nan(M,n);
    for k = 1:n
        mat(:,k) = interp1(times{k}, double(data{k}), Tcommon, 'linear', NaN);
    end
end

T = table(Tcommon,'VariableNames',{'Time'});
for k = 1:n, T.(names{k}) = mat(:,k); end
writetable(T, filename);
fprintf('Wrote %d rows x %d columns to %s\n', height(T), width(T)-1, filename);
end
