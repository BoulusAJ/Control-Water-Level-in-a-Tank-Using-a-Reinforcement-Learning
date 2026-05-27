clear; clc;
%%
files = [
    "WaterTankDDPG_curriculum_stage_01_easy_reset_strong_shaping.mat"
    "WaterTankDDPG_curriculum_stage_02_medium_reset_medium_shaping.mat"
    "WaterTankDDPG_curriculum_stage_03_full_reset_weak_shaping.mat"
    "WaterTankDDPG_curriculum_stage_04_full_reset_no_shaping_low_noise.mat"
];

files = [
    "WaterTankDDPG_curriculum_stage_04_full_reset_no_shaping_low_noise.mat"
];


allSummaries = table();
allMetrics = table();

for i = 1:numel(files)

    S = load(files(i));

    result = S.postStageEval;

    allSummaries = [allSummaries; result.summary];
    allMetrics = [allMetrics; result.metrics];

end

disp(allSummaries);

%% Example plots
figure;
bar(categorical(allSummaries.ControllerName), ...
    allSummaries.MeanFinalMAE);

ylabel("Mean Final MAE");
title("Steady-state accuracy");
grid on;