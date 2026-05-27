function [statistic, scores, data] = dummyTrainingEvaluator(~, ~, trainingInfo)

% No sim(), no env reset, no Simulink execution.
% This only tests whether rlCustomEvaluator itself works with parallel async.

ep = trainingInfo.EpisodeIndex;

statistic = -double(ep);      % scalar
scores = statistic;           % numeric vector/scalar
data = [];                    % keep empty for this test

fprintf("\n[DummyEval] Episode %d | Statistic %.2f\n", ep, statistic);

end