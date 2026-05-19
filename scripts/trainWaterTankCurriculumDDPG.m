clear; clc;

previousRngState = rng(0,"twister");

cfg = makeStageConfig();

mdl = cfg.ModelName;
open_system(mdl);

set_param(mdl, ...
    FastRestart="on", ...
    SimulationMode="accelerator");

%% Environment
obsInfo = rlNumericSpec([3 1], ...
    LowerLimit=[-inf -inf 0]', ...
    UpperLimit=[ inf  inf inf]');

obsInfo.Name = "observations";

actInfo = rlNumericSpec([1 1], ...
    LowerLimit=0, ...
    UpperLimit=1);

actInfo.Name = "flow";

env = rlSimulinkEnv( ...
    mdl, ...
    cfg.AgentBlock, ...
    obsInfo, ...
    actInfo);

env.ResetFcn = @localResetFcnCurriculum;

%% Agent
agent = createDDPGAgent(obsInfo, actInfo, cfg);

%% Parallel pool
if cfg.UseParallel
    pool = gcp("nocreate");
    if isempty(pool)
        pool = parpool("Processes", cfg.RequestedWorkers);
    elseif pool.NumWorkers ~= cfg.RequestedWorkers
        delete(pool);
        pool = parpool("Processes", cfg.RequestedWorkers);
    end
end

%% Curriculum loop
%for k = 1:numel(cfg.Stages)
for k = 3:3
    stage = cfg.Stages(k);

    fprintf("\n=====================================\n");
    fprintf("Starting Stage %d: %s\n", k, stage.Name);
    fprintf("=====================================\n");

    assignin("base","curriculumParams",stage.Reset);
    assignin("base","rewardParams",stage.Reward);

    agent = configureAgentForStage(agent, stage);

    trainOpts = rlTrainingOptions( ...
        MaxEpisodes=stage.MaxEpisodes, ...
        MaxStepsPerEpisode=ceil(cfg.Tf/cfg.Ts), ...
        Verbose=cfg.Verbose, ...
        Plots=cfg.PlotMode, ...
        StopTrainingCriteria=stage.StopTrainingCriteria, ...
        StopTrainingValue=stage.StopTrainingValue, ...
        UseParallel=cfg.UseParallel);

    if cfg.UseParallel
        trainOpts.ParallelizationOptions.Mode = "async";
        trainOpts.ParallelizationOptions.DataToSendFromWorkers = "experiences";
        trainOpts.ParallelizationOptions.StepsUntilDataIsSent = 32;
    end

    evl = rlEvaluator( ...
        EvaluationFrequency=stage.EvaluationFrequency, ...
        NumEpisodes=stage.EvaluationEpisodes);

    rng(stage.Seed,"twister");

    trainingStats = train(agent, env, trainOpts, Evaluator=evl);

    saveName = sprintf("%s_stage_%02d_%s.mat", ...
        cfg.SavePrefix, k, stage.Name);

    if cfg.SaveReplayBuffer
        agent.AgentOptions.SaveExperienceBufferWithAgent = true;
    else
        agent.AgentOptions.SaveExperienceBufferWithAgent = false;
    end

    if cfg.SaveTrainingStats
        save(saveName, "agent", "trainingStats", "stage");
    else
        save(saveName, "agent", "stage");
    end

    fprintf("Saved %s\n", saveName);

end

%% Final validation
simOpts = rlSimulationOptions( ...
    MaxSteps=ceil(cfg.Tf/cfg.Ts), ...
    StopOnError="on");

experiences = sim(env, agent, simOpts);

save(cfg.FinalSaveName, "agent", "experiences", "cfg");

set_param(mdl, FastRestart="off");
rng(previousRngState);