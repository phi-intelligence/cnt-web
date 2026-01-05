# Phase 0: Monitoring Setup - COMPLETE

**Date**: January 3, 2026  
**Status**: ✅ Complete

## Completed Tasks

### 1. CloudWatch Detailed Monitoring
- **Status**: ✅ Enabled
- **Instance**: i-03106a794959d37ab
- **Region**: eu-west-2
- **Result**: Detailed monitoring enabled (1-minute metrics)

### 2. CloudWatch Dashboard
- **Dashboard Name**: cnt-scaling-dashboard
- **Region**: eu-west-2
- **Metrics Included**:
  - EC2: CPU Utilization, Network In/Out
  - RDS: CPU Utilization, Database Connections, Freeable Memory
  - ALB: Target Response Time, HTTP 2XX/5XX Counts, Unhealthy Host Count
- **Result**: Dashboard created and accessible in CloudWatch console

### 3. Scaling Decision Alarms
All alarms created and configured with SNS topic: `arn:aws:sns:eu-west-2:649159624630:cnt-billing-alerts`

#### Alarms Created:
1. **cnt-ec2-cpu-high**
   - Metric: CPUUtilization > 70%
   - Period: 5 minutes
   - Purpose: Scale-up trigger
   - Status: ✅ Created (INSUFFICIENT_DATA - normal until metrics collected)

2. **cnt-ec2-cpu-low**
   - Metric: CPUUtilization < 30%
   - Period: 15 minutes
   - Purpose: Scale-down trigger
   - Status: ✅ Created (INSUFFICIENT_DATA)

3. **cnt-rds-connections-high**
   - Metric: DatabaseConnections > 20 (80% of db.t3.micro limit)
   - Period: 5 minutes
   - Purpose: Alert when database connections approaching limit
   - Status: ✅ Created (INSUFFICIENT_DATA)

4. **cnt-alb-unhealthy-hosts**
   - Metric: UnHealthyHostCount > 0
   - Period: 1 minute
   - Purpose: Alert when ALB targets are unhealthy
   - Status: ✅ Created (INSUFFICIENT_DATA)

5. **cnt-alb-response-time-high**
   - Metric: TargetResponseTime > 2 seconds (average)
   - Period: 5 minutes
   - Purpose: Alert when response times degrading
   - Status: ✅ Created (INSUFFICIENT_DATA)

## Next Steps

### Ongoing Activity: Baseline Monitoring
- **Duration**: 1-2 weeks recommended
- **Purpose**: Establish baseline metrics to make data-driven scaling decisions
- **Action**: Monitor CloudWatch dashboard and alarms regularly
- **Decision Point**: After 1-2 weeks, review metrics to determine if scaling is needed

### When to Proceed to Phase 2/3/4
Scale infrastructure ONLY when metrics indicate:
- CPU utilization consistently > 70% for 5+ minutes
- Memory usage consistently > 80%
- Database connections exhausted (>80% of limit)
- Response times degrading (>2 seconds average)
- Error rates increasing (>1%)
- Health check failures

## Monitoring Dashboard Access

**CloudWatch Console**:
- Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=eu-west-2#dashboards:name=cnt-scaling-dashboard
- Alarms: https://console.aws.amazon.com/cloudwatch/home?region=eu-west-2#alarmsV2:

## Notes

- All alarms are in INSUFFICIENT_DATA state initially (normal - they need time to collect metrics)
- Alarms will transition to OK/ALARM states as metrics are collected
- SNS topic `cnt-billing-alerts` is configured for alarm notifications
- Monitoring infrastructure is ready to inform scaling decisions


