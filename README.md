This guide describes how to build a Wordpress application stack using Chef cookbooks available from the [Cookbooks Community Site](http://cookbooks.opscode.com) and Hosted Chef. It assumes you have Chef installed.  

*This guide uses Ubuntu 12.10 on Amazon AWS EC2 with Chef 10.**

***Note:** At this time, the steps described above have only been tested on the identified platform(s).  Opscode has not researched and does not support alternative steps that may lead to successful completion on other platforms.  Platform(s) supported by this guide may change over time, so please do check back for updates.  If you'd like to undertake this guide on an alternate platform, you may desire to turn to open source community resources for support assistance.*

At the end of this guide, you'll have four total Ubuntu 12.10 systems running in Amazon EC2.

- 1 haproxy load balancer.
- 2 Wordpress application servers.
- 1 MySQL database server.

We're going to reuse a number of cookbooks from the [Cookbooks Community Site](http://cookbooks.opscode.com) to build the environment. For example, the source code lives in **git**, so that cookbook will ensure Git is available. The load balancer is **haproxy** because it is very simple to deploy and configure, and we use a recipe that automatically discovers the Wordpress application systems. 

If you don't already have an account with Amazon AWS, go to [Amazon Web Sevices](http://aws.amazon.com/) and click "Sign up". You'll need the access and secret access key credentials from the sign-up later.

Environment Setup
----

First, let's configure the local workstation.

### Shell Environment

Obtain the repository used for this guide. It contains all the components required. Use git:

    git clone git://github.com/opscode/wordpress-quick-start.git

### Chef and Knife

*Ubuntu/Debian users*: Install XML2 and XLST development headers on your system:

    sudo apt-get install libxml2-dev libxslt-dev

*All Users*: You'll need some additional gems for Knife to launch instances in Amazon EC2:

    sudo gem install knife-ec2

As part of your initial set-up, you should have copied Knife configuration file (knife.rb), validation certificate (ORGNAME-validator.pem) and user certificate (USERNAME.pem) to **~/.chef/**. Copy these files to the new wordpress-quick-start repository. 

    mkdir ~/wordpress-quick-start/.chef
    cp ~/chef-repo/.chef/knife.rb ~/wordpress-quick-start/.chef
    cp ~/chef-repo/.chef/USERNAME.pem ~/wordpress-quick-start/.chef
    cp ~/chef-repo/.chef/ORGNAME-validator.pem ~/wordpress-quick-start/.chef

Add the Amazon AWS credentials to the Knife configuration file.

    vi ~/wordpress-quick-start/.chef/knife.rb

Add the following two lines to the end:

    knife[:aws_access_key_id] = "replace with the Amazon Access Key ID"
    knife[:aws_secret_access_key] =  "replace with the Amazon Secret Access Key ID"

Once the wordpress-quick-start and knife configuration is in place, we'll work from this directory.

    cd wordpress-quick-start

### Amazon AWS EC2

In addition to the credentials, two additional things need to be configured in the AWS account.

Configure the default [security group](http://docs.amazonwebservices.com/AWSEC2/latest/DeveloperGuide/index.html?using-network-security.html) to allow incoming connections for the following ports.

* 22 - ssh
* 80 - haproxy load balancer
* 22002 - haproxy administrative interface
* 3306 - MySQL database

Add these to the default security group for the account using the AWS Console.

1. Sign into the [Amazon AWS Console](https://console.aws.amazon.com/s3/home).
2. Click on the "Amazon EC2" tab at the top.
3. Click on "Security Groups" in the left sidebar of the AWS Console.
4. Select the "Default" group in the main pane.
5. Enter the values shown for each of the ports required. Use "Custom" in the drop-down for 22002 and 3306.

Create an [SSH Key Pair](http://docs.amazonwebservices.com/AWSEC2/latest/DeveloperGuide/index.html?using-credentials.html#using-credentials-keypair) and save the private key in **~/.ssh**.

1. In the AWS Console, click on "Key Pairs" in the left sidebar.
2. Click on "Create Keypair" at the top of the main pane.
3. Give the keypair a name like "wordpress-quick-start".
4. The keypair will be downloaded automatically by the browser and saved to the default Downloads location.
5. Move the wordpress-quick-start.pem file from the default Downloads location to **~/.ssh** and change permissions so that only you can read the file.  For example,

    mv ~/Downloads/wordpress-quick-start.pem ~/.ssh  
    chmod 600 ~/.ssh/wordpress-quick-start.pem

Acquire Cookbooks
----

The wordpress-quick-start has all the cookbooks we need for this guide. They were downloaded along with their dependencies from the cookbooks site using Knife. These are in the **cookbooks/** directory.

    apt
    aws
    build-essential
    chef-client
    chef_handler
    cpu
    cron
    database
    dmg
    quick-start-database
    quick-start-loadbalancer
    quick-start-wordpress
    git
    haproxy
    mysql
    openssl
    php
    postgresql
    runit
    sudo
    users
    windows
    wordpress
    xfs
    xml
    yum
    zsh

Upload all the cookbooks to Hosted Chef.

    knife cookbook upload -a

Server Roles
------------

All the required roles have been created in the wordpress-quick-start repository. They are in the **roles/** directory.

    base.json
    database-server.json
    application-server.json
    load-balancer.json

Upload all the roles to Hosted Chef.

    knife role from file roles/*.json 

Decision Time
====
We're going to use m1.small instances with the 64 bit Ubuntu 12.10 image provided [by Canonical](http://uec-images.ubuntu.com/releases/quantal/release-20121218/). The identifier is **ami-9b3db0f2** for the AMI in us-east-1 with instance storage that we will use in this guide.  We'll show you the **knife ec2 server create** sub-command to launch instances.

This command will:

* Launch a server on EC2.
* Connect it to Hosted Chef.
* Configure the system with Chef.

Launch Multi-instance Infrastructure
----

We will launch one database server, two application servers and one load balancer.

First, launch the database instance.

    knife ec2 server create -G default -I ami-9b3db0f2 -f m1.small \
      -S wordpress-quick-start -i ~/.ssh/wordpress-quick-start.pem -x ubuntu \
      -r 'role[database-server]'

Once the database master is up, launch the two application nodes.

    knife ec2 server create -G default -I ami-9b3db0f2 -f m1.small \
      -S wordpress-quick-start -i ~/.ssh/wordpress-quick-start.pem -x ubuntu \
      -r 'role[application-server]'

    knife ec2 server create -G default -I ami-9b3db0f2 -f m1.small \
      -S wordpress-quick-start -i ~/.ssh/wordpress-quick-start.pem -x ubuntu \
      -r 'role[application-server]'

Once the second application instance is up, launch the load balancer.

    knife ec2 server create -G default -I ami-9b3db0f2 -f m1.small \
      -S wordpress-quick-start -i ~/.ssh/wordpress-quick-start.pem -x ubuntu \
      -r 'role[load-balancer]'

Once complete, we'll have four instances running in EC2 with MySQL, Wordpress and haproxy up and available to serve traffic.

Verification
----

Knife will output the fully qualified domain name of the instance when the commands complete. Navigate to the public fully qualified domain name on port 80:

    http://ec2-xx-xxx-xx-xxx.compute-1.amazonaws.com/

You can access the haproxy admin interface at:

    http://ec2-xx-xxx-xx-xxx.compute-1.amazonaws.com:22002/

Appendix
----

### A Note about EC2 Instances

We used m1.small instances. This is a low performance instance size in EC2 and just fine for testing. Visit the Amazon AWS documentation to [learn more about instance sizes](http://aws.amazon.com/ec2/instance-types/).
