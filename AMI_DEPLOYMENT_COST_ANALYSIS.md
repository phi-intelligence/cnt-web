# AMI-Based Deployment - Cost Analysis

## Cost Overview

### AMI Storage Costs

**AWS Pricing (eu-west-2 - London Region):**
- EBS Snapshot Storage: **$0.095 per GB per month** (first 50 GB)
- Additional tiers: $0.080/GB (next 450 GB), $0.060/GB (next 500 GB)

### Your Current AMI

- **AMI ID**: ami-013fb36a0ba6d426f
- **Size**: ~8-20 GB (typical range)
- **Monthly Cost**: ~**$0.80 - $1.90 per AMI**

### Real-World Cost Scenarios

#### Scenario 1: Single AMI (Current State)
- **Cost**: ~$1.00/month
- **When**: Keep only latest AMI
- **Best for**: Simple deployments, manual cleanup

#### Scenario 2: Multiple AMI Versions (Recommended)
- **AMIs Kept**: 3-5 versions (for rollback capability)
- **Cost**: ~$3.00 - $5.00/month
- **When**: Keep last few versions for quick rollback
- **Best for**: Production environments

#### Scenario 3: AMI Versioning with Cleanup
- **AMIs Kept**: Latest + 2 previous versions
- **Cost**: ~$3.00/month
- **Automated**: Delete AMIs older than 30 days
- **Best for**: Automated deployments with retention

## Cost Comparison

| Deployment Method | Monthly Cost | Notes |
|------------------|--------------|-------|
| **AMI-Based** | $1-5/month | Depends on versions kept |
| **Git-Based** | $0/month | Free (GitHub) |
| **S3-Based** | $0.20-0.50/month | Minimal storage/requests |
| **CodeDeploy** | $0.02/deployment | Plus instance costs |

## Cost Breakdown: AMI-Based Deployment

### Monthly Costs

1. **AMI Storage**
   - Single AMI: ~$1.00/month
   - 3-5 AMIs (recommended): ~$3-5/month
   - With cleanup policy: ~$2-3/month

2. **Data Transfer**
   - Within same region: **Free**
   - Cross-region: $0.02/GB (if applicable)

3. **Other Costs**
   - AMI creation: **Free** (included in EBS snapshot cost)
   - AMI registration: **Free**
   - AMI copying: **Free** (within region)

### Annual Costs

- **Single AMI**: ~$12/year
- **Multiple AMIs (3-5)**: ~$36-60/year
- **With cleanup**: ~$24-36/year

## Cost Optimization Strategies

### 1. Keep Minimal AMI Versions
- Keep only latest + 1-2 previous versions
- **Savings**: Reduces from $5/month to $2-3/month

### 2. Automated Cleanup
- Delete AMIs older than 30 days automatically
- Use AWS Lambda + EventBridge
- **Savings**: Reduces ongoing cost by 50-70%

### 3. Optimize AMI Size
- Don't include Docker images in AMI (pull at runtime)
- Exclude unnecessary files
- **Savings**: Reduces AMI size, reduces cost proportionally

### 4. Use Sparse Snapshots
- Only snapshot changed blocks
- **Savings**: 20-40% reduction if base AMI is reused

## Cost vs. Benefits Analysis

### AMI-Based Deployment Costs: ~$1-5/month

**Benefits Worth the Cost:**
- ✅ **Faster instance launch**: 2-3 minutes vs 4-5 minutes (saves compute time)
- ✅ **More reliable**: Pre-tested image
- ✅ **Easier rollback**: Instant rollback to previous AMI
- ✅ **Production-ready**: Industry standard for production
- ✅ **Immutable infrastructure**: Code is part of image

**Cost Impact:**
- $1-5/month is **negligible** compared to:
  - EC2 instance costs: $68/month (t3.large)
  - RDS costs: $15/month (db.t3.micro)
  - Total infrastructure: $100+/month

**Percentage of Infrastructure Cost:**
- AMI cost: ~1-5% of monthly infrastructure cost
- Very small impact on total cost

## Recommendation

### Cost-Effective Approach: AMI with Cleanup

**Strategy:**
1. Keep 3 AMI versions (latest + 2 previous)
2. Automate cleanup (delete AMIs older than 30 days)
3. Estimated cost: **~$2-3/month**

**Why This Works:**
- Low cost (~2-3% of infrastructure)
- Fast deployments
- Quick rollback capability
- Production-ready approach

### Alternative: Start with Git, Add AMI Later

**If Cost is Primary Concern:**
1. Start with Git-based deployment ($0/month)
2. Evaluate if AMI benefits are worth $2-3/month
3. Add AMI-based deployment later if needed

**When to Add AMI:**
- When you need faster deployments
- When you need reliable production deployments
- When $2-3/month is acceptable

## Real-World Example

**Your Infrastructure Costs:**
- EC2 (t3.large): $68/month
- RDS (db.t3.micro): $15/month
- ALB: ~$20/month
- S3 + CloudFront: ~$5-10/month
- Redis (ElastiCache): ~$15/month
- **Total: ~$125/month**

**Adding AMI-Based Deployment:**
- AMI storage (3 versions): +$3/month
- **New Total: ~$128/month**
- **Increase: +2.4%**

## Conclusion

### AMI-Based Deployment Cost: **Minimal**

- **Cost**: $1-5/month (typically $2-3/month with cleanup)
- **Impact**: ~2-4% of total infrastructure cost
- **Benefit**: Faster, more reliable deployments
- **Recommendation**: Worth the cost for production environments

### For Your Use Case

**If optimizing for cost:**
- Start with Git-based ($0/month)
- Add AMI later if needed (+$2-3/month)

**If optimizing for reliability/speed:**
- Use AMI-based from start ($2-3/month)
- Very small cost increase
- Better for production

**The cost is minimal and the benefits (speed, reliability, rollback) typically justify the small monthly cost.**


