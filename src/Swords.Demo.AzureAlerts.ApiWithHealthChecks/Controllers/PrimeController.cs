using System;

using Microsoft.AspNetCore.Mvc;

using Swords.Demo.AzureAlerts.Common;

namespace Swords.Demo.AzureAlerts.ApiWithHealthChecks.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PrimeController : ControllerBase
    {
        private readonly IPrimeSearcher primeSearcher;

        public PrimeController(IPrimeSearcher primeSearcher)
        {
            this.primeSearcher = primeSearcher ?? throw new ArgumentNullException(nameof(primeSearcher));
        }

        [HttpGet("{position}")]
        public string Get(int position)
        {
            var value = primeSearcher.Find(position);
            return "Done! The " + position + "nth prime number is " + value;
        }
    }
}