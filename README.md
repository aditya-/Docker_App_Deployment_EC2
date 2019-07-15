# Docker_Jenkins_web_app_EC2_Deployment

This continution of could provisioning of EC2 Docker Host machine, This Repository deals with java based Dockerized Application Container Deployment through **Docker compose** and Docker file scripting, Further shipping **Re-producible docker images** through Jenkins Pipeline(Continuous-Integration and Continuous-Deployment Pipeline). 

This repository is tries to exemplify how to automatically manage the process of building and deployment phases. 

First we will setup the Container infrastructure through docker-compose and docker file scripting then ensure to build reproducible docker images with Jenkins pipeline whenver we find any changes in application code. 

To ensure building of reproducible docker images, we will be provisioning a Jenkins container then we will add Jenkins Pipeline script and Git Webhook Configuration to oensure ur pipeline works well after each code being pushed.

We can further Scale and Orchestrate the above Application through **Kubernetes** or other scaling solutions. 

Following are the pipeline stages of Jenkins Docker Image Build Pipeline:

* Code checkout
* Create Docker image
* Push the image to Docker Hub
* Create the container with port mappings


## First step, running up the services

Since one of the goals is to obtain the ``sonarqube`` report of our project, we should be able to access sonarqube from the jenkins service. ``Docker compose`` is a best choice to run services working together. We configure our application services in a yaml file as mentioned below.

``docker-compose.yml``
```yml
version: "3.1"

services:
  reverse_proxy:
    build: ./reverse_proxy
    user: nginx

  appserver:
    build:
       context: app
       dockerfile: Dockerfile
    container_name: appserver
    user: app
    ports:
      - "5005:5005"
    networks:
      - front-tier
      - back-tier

  jenkins:
    build:
      context: jenkins/
    privileged: true
    user: root
    ports:
      - 8080:8080
      - 50000:50000
    container_name: jenkins
    volumes:
      - /tmp/jenkins:/var/jenkins_home #Remember that, the tmp directory is designed to be wiped on system reboot.
      - /var/run/docker.sock:/var/run/docker.sock

networks:
  front-tier:
  back-tier:
    driver: overlay

```
**Self-Signed SSL Gen:**
This application uses Docker secrets to secure the application components such as self-signed certificates. The reverse proxy requires creating a certificate that is stored as a secret. To create a certificate and add as a secret, run the following commands in Docker Server Machine:

```
mkdir certs

openssl req -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key -x509 -days 365 -out certs/domain.crt

docker secret create revprox_cert certs/domain.crt

docker secret create revprox_key certs/domain.key

```

Paths of docker files of the containers are specified at context attribute in the docker-compose file. Content of these files as follows.


``jenkins/Dockerfile``
```
FROM jenkins:2.60.3
```

If we run the following command in the same directory as the ``docker-compose.yml`` file, the Sonarqube and Jenkins containers will up and run.

```
docker-compose -f docker-compose.yml up --build
```

```
docker ps

CONTAINER ID        IMAGE                COMMAND                  CREATED              STATUS              PORTS                                              NAMES
87105432d655        pipeline_jenkins     "/bin/tini -- /usr..."   About a minute ago   Up About a minute   0.0.0.0:8080->8080/tcp, 0.0.0.0:50000->50000/tcp   jenkins
f5bed5ba3266        appserver   "./bin/run.sh"           About a minute ago   Up About a minute   0.0.0.0:5005->5005/tcp,      appserver
f5bed5ba3288        reverse_proxy   "./bin/run.sh"           About a minute ago   Up About a minute   0.0.0.0:80->80/tcp,      reverse_proxy
```

## GitHub configuration
* We’ll define a service on Github to call the ``Jenkins Github webhook`` because we want to trigger the pipeline. To do this go to _Settings -> Integrations & services._ The ``Jenkins Github plugin`` 

* After this, we should add a new service by typing the URL of the dockerized Jenkins container along with the ``/github-webhook/`` path.

* The next step is that create an ``SSH key`` for a Jenkins user and define it as ``Deploy keys`` on our GitHub repository.

* If everything goes well, the following connection request should return with a success.
```
ssh git@github.com
PTY allocation request failed on channel 0
Hi <your github username>/<repository name>! You've successfully authenticated, but GitHub does not provide shell access.
Connection to github.com closed.
```

