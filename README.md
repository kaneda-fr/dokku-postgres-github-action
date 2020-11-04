# dokku-postgres

This action manage PostgreSQL database for your Dokku Application:
* DB deployments
* DB destruction
* Data Load from AWS S3 (Not Implemented yet)
* Scheduled backup to S3

## Inputs

### ssh-private-key

The private ssh key used for Dokku deployments. Never use as plain text! Configure it as a secret in your repository by navigating to https://github.com/USERNAME/REPO/settings/secrets

**Required**

### dokku-user

The user to use for ssh. If not specified, `dokku` user will be used.

### dokku-host

The Dokku host to deploy to.

### app-name

The Dokku app name to be deployed.

### db-name

The name of the database to be deployed.

### destroy

Destroy the DB if set to if set to `true`. If not specified, `false` will be used.

**Optional**

### aws-access-key-id

AWS access key id. **Required** if data load or backup are enabled.

### aws-secret-access-key

AWS secret access key. **Required** if data load or backup are enabled.

### s3-data-load

The S3 file name to import into the DB.

### backup-s3

The backup activation to an existing S3 bucket:
* Enable if set to `true`.
* Disable if set to `false`.

### backup-s3-bucket

The S3 bucket name used for backup. **Required** if backup enabled.

### backup-s3-schedule

The S3 bucket name used for backup. **Required** if backup enabled.

## Example

```
steps:
  - id: db
    name: Deploy dokku DB
    uses: kaneda-fr/dokku-postgres-github-action@v1
    with:
        ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
        dokku-host: 'my-dokku-host.com'
        app-name: 'my-dokku-app'
        db-name: 'my-db'
        aws-access-key-id: 'AKIAIOSFODNN7EXAMPLE'
        aws-secret-access-key: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY'
        s3-data-load: 's3://mybucket/database.dump'
        backup-activation: 'true'
        backup-s3-bucket: 'my-s3-bucket'
        backup-schedule: "0 3 * * *"
```
## TODO
* exit if an operation fails
