# k3s-deploy

This repo builds a Docker image for a self-hosted GitHub Actions runner and
uses Jenkins to build and push the image to JFrog.

## Run The GitHub Runner With Docker

On the EC2 instance, clone or update this repo:

```bash
git clone https://github.com/Prashant260/k3s-deploy.git
cd k3s-deploy
```

Build the runner image:

```bash
docker build -t github-runner ./runner
```

Create a fresh runner token from GitHub:

```text
Repository > Settings > Actions > Runners > New self-hosted runner
```

Start the runner with `docker run`:

```bash
docker rm -f github-runner || true

docker run -d \
  --name github-runner \
  --restart always \
  -e GITHUB_URL=https://github.com/Prashant260/k3s-deploy \
  -e RUNNER_TOKEN=YOUR_NEW_GITHUB_RUNNER_TOKEN \
  -v /var/run/docker.sock:/var/run/docker.sock \
  github-runner
```

Check the logs:

```bash
docker logs -f github-runner
```

The runner is ready when the logs show:

```text
Listening for Jobs
```

## Jenkins Build

The Jenkins pipeline in `Jenkinsfile` builds the same image from
`runner/Dockerfile`, tags it, logs in to JFrog, and pushes it.

Before running the Jenkins job, update:

```groovy
JFROG_REGISTRY = 'YOUR_COMPANY.jfrog.io'
JFROG_REPO = 'docker-local'
```

Create this Jenkins credential:

```text
ID: jfrog-docker-creds
Kind: Username with password
Username: your JFrog username
Password: your JFrog access token
```

Then create a Jenkins pipeline job:

```text
Pipeline script from SCM
Repository URL: https://github.com/Prashant260/k3s-deploy
Script Path: Jenkinsfile
```

## Important

Never commit real values for:

- GitHub runner token
- JFrog password or token
- AWS access key or secret key
