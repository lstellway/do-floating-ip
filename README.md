# Reassign DigitalOcean Floating IP to Current Droplet

This project has been sourced and tweaked from [5pi/img-do-float-ip](https://github.com/5pi/img-do-float-ip) _(thank you!)_.

**Docker Pull Command**

```sh
docker pull lstellway/do-floating-ip
```

## Environment Variables

-   `DO_METADATA_API` = `http://169.254.169.254`
    -   The metadata API url
-   `DO_API` = `https://api.digitalocean.com`
    -   The DigitalOcean API url
-   `DO_TOKEN`
    -   DigitalOcean [personal access token](https://docs.digitalocean.com/reference/api/create-personal-access-token/)
-   `DO_TOKEN_FILE`
    -   Path to file containing mounted DigitalOcean [personal access token](https://docs.digitalocean.com/reference/api/create-personal-access-token/) secret
-   `DO_FLOATING_IP`
    -   The DigitalOcean floating IP to keep up-to-date
-   `UPDATE_FREQUENCY` = `600` _(`10` minutes)_
    -   The frequency _(in seconds)_ for which to check that the floating IP is up-to-date

## Running on Kubernetes

Because [Kubernetes masks the "Link Local" IP range](https://kubernetes.io/docs/tasks/administer-cluster/ip-masq-agent/) required to run this container, the `hostNetwork` parameter needs to be enabled in the Pod specification:

```yml
apiVersion: v1
kind: Pod
spec:
    hostNetwork: true
```
