function evalCfg = makeWaterTankEvalConfig(cfg)

evalCfg.Ts = cfg.Ts;
evalCfg.Tf = cfg.Tf;
evalCfg.MaxSteps = ceil(cfg.Tf/cfg.Ts);

% Final-window length for steady-state metrics
evalCfg.FinalWindowSeconds = 2.0;

% Settling tolerance
evalCfg.SettlingTol = 0.05;

% Safety limits
evalCfg.h_min = 0;
evalCfg.h_max = 20;

%% Training-time validation set
% Small fixed set used during training by rlCustomEvaluator.
evalCfg.TrainingCases = table( ...
    [1;2;3;4;5;6;7], ...
    [5;7;11;3;15;1;19], ...
    [9;9;9;10;10;15;5], ...
    'VariableNames', ["CaseID","h0","hRef"]);

%% Final/post-stage test matrix
h0List   = [1 3 5 7 9 11 13 15 17 19];
hRefList = [5 10 15];

caseID = 0;
rows = [];

for i = 1:numel(h0List)
    for j = 1:numel(hRefList)
        caseID = caseID + 1;
        rows = [rows; caseID, h0List(i), hRefList(j)]; %#ok<AGROW>
    end
end

evalCfg.FinalCases = array2table(rows, ...
    'VariableNames', ["CaseID","h0","hRef"]);

%% Gated score weights
% Lower J is better. Evaluator returns statistic = -J.
evalCfg.Score.failureBasePenalty = 1000;
evalCfg.Score.failureRateWeight = 1000;

evalCfg.Score.meanFinalMAEWeight = 10;
evalCfg.Score.maxFinalMAEWeight = 2;
evalCfg.Score.meanIAEWeight = 1;

evalCfg.Score.meanUEnergyWeight = 0.1;
evalCfg.Score.meanDuEnergyWeight = 0.1;

end