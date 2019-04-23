using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Swords.Demo.AzureAlerts.ApiWithHealthChecks.HealthChecks;
using Swords.Demo.AzureAlerts.ApiWithHealthChecks.Services;
using Swords.Demo.AzureAlerts.Common;

namespace Swords.Demo.AzureAlerts.ApiWithHealthChecks
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddSingleton<IPrimeSearcher, PrimeSearcher>();
            services.AddSingleton<IHealthCheckCounter, HealthCheckCounter>(factory => new HealthCheckCounter(10));
            services.AddHealthChecks()
                    .AddCheck<CounterHealthCheck>("example_health_check"); ;
            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_2);
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            else
            {
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
            }

            app.UseHealthChecks("/health");
            app.UseHttpsRedirection();
            app.UseMvc();
        }
    }
}