using Microsoft.Extensions.Diagnostics.HealthChecks;
using Swords.Demo.AzureAlerts.ApiWithHealthChecks.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace Swords.Demo.AzureAlerts.ApiWithHealthChecks.HealthChecks
{
    public class CounterHealthCheck : IHealthCheck
    {
        private readonly IHealthCheckCounter healthCheckCounter;

        public CounterHealthCheck(IHealthCheckCounter healthCheckCounter)
        {
            // Use dependency injection (DI) to supply any required services to the
            // health check.
            this.healthCheckCounter = healthCheckCounter;
        }

        public Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default(CancellationToken))
        {
            // Execute health check logic here. This example sets a dummy
            // variable to true.
            var healthCheckResultHealthy = this.healthCheckCounter.Current < healthCheckCounter.Maximum;

            if (healthCheckResultHealthy)
            {
                return Task.FromResult(
                    HealthCheckResult.Healthy("The check indicates a healthy result."));
            }

            return Task.FromResult(
                HealthCheckResult.Unhealthy("The check indicates an unhealthy result."));
        }
    }
}
