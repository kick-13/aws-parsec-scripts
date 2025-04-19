
# aws-parsec-script

This script aims to smoothen the experience of starting up an AWS server for Parsec Gaming.

## Pre-requisites
- An AWS Server - Installation guide [here](https://t.co/ZAag0VI9Jh)
- AWS CLI - command line for AWS to execute the script remotely - Installation guide [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## Initial Setup
### IAM User
1. On the AWS console, search for IAM in the searchbar at the top.
2. Click on `Users` on the right side dashboard. Then click on `Create User` on the top right.
3. Enter a name for the user. This can be anything you want. Click `Next` when done.
4. Click on `Attach policies directly` and then click on `Create policy`. This should open a new tab to create an IAM policy.
5. Click on `JSON` and then replace the whole policy with the policy below.
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2Actions",
            "Effect": "Allow",
            "Action": [
                "ec2:DeregisterImage",
                "ec2:DeleteSnapshot",
                "ec2:TerminateInstances",
                "ec2:StartInstances",
                "ec2:CreateSecurityGroup",
                "ec2:CreateTags",
                "ec2:DeleteSecurityGroup",
                "ec2:CreateImage",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RebootInstances"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SupplementaryActions",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "ssm:GetParameters"
            ],
            "Resource": [
                "arn:aws:iam::645434766026:role/*",
                "arn:aws:ssm:*:645434766026:parameter/*"
            ]
        }
    ]
}
```
Click on `Next` when done.

6. Enter a policy name. Click on `Create Policy` when done. Close the tab when it is completed to go back to the IAM User creation page.
7. Now we are going to add two IAM policies to this user.In the searchbar under Permission policies, type in the name you've given to the policy you created. Click on the tickbox.
8. Now search for `AmazonEC2ReadOnlyAccess` and click on the tickbox. Click `Next`.
9. Click on `Create User` at the bottom.

### Access Keys
1. Click on `Users` on the right side dashboard. Click on your new user you've just created.
2. Click on the `Security credentials` tab. Click on `Create access key` under Access keys.
3. Click on `Other` at the bottom and then click on `Next`.
4. Click on `Create access key`.
5. Copy both the Access key and Secret access key into notepad. We will be using these values later. Click on `Done`.

### aws configure
1. Open up Powershell and enter `aws configure`.
2. Enter your Access key and Secret access key that are kept on your notepad.
3. Enter the region that you want to execute the script under. The list of regions are listed [here](https://docs.aws.amazon.com/global-infrastructure/latest/regions/aws-regions.html).
4. Just press Enter when it asks for `Default output format`.
