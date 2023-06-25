using KubeOps.Operator;

// Builder
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddKubernetesOperator();

// App
var app = builder.Build();

app.UseKubernetesOperator();

// Run
await app.RunOperatorAsync(args);
