function [t, h, hRef, u] = extractWaterTankSignals(experiences, hRefFallback, evalCfg)

t = [];
h = [];
hRef = [];
u = [];

%% Preferred: use Simulink logsout signals
try
    logsout = experiences.SimulationInfo.logsout;

    [t, h]    = getLogsoutSignal(logsout, "h");
    [~, hRef] = getLogsoutSignal(logsout, "href");
    [~, u]    = getLogsoutSignal(logsout, "u");
catch
end

%% Fallback: use RL observations/actions
% Your observation order is:
%   obs(1) = I_e
%   obs(2) = e
%   obs(3) = h
if isempty(h)
    try
        obs = experiences.Observation.observations.Data;
        act = experiences.Action.flow.Data;

        e = squeeze(obs(2,1,:));
        h = squeeze(obs(3,1,:));
        u = squeeze(act(1,1,:));

        hRef = h + e;

        n = numel(h);
        t = (0:n-1)' * evalCfg.Ts;
    catch
    end
end

%% Fallback for hRef
if isempty(hRef) && ~isempty(h)
    hRef = hRefFallback * ones(size(h));
end

if isempty(t) || isempty(h) || isempty(u)
    error("extractWaterTankSignals:MissingSignals", ...
        "Could not extract h, href, and u. Check logsout signal names or observation/action names.");
end

t = t(:);
h = h(:);
hRef = hRef(:);
u = u(:);

n = min([numel(t), numel(h), numel(hRef), numel(u)]);

t = t(1:n);
h = h(1:n);
hRef = hRef(1:n);
u = u(1:n);

end

function [t, y] = getLogsoutSignal(logsout, signalName)

sig = logsout.get(signalName);

if isempty(sig)
    error("Signal '%s' not found in logsout.", signalName);
end

values = sig.Values;

t = values.Time;
y = squeeze(values.Data);

end