# Jenkins Demo

## Introduction

This repo contains everything needed to create a Jenkins controller on AWS EC2 and configure it with Docker cloud agents. For demonstration sake, we will then create a pipeline to build the [taglib](https://github.com/taglib/taglib) library

Once the infrastructure is setup using terraform, you will need to manually install Jenkins on the EC2 instance, setup a github app and create a multibranch pipeline project in Jenkins.

:warning: **This setup is insecure and not meant for production** :warning:

## Installation

### Infrastructure (Terraform)

The infrastructure on which the controller and agents will run, will be deployed using terraform scripts located in the `./terraform` directory.

1. In AWS, create a bucket to store your state file (e.g. `tfstate-jenkins-demo`).

1. In the `main.tf` file, change the region to your prefered one and set the IAM role to one in your account which has the proper permission to deploy resources and for which you have the permission to assume.

1. In the `version.tf` file, replace the bucket by the one you created earlier and make sure the region is correct.

1. This terraform module expects a few variable to be set. You can create a `variable.tfvars` file or pass the variables one by one on the command line when applying. (See below for available variables).

1. Run `terraform init` to installed the required modules and providers.

1. Finally, apply the script using `terraform apply`.

#### Terraform module variables

| Variable name | Type | Required | Description |
|---|---|---|---|
| `ec2_key_name` | string | yes | Name of the EC2 key pair to use. This will be used to ssh into the instance to install Jenkins. |
| `ssh_ip_whitelist` | (list)string | yes | A list of IPs in CIDR notation from which you will be able to ssh into the Jenkins controller. |
| `jenkins` | map | N/A | see below |
| `jenkins.hosted_zone` | string | No (Unless `jenkins.hostname` is set) | Name of the Route53 zone where to create the record for the Jenkins instance. |
| `jenkins.hostname` | string | No (Unless `jenkins.hosted_zone` is set) | Jenkins controller hostname. |

### Jenkins installation

1. Once your infrastructure is deployed, ssh into the newly created instance. Start by creating a new folder and `cd` into it

    ```bash
    mkdir -p /home/ubuntu/jenkins_controller && cd /home/ubuntu/jenkins_controller
    ```

1. Copy the files from your local `./jenkins_controller` folder into the folder you just created on the EC2 instance. 

    ```bash
    # On your local machine
    scp -i /path/to/you/key jenkins_controller/* ubuntu@instance-ip-address:/home/ubuntu/jenkins_controller`
    ```

1. Then from the EC2 instance, build the custom image which will include the required plugins 

    ```bash
    sudo docker build -t jenkins-custom .
    ```

1. Start the docker-compose stack 

    ```bash
    sudo docker compose up -d
    ```

    This will create a Jenkins container and a socat container which allow your jenkins controller to start up docker cloud agents using the docker engine on which it is running.

1. Once the containers are up and running, retrieve the admin password created during the initial setup from the Jenkins controller. 

    ```bash
    sudo docker exec -ti jenkins cat /var/jenkins_home/secrets/initialAdminPassword
    ```

You can now connect to your Jenkins controller by navigating to `http://<jenkins_hostname>` or `http://<ec2_instance_public_ip>` and skip the initial start-up wizard.

### Docker cloud agent configuration

Once you're connect to your Jenkins controller, you need to setup a Docker cloud agent. The required plugin has been installed when building the custom image.

1. Click on **Manage Jenkins > Clouds > New cloud**.

1. Give it a name e.g. `local-docker-agent`, select the "Docker" type and click on "Create".

On the next screen, expand the "Docker Cloud details" section. 

1. In the **Docker Host URI** text field, type in `tcp://socat:2375`.

1. click on **Test connection**.

1. If the connection is successful, check the **Enabled** checkbox.

#### Custom Docker agent image

There are various agent images available in the jenkins repository with different built-in tools and languages. For the purpose of this demo, we will create a custom image which include the tools required to build the taglib library.

1. On the EC2 instance running Jenkins, create a new directory.

    ```
    mkdir /home/ubuntu/custom-docker-agent && cd /home/ubuntu/custom-docker-agent
    ```

1. Copy the custom-docker-agent Dockerfile from your machine to the EC2 instance

    ```
    # On your local machine
    scp -i /path/to/you/key custom-docker-agent/Dockerfile ubuntu@instance-ip-address:/home/ubuntu/custom-docker-agent`
    ```

1. Back on the EC2 instance, build the custom-docker-agent

    ```
    sudo docker build -t custom-docker-agent .
    ```

#### Docker agent templates

Once the connection details are set, we need to create a template which will tell Jenkins how we want our docker agent to be run.

1. Expand the "Docker Agent templates" section and click on "Add Docker Template".

1. Fill in the form as below:

    - **Labels**: Docker_Linux
    - **Name**: docker-linux-agent
    - **Docker Image**: custom-docker-agent
    - **Instance Capactiy**: 20
    - **Connect method**: Attach Docker container
    - **Pull Strategy**: Never Pull (this is to ensure we use the local image we built)

### Github App

#### Creating the Github App
We now need to setup a Github App which will allow Jenkins pipelines to receive webhooks, set commit statuses, read private repositories, etc.

1. On github, click on your profile picture then "Settings". To create a Github App for your organization, you need to do this from your organization page.

1. In the left sidebar, click on `Developper settings > GitHub Apps > New Github App`

1. Configure your app

    - Give your app a name (e.g. `jenkins-demo-myapp`)
    - Set the `Homepage URL` to your github page or Jenkins controller url.
    - Set the `Webhook URL` to the Jenkins controller webhook url (e.g. http://<jenkins_url>/github-webhook/).

1. Under `Repository permissions`, choose the following permissions:

    - **Administration**: Read-only
    - **Checks**: Read & write
    - **Contents**: Read-only
    - **Metadata**: Read-only
    - **Pull requests**: Read-only
    - **Commit statuses**: Read & write

1. Under Subscribe to events, select the following events:

    - **Check run**
    - **Check suite**
    - **Pull request**
    - **Push**
    - **Repository**

1. Click on Create Github App


#### Generating a private key for authenticating to the GitHub App

After you have created the GitHub App, you will need to generate a private key for authenticating to the GitHub App.

To generate a private key authenticating to the GitHub App:

1. On github, click on your profile picture then **Settings**.

1. In the left sidebar, click on **Developer settings > GitHub Apps**.

1. Select the GitHub App you just created.

1. Under Private keys, select Generate a private key option.

1. A private key in PEM format will be downloaded to your computer.

1. Convert the key to a format readable by Jenkins using the command below

    ```
    openssl pkcs8 -topk8 -inform PEM -outform PEM -in github-app-key.pem -out converted-github-app-key.pem -nocrypt
    ```

#### Installing the GitHub App

Finally, you must install the newly created app:

1. From the GitHub Apps settings page, select the GitHub App.

1. In the left sidebar, click on **Install App**.

1. Click on **Install** next to the organization or user account containing the correct repository.

1. Install the app on all repositories or select repositories.

#### Create the credentials in Jenkins

Now we need to add the Github App credentials to Jenkins.

1. From the Jenkins dashboard, click on **Manage Jenkins**.

1. In the **Security** section click on **Credentials**.

1. Click on the **(global)** domain then **Add Credentials**.

1. In the dropdown, select the type **Github App**

1. Fill in the details of your app:

    - **ID**: this is an internal ID for Jenkins. It's good practice to use the name of the Github App for that field (e.g. `jenkins-demo-myapp`).
    - **Description**: An optional description to help tell similar credentials apart.
    - **App ID**: The GitHub App ID can be found in the **About** section of your GitHub App under the **General** tab in GitHub.
    - **Key**: Click on **Add** and copy paste the value of the converted key you created earlier.

1. Click on **Test Connection** to confirm your app details are correct then click on **Create**.

## Create pipeline

We have now created the infrastructure to run Jenkins, installed and configured Jenkins and we have created a Github App to allow Jenkins to perform authenticated actions in Github. It is now time to create a pipeline to automate the build, test and deploy stages of the [taglib](https://github.com/taglib/taglib) repository.

### Create the Jenkins job

1. From the main dashboard of Jenkins, click on **Create a job**. 

1. Call it `taglib-pipeline`, select the type **Multibranch Pipeline** type of job and click **OK**.

1. (Optional) Set the display name to `Taglib Pipeline`.

1. (Optional) Write a description for the job.

1. In the **Branch Sources** section, click on **Add source** and select **GitHub**.

1. In the **Credentials** dropwdown, select the Github App you created earlier.

1. Type in the HTTPS url of your fork of taglib. (e.g. `https://github.com/my-account/taglib.git`) and click **Validate**.

1. When the connection is successfull, click on **Save**. The options can stay as default for now.

### Automate building the taglib library

Now that the Jenkins setup is complete, we can go ahead and automate the building, testing and packaging of the taglib library.

1. Fork the taglib repository in your account.

1. Clone the repository to your local machine.

1. Create a new branch (e.g. jenkins-cicd).

1. Copy paste the provided `Jenkinsfile` in the `taglib_example` directory at the root of the taglib repo.

1. Commit the new file and push to your branch.

Thanks to the Github App we created, this will send a push event to Jenkins which will trigger the pipeline defined in the Jenkinsfile. Once the pipeline completed successfully, Jenkins will then make a POST request to Github to mark the commit as successful.

## Improvements

- Set up Jenkins in a private subnet.
- Use an ELB to handle SSL termination and route traffic to the private controller.
- Setup agents for different platforms and using different cloud providers.
- Use [JCasC](https://www.jenkins.io/projects/jcasc/) to be able to configure Jenkins controllers using a conf file. ("as code" paradigm)
- Explore similar "as code" solutions for Jenkins jobs. Such as [Job DSL](https://plugins.jenkins.io/job-dsl/)
- Post notification to Slack, Teams or other communication platforms when a pipeline passes or fails.
