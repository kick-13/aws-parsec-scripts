$continue = $true
while($continue){
    # Prompt for action
    Write-Host "Choose an action:"
    Write-Host "1. Start instance"
    Write-Host "2. Terminate instance"
    Write-Host "3. Restart instance"
    Write-Host "4. Create snapshot"
    Write-Host "5. Delete snapshot"
    Write-Host "6. Connect via RDP"
    Write-Host "7. Exit"
    $choice = Read-Host "Enter a number"

    # Perform the action
    switch ($choice) {
        '1' { # Start
            # Listing AWS EC2 Images
            $ami_list = aws ec2 describe-images `
                --owners self `
                --query "Images[*].{`Name:Name, Id:ImageId, CreationDate:CreationDate, SnapshotId:BlockDeviceMappings[*].Ebs.SnapshotId}" `
                --output json | ConvertFrom-Json
            Write-Host "Select Image to launch server from"
            $ami = $ami_list | Out-GridView -Title "Select Image to launch server from" -OutputMode Single

            if ($ami -eq $null) {
                break
            } else {
                $name = Read-Host "Enter name of the instance"
                $count = Read-Host "Enter how many instances to launch"
                # $instance_type = Read-Host "Enter an instance type:"
                # $region = Read-Host "Enter region:"
                $instance_type = 'g4dn.xlarge'
                $region = aws configure get region

                # Creating Security Group
                Write-Host "Creating security group..."
                $sg_id = $(aws ec2 create-security-group `
                    --group-name "$name-security-group" `
                    --description "AWS Parsec Security Group for $name" `
                    | ConvertFrom-Json).GroupId

                # Launching EC2 Instance from AMI
                Write-Host "Starting instance from image $($ami.Name) in $region..."
                $instance_id = $(aws ec2 run-instances `
                    --image-id $($ami.Id) `
                    --instance-type $instance_type `
                    --security-group-ids $sg_id `
                    --count $count `
                    --region $region `
                    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" `
                    | ConvertFrom-Json).Instances.Id
                aws ec2 wait instance-running --instance-ids $instance_id

                Write-Host "Instance $name launched in $region!"
            }
        } '2' { # Terminate
            $instance_list = aws ec2 describe-instances `
                --filters "Name=instance-state-name,Values=running,stopped" `
                --query "Reservations[*].Instances[*].{`Id:InstanceId, Name:Tags[?Key=='Name']|[0].Value, State:State.Name, Type:InstanceType, Region:Placement.AvailabilityZone}" | ConvertFrom-Json
            Write-Host "Select Instance to terminate"
            $instance = $instance_list `
                | Select-Object -ExpandProperty SyncRoot `
                | Out-GridView -Title "Select Instance to terminate" -OutputMode Single
            if ($instance -eq $null) {
                break
            } else {
                $sg_id = aws ec2 describe-instances `
                    --instance-ids $($instance.Id) `
                    --query "Reservations[*].Instances[*].SecurityGroups[*].GroupId" `
                    --output text

                Write-Host "Terminating instance $($instance.Name) in $($instance.Region)...."
                aws ec2 terminate-instances --instance-ids $($instance.Id) | Out-Null
                aws ec2 wait instance-terminated --instance-ids $($instance.Id)

                Write-Host "Deleting associated security group..."
                aws ec2 delete-security-group --group-id $sg_id

                Write-Host "Instance $($instance.Name) terminated."
            }
        } '3' { # Restart
            $instance_list = aws ec2 describe-instances `
                --filters "Name=instance-state-name,Values=running" `
                --query "Reservations[*].Instances[*].{`Id:InstanceId, Name:Tags[?Key=='Name']|[0].Value, State:State.Name, Type:InstanceType, Region:Placement.AvailabilityZone}" | ConvertFrom-Json
            Write-Host "Select Instance to restart"
            $instance = $instance_list `
                | Select-Object -ExpandProperty SyncRoot `
                | Out-GridView -Title "Select Instance to restart" -OutputMode Single

            if ($instance -eq $null) {
                break
            } else {
                Write-Host "Restarting instance $($instance.Name) in $($instance.Region)..."
                aws ec2 reboot-instances --instance-ids $($instance.Id) | Out-Null
                aws ec2 wait instance-running --instance-ids $instance_id

                # # Stop the instance
                # Write-Host "Stopping instance $($instance.Name) in $($instance.Region)..."
                # aws ec2 stop-instances --instance-ids $($instance.Id) | Out-Null

                # # Wait until the instance is stopped
                # Write-Host "Waiting for the instance to stop..."
                # aws ec2 wait instance-stopped --instance-ids $($instance.Id)

                # # Start the instance
                # Write-Host "Starting instance $($instance.Name) in $($instance.Region)..."
                # aws ec2 start-instances --instance-ids $($instance.Id) | Out-Null
                # aws ec2 wait instance-running --instance-ids $instance_id

                Write-Host "Instance $($instance.Name) restarted successfully."
            }
        } '4' { # create snapshot
            # choose a server
            $instance_list = aws ec2 describe-instances `
                --filters "Name=instance-state-name,Values=running" `
                --query "Reservations[*].Instances[*].{`Id:InstanceId, Name:Tags[?Key=='Name']|[0].Value, State:State.Name, Type:InstanceType, Region:Placement.AvailabilityZone}" | ConvertFrom-Json
            Write-Host "Select Instance to create snapshot"
            $instance = $instance_list `
                | Select-Object -ExpandProperty SyncRoot `
                | Out-GridView -Title "Select Instance to create snapshot" -OutputMode Single

            if ($instance -eq $null) {
                break
            } else {
                # Stop the instance
                Write-Host "Stopping instance $($instance.Name) in $($instance.Region)..."
                aws ec2 stop-instances --instance-ids $($instance.Id) | Out-Null

                # Wait until the instance is stopped
                Write-Host "Waiting for the instance to stop..."
                aws ec2 wait instance-stopped --instance-ids $($instance.Id)

                # create image - input name
                $snapshot_name = Read-Host "Enter a snapshot name"
                Write-Host "Creating image of $($instance.Name)..."
                $image_id = $(aws ec2 create-image `
                    --instance-id $($instance.Id) `
                    --name $snapshot_name `
                    | ConvertFrom-Json).ImageId

                # wait until complete
                aws ec2 wait image-available --image-ids $image_id

                # ask if server terminates or start up
                $choice = Read-Host "Choose either terminate or start server"
                switch ($choice) {
                    'terminate' {
                        $sg_id = aws ec2 describe-instances `
                            --instance-ids $($instance.Id) `
                            --query "Reservations[*].Instances[*].SecurityGroups[*].GroupId"$

                        Write-Host "Terminating instance $($instance.Name) in $($instance.Region)...."
                        aws ec2 terminate-instances --instance-ids $($instance.Id) | Out-Nul$l

                        Write-Host "Deleting associated security group..."
                        aws ec2 delete-security-group --group-id $sg_id

                        Write-Host "Instance $($instance.Name) terminated."
                    } 'start' {
                        # Start the instance
                        Write-Host "Starting instance $($instance.Name) in $($instance.Region)..."
                        aws ec2 start-instances --instance-ids $($instance.Id) | Out-Null

                        Write-Host "Instance $($instance.Name) restarted successfully."
                    }
                }
            }
        } '5' { # delete snapshot
            # Listing AWS EC2 Images
            $ami_list = aws ec2 describe-images `
                --owners self `
                --query "Images[*].{`Name:Name, Id:ImageId, CreationDate:CreationDate, SnapshotId:BlockDeviceMappings[*].Ebs.SnapshotId}" `
                --output json | ConvertFrom-Json
            Write-Host "Select Image to delete"
            $ami = $ami_list | Out-GridView -Title "Select Image to delete" -OutputMode Single

            if ($instance -eq $null) {
                break
            } else {
                # delete snapshot
                Write-Host "Deregistering $($ami.Name)..."
                aws ec2 deregister-image --image-id $($ami.Id)

                Write-Host "Deleting associated snapshot..."
                aws ec2 delete-snapshot --snapshot-id $($ami.SnapshotId)

                Write-Host "AMI deregistration complete!"
            }
        } '6' { # RDP
            $instance_list = aws ec2 describe-instances `
                --filters "Name=instance-state-name,Values=running" `
                --query "Reservations[*].Instances[*].{`Id:InstanceId, Name:Tags[?Key=='Name']|[0].Value, State:State.Name, Type:InstanceType, Region:Placement.AvailabilityZone, DnsName:PublicDnsName}" | ConvertFrom-Json
            Write-Host "Select Instance to connect to"
            $instance = $instance_list `
                | Select-Object -ExpandProperty SyncRoot `
                | Out-GridView -Title "Select Instance to connect to" -OutputMode Single
            if ($instance -eq $null) {
                break
            } else {
                $sg_id = aws ec2 describe-instances `
                    --instance-ids $($instance.Id) `
                    --query "Reservations[*].Instances[*].SecurityGroups[*].GroupId" `
                    --output text

                Write-Host "Creating security group rules..."
                aws ec2 authorize-security-group-ingress `
                    --group-id $sg_id `
                    --protocol tcp `
                    --port 3389 `
                    --cidr "$($(Invoke-WebRequest -UseBasicParsing http://whatismyip.akamai.com/).Content)/32" `
                    --region $($instance.Region).Substring(0, $($instance.Region).Length - 1) | Out-Null

                # RDP into public DNS
                mstsc /v:$($instance.DnsName)
                Write-Host "Log in with username Administrator"
            }
        } '7' {
            Write-Host "Exiting script."
            $continue = $false
        } Default {
            Write-Host "Invalid choice. Exiting script."
            $continue = $false
        }
    }
}

