# Scandiweb Stack - Magento 2

Magento is an open-source e-commerce platform written in PHP. It uses multiple other PHP frameworks such as Laminas and Symfony.

## Table of Contents

- [Introduction](#introduction)
- [Requirements](#requirements)
- [Description](#description)
- [Installation](#installation)
- [Usage](#usage)
- [Todo](#todo)

## Introduction

This is a complete stack for Magento 2.4 development. It includes:

- [Nginx](https://www.nginx.com/) web server
- [PHP-FPM](https://php-fpm.org/) PHP FastCGI Process Manager
- [MySQL](https://www.mysql.com/) database
- [Varnish](https://varnish-cache.org/) caching server
- [ElasticSearch](https://www.elastic.co/) search engine
- [Terraform](https://www.terraform.io/) infrastructure as code
- [Docker](https://www.docker.com/) containerization
- [Docker Compose](https://docs.docker.com/compose/) container orchestration

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) 1.4.2
- Setting up aws credentials (follow [this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) guide)

## Description
Infrastructure which will consist of 2 servers: caching server and server which will host Magento application. The entry point to the infrastructure will be AWS load-balancer, which will be terminating SSL and taking care of correct routing.

Details of the infrastructure:
1. Load-balancer must route all requests to the Varnish server. Except for requests whose path starts with /media/* or /static/*, those requests should bypass Varnish and go directly to the Magento application.
2. Redirect all the HTTP requests to HTTPS.
3. Varnish server must be configured to cache all the responses from Magento application.


## Installation

1. Clone the repository:

   ```bash
   git clone git@github.com:pyhp2017/scandiweb-stack.git
    ```
2. Create a new file called `terraform.tfvars` in the root directory of the project and add the following content. (You can also override the default values in `values.tf`)
    ```env
    servers_public_key="<YOUR PUBLIC KEY>"
    servers_private_key_path="<PATH TO YOUR PRIVATE KEY>"
    acme_registration_email="<YOUR EMAIL>"
    ```
3. Run the following command to create the infrastructure
    ```bash
    terraform init
    terraform plan -var-file=terraform.tfvars
    terraform apply --auto-approve -var-file=terraform.tfvars
    ```
4. Wait for the infrastructure to be created. It will take around 15 to 20 minutes. (You have to wait for magneto2 to be installed and configured in the first run in the ec2 instance)

## Usage

1. After the infrastructure is created, you can access the server using the domain shown in the output.
    ```
        admin_password = "<YOUR ADMIN PASSWORD>"
        admin_url = "https://<DOMAIN>/admin"
        admin_user = "<YOUR ADMIN USERNAME>"
        scandiweb_magento2_ip = "<YOUR MAGENTO2 IP>"
        scandiweb_varnish_ip = "<YOUR VARNISH IP>"
2. You can access the admin panel using the credentials shown in the output.

## TODO

- [ ] Change Hard coded values such as private ip of the instances and find another way to get the private ip of the instances.
- [ ] Pass other environment variables to the docker-compose file.
- [ ] Add tests for the terraform code.
- [ ] Add tests for the docker-compose.
