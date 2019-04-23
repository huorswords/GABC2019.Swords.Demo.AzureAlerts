namespace Swords.Demo.AzureAlerts.ApiWithHealthChecks.Services
{
    public class HealthCheckCounter : IHealthCheckCounter
    {
        public HealthCheckCounter(int maximum)
        {
            Maximum = maximum;
        }

        public int Current { get; private set; }

        public int Maximum { get; private set; }

        public void Next()
        {
            this.Current++;
        }

        public void Reset()
        {
            this.Current = 0;
        }
    }
}
