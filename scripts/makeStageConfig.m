function cfg = makeStageConfig()

cfg.ModelName = "rlwatertank";
cfg.AgentBlock = "rlwatertank/RL Agent";

cfg.Ts = 0.1;
cfg.Tf = 10;

cfg.UseParallel = true;
cfg.RequestedWorkers = 16;

cfg.Verbose = true;
cfg.PlotMode = "training-progress";

cfg.SavePrefix = "WaterTankDDPG_curriculum";
cfg.FinalSaveName = "WaterTankDDPG_curriculum_final.mat";

cfg.SaveReplayBuffer = false;
cfg.SaveTrainingStats = true;

%% Shared reward defaults
baseReward.mode = 3;                  % reward type: full shaped reward, based on file rewardFcn.m
baseReward.thr = 0.1;                 % error threshold for mode 1
baseReward.posReward = 10;            % positive reward for mode 1
baseReward.negReward = -1;            % negative reward for mode 1
baseReward.unsafePenalty = 100;       % penalty for unsafe tank height
baseReward.h_min = 0;                 % minimum allowed height
baseReward.h_max = 20;                % maximum allowed height
baseReward.lambda_u = 0.001;          % control effort penalty weight
baseReward.lambda_du = 0.02;          % control smoothness penalty weight
baseReward.tol = 0.05;                % tolerance band for bonus
baseReward.tolBonus = 0.05;           % small bonus inside tolerance

%% Stage 1: local correction
stages(1).Name = "local";
stages(1).Seed = 1;
stages(1).MaxEpisodes = 800;
stages(1).EvaluationFrequency = 25;
stages(1).EvaluationEpisodes = 3;
stages(1).StopTrainingCriteria = "EpisodeCount";
stages(1).StopTrainingValue = stages(1).MaxEpisodes;

stages(1).Reset.mode = "offset";
stages(1).Reset.hRefMean = 10;
stages(1).Reset.hRefStd = 3;
stages(1).Reset.hMin = 0;
stages(1).Reset.hMax = 20;
stages(1).Reset.minInitialError = 0.5;
stages(1).Reset.maxInitialError = 2.0;

stages(1).Reward = baseReward;
stages(1).Reward.e_scale = 2.0; % Based on e max

stages(1).NoiseStd = 0.05;
stages(1).NoiseDecay = 1e-5;
stages(1).ResetBuffer = true;

%% Stage 2: medium transient
stages(2) = stages(1);
stages(2).Name = "medium";
stages(2).Seed = 2;
stages(2).MaxEpisodes = 1000;
stages(2).Reset.maxInitialError = 5.0;
stages(2).Reward.e_scale = 5.0;
stages(2).NoiseStd = 0.08;
stages(2).NoiseDecay = 1e-5;
stages(2).ResetBuffer = true;

%% Stage 3: full-range robustness
stages(3) = stages(1);
stages(3).Name = "global";
stages(3).Seed = 3;
stages(3).MaxEpisodes = 1500;
stages(3).Reset.mode = "independent";
stages(3).Reward.e_scale = 10.0;
stages(3).NoiseStd = 0.12;
stages(3).NoiseDecay = 1e-5;
stages(3).ResetBuffer = true;

%% Stage 4: precision fine-tuning
stages(4) = stages(1);
stages(4).Name = "precision";
stages(4).Seed = 4;
stages(4).MaxEpisodes = 1000;
stages(4).Reset.mode = "independent";
stages(4).Reward.e_scale = 1.0;
stages(4).Reward.lambda_u = 0.001;
stages(4).Reward.lambda_du = 0.05;
stages(4).Reward.tol = 0.02;
stages(4).Reward.tolBonus = 0.1;
stages(4).NoiseStd = 0.02;
stages(4).NoiseDecay = 1e-5;
stages(4).ResetBuffer = true;

cfg.Stages = stages;

end

%% Notes on BaseRewards
% baseReward.mode = 3;
% % Reward mode:
% % 1 = original boolean reward
% % 2 = normalized quadratic error only
% % 3 = quadratic error + control penalties + tolerance bonus
% 
% baseReward.thr = 0.1;
% % Error threshold used ONLY in mode 1
% % If |e| < thr -> positive reward
% % Otherwise -> negative reward
% 
% baseReward.posReward = 10;
% % Positive reward used ONLY in mode 1
% % Applied when |e| < thr
% 
% baseReward.negReward = -1;
% % Negative reward used ONLY in mode 1
% % Applied when |e| >= thr
% 
% baseReward.unsafePenalty = 100;
% % Large penalty applied if tank becomes unsafe:
% % h <= h_min OR h >= h_max
% 
% baseReward.h_min = 0;
% % Minimum allowed tank height
% % Falling below this terminates the episode
% 
% baseReward.h_max = 20;
% % Maximum allowed tank height
% % Exceeding this terminates the episode
% 
% baseReward.lambda_u = 0.001;
% % Penalty weight on control effort u^2
% % Higher value discourages large actuator commands
% 
% baseReward.lambda_du = 0.02;
% % Penalty weight on control rate change:
% % (u - u_prev)^2
% % Higher value encourages smoother control action
% 
% baseReward.tol = 0.05;
% % Precision tolerance band for mode 3
% % If |e| < tol, a small bonus is added
% 
% baseReward.tolBonus = 0.05;
% % Small positive bonus added in mode 3
% % Encourages staying very close to the setpoint