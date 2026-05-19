function agent = createDDPGAgent(obsInfo, actInfo, cfg)

%% Critic
obsPath = featureInputLayer(obsInfo.Dimension(1), Name="obsInLyr");
actPath = featureInputLayer(actInfo.Dimension(1), Name="actInLyr");

commonPath = [
    concatenationLayer(1,2,Name="concat")
    fullyConnectedLayer(25)
    reluLayer
    fullyConnectedLayer(25)
    reluLayer
    fullyConnectedLayer(1,Name="QValue")
];

criticNet = dlnetwork;
criticNet = addLayers(criticNet, obsPath);
criticNet = addLayers(criticNet, actPath);
criticNet = addLayers(criticNet, commonPath);

criticNet = connectLayers(criticNet,"obsInLyr","concat/in1");
criticNet = connectLayers(criticNet,"actInLyr","concat/in2");

rng(0,"twister");
criticNet = initialize(criticNet);

critic = rlQValueFunction( ...
    criticNet, obsInfo, actInfo, ...
    ObservationInputNames="obsInLyr", ...
    ActionInputNames="actInLyr");

%% Actor
actorNet = [
    featureInputLayer(obsInfo.Dimension(1), Name="obsInLyr")
    fullyConnectedLayer(25)
    reluLayer
    fullyConnectedLayer(25)
    reluLayer
    fullyConnectedLayer(actInfo.Dimension(1), Name="actOutLyr")
    sigmoidLayer(Name="boundedAction")
];

rng(0,"twister");
actorNet = dlnetwork(actorNet);

actor = rlContinuousDeterministicActor( ...
    actorNet, obsInfo, actInfo, ...
    ObservationInputNames="obsInLyr");

%% Agent
agent = rlDDPGAgent(actor, critic);

agent.AgentOptions.SampleTime = cfg.Ts;
agent.AgentOptions.DiscountFactor = 0.99;
agent.AgentOptions.MiniBatchSize = 256;
agent.AgentOptions.ExperienceBufferLength = 1e5;

agent.AgentOptions.ActorOptimizerOptions = rlOptimizerOptions( ...
    LearnRate=1e-4, ...
    GradientThreshold=1);

agent.AgentOptions.CriticOptimizerOptions = rlOptimizerOptions( ...
    LearnRate=1e-3, ...
    GradientThreshold=1);

end