﻿using System;

using Microsoft.AspNetCore.Mvc;

using Swords.Demo.AzureAlerts.ApiWithHealthChecks.Services;
using Swords.Demo.AzureAlerts.Common;

namespace Swords.Demo.AzureAlerts.ApiWithHealthChecks.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PrimeController : ControllerBase
    {
        private readonly IPrimeSearcher primeSearcher;
        private readonly IHealthCheckCounter healthCheckCounter;

        public PrimeController(IPrimeSearcher primeSearcher, IHealthCheckCounter healthCheckCounter)
        {
            this.primeSearcher = primeSearcher ?? throw new ArgumentNullException(nameof(primeSearcher));
            this.healthCheckCounter = healthCheckCounter ?? throw new ArgumentNullException(nameof(healthCheckCounter));
        }

        [HttpGet("{position}")]
        public string Get(int position)
        {
            this.healthCheckCounter.Next();
            var value = primeSearcher.Find(position);
            return "Done! The " + position + "nth prime number is " + value;
        }
    }
}