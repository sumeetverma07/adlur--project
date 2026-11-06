# Operations Runbook

## Deployment failure

1. Check ALB healthy target count and ASG instance-refresh status.
2. Inspect cloud-init and container logs through AWS Systems Manager; never open SSH to the internet.
3. If the new image fails health checks, cancel or allow automatic rollback of the refresh and reapply the last known-good image digest.
4. Do not roll application code back after a destructive migration. Follow the migration incident path.
5. Save timestamps, digest, metrics, and commands under `evidence/`; remove credentials and customer data.

## High API latency or 5xx

1. Compare request rate, target response time, 5xx by ALB/target, and healthy target count.
2. Confirm ASG desired/in-service capacity and scaling activity.
3. Check RDS CPU, connections, I/O latency, locks, and slow queries; check Redis latency and evictions.
4. Scale application capacity only if the bottleneck is application compute. Increasing API instances can make an overloaded database worse.
5. Roll back the image when the regression aligns with a release and schema compatibility is safe.

## Queue backlog

1. Check queue depth, oldest-job age, arrival rate, completion rate, errors, and Redis health.
2. Stop rollout if job errors or duration increased with a new version.
3. Increase consumers only within database/downstream service limits.
4. During scale-in or deployment, stop polling, finish the current job, acknowledge it, then terminate.

## Database migration incident

1. Stop further deployments and destructive migration steps.
2. Determine whether old and new binaries are both compatible with the current schema.
3. Prefer a forward fix for additive changes. After destructive changes, use the tested restore procedure and replay plan.
4. Validate row counts, constraints, and application health before restoring traffic.

## RDS restore test

1. Record the latest restorable time and choose an isolated subnet/security group with no application traffic.
2. Restore to a new identifier; never overwrite the source database.
3. Run schema version, row-count, and representative read checks through a controlled SSM session.
4. Record recovery point and elapsed recovery time.
5. Obtain evidence approval, then delete the temporary database according to the change process.

## NAT or Availability Zone failure

The demo uses one NAT Gateway. Existing application traffic may continue, but image pulls and AWS public API calls from private subnets can fail. For production, provision one NAT per AZ and VPC endpoints for SSM, ECR, S3, CloudWatch, and Secrets Manager.
