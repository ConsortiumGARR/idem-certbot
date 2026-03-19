# IDEM CERTBOT

This repository contains a fully automated Certbot in Docker that manages ACME account registration and SSL/TLS certificate issuance. It supports both standard Let's Encrypt and ACME EAB (External Account Binding).

It can operate in two modes:

- **Standalone** – for using certificates directly on the VM running Docker.

- **Centralized** – the first node requests certificates, which are then synced to other nodes via rsync.

## Prerequisites

### Local usage

- Docker
- An ACME account (required only if using ACME EAB).

### Remote usage

- Ansible installed on your node (>2.17.0)
- Community Docker Ansible collection. You can install it by running the following command:

        ansible-galaxy collection install community.docker

- Docker installed on the remote machines.
- An ACME account (required only if using ACME EAB).

## Environment Variables

| Variable | Description | Is Required? |
| -------- | ----------- | --------- |
| EMAIL_ADMIN | Admin email for ACME registration | Yes |
| DOMAINS_LIST | List of domains to certificate, separated by ; with optional aliases after :. Example: example.com:www.example.com;example.org | Yes - Structure managed by Ansible |
| SERVER_URL | ACME server URL | Yes, only for ACME EAB |
| KEY_ID | EAB key identifier | Yes, only for ACME EAB |
| HMAC_KEY | HMAC key for EAB | Yes, only for ACME EAB |
| CHECK_FREQ | Hours between certificate checks and renewal | No  - Default: 12 |

## How It Works

### ACME Registration

1. Verifies required variables; exits if missing.
2. It checks for EAB variables:
    - If present → uses ACME EAB.
    - If absent → uses standard Let's Encrypt.
3. Registers the ACME account via certbot register.
4. Skips if the account already exists on the mounted folder.

### Certificate Creation

- `create_cert` function handles certificate creation per domain.
- Supports multiple aliases.
- Checks if certificate exists in `/etc/letsencrypt/live/$domain`.
  - Creates certificate, if missing, using `certbot certonly --standalone`.
  - Skips if certificate already exists.
- Splits `DOMAINS_LIST` by ; and parses aliases with :.

### Automatic Renewal

- After certificate creation, the script enters an infinite loop.
- Uses `CHECK_FREQ` (hours) to determine how frequent the renew check is performed.
- Executes `certbot renew -q` every cycle.
- Logs errors if renewal fails.
- Sleeps `CHECK_FREQ` hours between cycles.

## Instructions

### Docker image creation

1. Retrieve the repository with `git clone`.

2. Move inside the `idem-certbot` repository folder.

3. Build the image:

    ```bash
    docker build -f docker/Dockerfile -t <CHOOSE-A-DOCKER-IMAGE-NAME>:<CHOOSE-A-TAG> .
    ```

### Deploy

#### With Ansible

1. Move inside the `idem-certbot` repository folder.

2. Copy the `ansible/inventories/example` folder to `ansible/inventories/<YOUR-FOLDER-NAME>/`.

3. Create an SSH key pair under the `ansible/inventories/<YOUR-FOLDER-NAME>/files`:

   - `ssh-keygen -t ed25519 -f ansible/inventories/<YOUR-FOLDER-NAME>/files/id_ed25519_certbot -N ""`

> [!IMPORTANT]
> **You need to protect the private key! You can use [Ansible Vault](https://docs.ansible.com/projects/ansible/latest/vault_guide/vault_encrypting_content.html).**

4. To make the Docker image available to remote nodes, it must either be pushed to a private container registry or the image (in tar.gz format) must be sent to the remote node (already implemented with Ansible).

   - Push the image to a private container registry:

     ```bash
     docker push <CHOSEN-DOCKER-IMAGE-NAME>:<CHOSEN-TAG>
     ```

> [!NOTE]
> If you are using a private container registry, the Docker image name must also include the container registry URL.

   - Create a tar.gz archive of the created Docker image:

     ```bash
     docker save <CHOSEN-DOCKER-IMAGE-NAME>:<CHOSEN-TAG> | gzip > ansible/inventories/<YOUR-FOLDER-NAME>/files/<CHOSEN-DOCKER-IMAGE-NAME>_<CHOSEN-TAG>.tar.gz
     ```

5. Modify as needed:

   - `ansible/inventories/<YOUR-FOLDER-NAME>/inventory.ini`
   - `ansible/inventories/<YOUR-FOLDER-NAME>/group_vars/all.yml`

> [!IMPORTANT]
> **You need to protect your secrets! You can use [Ansible Vault](https://docs.ansible.com/projects/ansible/latest/vault_guide/vault_encrypting_content.html).**

6. Run the Ansible Playbook command (with vaulted secrets):

    ```bash
    ansible-playbook ansible/playbook.yml -u <USER-ON-REMOTE-VM> -i ansible/inventories/<YOUR-FOLDER-NAME>/inventory.ini --ask-vault-pass
    ```

#### Without Ansible - Locally

1. Create a `docker-compose.yml` file and modify it as needed:

    ```bash
    services:
        idem-certbot:
            image: "<DOCKER-IMAGE-NAME>:<TAG>"
            container_name: "custom-certbot"
            hostname: certbot
            environment:
                - EMAIL_ADMIN=<MAIL-UTENTE>
                - KEY_ID=<KEY-ID-VALUE>
                - HMAC_KEY=<HMAC_KEY_VALUE>
                - SERVER_URL=<ACME-SERVER-URL>
                - CHECK_FREQ=<CHECK-FREQ>
                - DOMAINS_LIST=domain1:alias1,alias2;domain2;domain3:alias1
            volumes:
                - <YOUR-DESTINATION-FOLDER-ON-VM>:/etc/letsencrypt
            restart: unless-stopped
            healthcheck:
                test: ["CMD-SHELL", "certbot certificates > /dev/null 2>&1"]
                interval: 1m
                timeout: 10s
                retries: 3
                start_period: 20s
    ```

> [!CAUTION]
> If you want to use Let's Encrypt, you MUST leave **KEY_ID**, **HMAC_KEY** and **SERVER_URL** variables EMPTY.

2. Run docker compose: `docker compose up -d`
