using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Swords.Demo.AzureAlerts.ApiWithHealthChecks.Services
{
    public interface IHealthCheckCounter
    {
        int Current { get; }
        int Maximum { get; }

        void Next();
        void Reset();
    }
}
