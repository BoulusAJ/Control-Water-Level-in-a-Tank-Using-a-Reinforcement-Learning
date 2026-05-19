function agent = configureAgentForStage(agent, stage)

agent.AgentOptions.NoiseOptions.StandardDeviation = stage.NoiseStd;
agent.AgentOptions.NoiseOptions.StandardDeviationDecayRate = stage.NoiseDecay;

agent.AgentOptions.ResetExperienceBufferBeforeTraining = stage.ResetBuffer;

end