## Jenkins configuration

We have configured Jenkins in the docker compose file to run on port 8080 therefore if we visit http://localhost:8080 we will be greeted with a screen like this.

![](images/004.png)

We need the admin password to proceed to installation. It’s stored in the ``/var/jenkins_home/secrets/initialAdminPassword`` directory and also It’s written as output on the console when Jenkins starts.

```
jenkins      | *************************************************************
jenkins      |
jenkins      | Jenkins initial setup is required. An admin user has been created and a password generated.
jenkins      | Please use the following password to proceed to installation:
jenkins      |
jenkins      | 45638c79cecd4f43962da2933980197e
jenkins      |
jenkins      | This may also be found at: /var/jenkins_home/secrets/initialAdminPassword
jenkins      |
jenkins      | *************************************************************
```

To access the password from the container.

```
docker exec -it jenkins sh
/ $ cat /var/jenkins_home/secrets/initialAdminPassword
```

After entering the password, we will download recommended plugins and define an ``admin user``.

![](images/005.png)

![](images/006.png)

![](images/007.png)

After clicking **Save and Finish** and **Start using Jenkins** buttons, we should be seeing the Jenkins homepage. One of the seven goals listed above is that we must have the ability to build an image in the Jenkins being dockerized. Take a look at the volume definitions of the Jenkins service in the compose file.
```
- /var/run/docker.sock:/var/run/docker.sock
```

The purpose is to communicate between the ``Docker Daemon`` and the ``Docker Client``(_we will install it on Jenkins_) over the socket. Like the docker client, we also need ``Maven`` to compile the application. For the installation of these tools, we need to perform the ``Maven`` and ``Docker Client`` configurations under _Manage Jenkins -> Global Tool Configuration_ menu.

![](images/008.png)

We have added the ``Maven and Docker installers`` and have checked the ``Install automatically`` checkbox. These tools are installed by Jenkins when our script(Jenkins file) first runs. We give ``myMaven`` and ``myDocker`` names to the tools. We will access these tools with this names in the script file.

Since we will perform some operations such as ``checkout codebase`` and ``pushing an image to Docker Hub``, we need to define the ``Docker Hub Credentials``. Keep in mind that if we are using a **private repo**, we must define ``Github credentials``. These definitions are performed under _Jenkins Home Page -> Credentials -> Global credentials (unrestricted) -> Add Credentials_ menu.

![](images/009.png)

We use the value we entered in the ``ID`` field to Docker Login in the script file. Now, we define pipeline under _Jenkins Home Page -> New Item_ menu.

![](images/0101.png)

In this step, we select ``GitHub hook trigger for GITScm pooling`` options for automatic run of the pipeline by ``Github hook`` call.

![](images/011.png)

Also in the Pipeline section, we select the ``Pipeline script from SCM`` as Definition, define the GitHub repository and the branch name, and specify the script location (Jenkins file).

![](images/0120.png)



## Review important points of the Jenkins file

```
stage('Initialize'){
    def dockerHome = tool 'myDocker'
    def mavenHome  = tool 'myMaven'
    env.PATH = "${dockerHome}/bin:${mavenHome}/bin:${env.PATH}"
}
```

The ``Maven`` and ``Docker client`` tools we have defined in Jenkins under _Global Tool Configuration_ menu are added to the ``PATH environment variable`` for using these tools with ``sh command``.

```
stage('Push to Docker Registry'){
    withCredentials([usernamePassword(credentialsId: 'dockerHubAccount', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
        pushToImage(CONTAINER_NAME, CONTAINER_TAG, USERNAME, PASSWORD)
    }
}
```

## Application and HA

With reverse proxy configuration, we can achieve non https redirection to https protocol

You can access the application at  `https://localhost`

**@TODO**:

I will try further to add High-availability of the application though **Kubernetes** or sclaing Docker server through **Auto-scaling with scaling policies**. As part of above process we are building the docker image with respective tags and pushing back to the DockeHub Registry. 

In this scenraio usage of **Kubenetes** is much better for scaling the application across multiple containers(Horizontal scaling) instead host machine scaling(vertical scaling) everytime which is not a good practice.