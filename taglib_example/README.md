# Taglib Jenkinsfile

This Jenkinsfile creates a pipeline that will build, test and package the taglib library on every push to the repo.

## Package versioning

The first step of this pipeline is determining the version we're building. When building feature branch, we want the version to be based on the branch name and the build ID. This makes it easier to find build logs in Jenkins and prune those artifact once they're not needed anymore.

When we want to create a release, we want the version to be easier to understand for users. In which case, using semver is a better option. One way to do that is to **not** trigger builds for pushes on the `master` branch and instead rely on git tag. Alternatively, you could come up with a solution to use semver when pushing to the `master` branch like parsing a CHANGELOG.md file or automated increment based on previous master build.

## Platform matrix

In order to build the library for multiple platform, we are leveraging the matrix feature. 

We create a function for each platform we want to build. This allows to easily add new platform as required making this pipeline modular.

The matrix then calls a function using the platform name as parameter which is then used in a switch case statement to trigger the corresponding function.

To add a new platform, simply creates a function which includes the build, test and package stages. Then add your function in the switch case statement of the `callPlatformPipeline` function. Make sure to include a step in your function that `stash` the resulting package so that we can upload it to a remote storage at a later stage.

### Note

In this example, the agent for the stages in the matrix are harcoded to use the Docker_Linux agent. This is to demonstrate running parallel steps as part of a matrix and because this demo does not cover deploying a Windows agent. In production, the agent label would be set by the matrix allowing to run steps on different agents.

## Upload artifacts

At the end of the pipeline, an upload stage `unstash` all the artifacts that were stashed and upload them to a remote storage. This part has been mocked in the example Jenkinsfile but you could easily add a step that would upload the artifacts to an S3 bucket, a google drive, artifact registry, etc.

Having the upload stage at the end ensures that in any given pipeline run, all builds have passed before uploading, preventing partial or inconsistent deployments. This is especially important when running the pipeline for the master branch or a git tag.

