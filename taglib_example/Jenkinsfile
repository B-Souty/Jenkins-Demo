def PLATFORM_BUILT = []

pipeline {
  agent none
  environment {
    VERSION = ''
  }

  stages {
    stage('Set Version') {

        agent any
        
        steps {
          script {
            if (env.GIT_BRANCH == 'master') {
              // When we build the master branch we want to use semver. 
              // In production you would have a script to get the actual semver or use 
              // git tags instead of running the pipeline on master.
              // For simplicity sake in this example we just set a arbitrary semver of 1.2.3
              VERSION = "1.2.3"
            } else {
              VERSION = "${env.GIT_BRANCH}-${env.BUILD_ID}"
            }
            echo "Build taglib version: ${VERSION}"
          }
        }
    }

    stage('Build and Test') {
      matrix {
        axes {
          axis {
            name 'PLATFORM'
            values 'Linux', 'Windows'
          }
        }

        // For demo purposes and because we don't have a windows agent in our setup, we will use the Linux agent to run
        // a mock build, test and package matrix for Windows to demonstrate running parallel steps in a matrix.
        // agent { label "Docker_${PLATFORM}" }
        agent { label "Docker_Linux" }
        
        stages {
          stage('Platform-Specific Stages') {
            steps {
              script {
                callPlatformPipeline(env.PLATFORM)
                PLATFORM_BUILT.add(env.PLATFORM)
              }
            }
          }
        }
      }
    }

    stage('Upload') {

      agent any

      steps {
        echo "Uploading binaries for version ${VERSION}"
        script {
          PLATFORM_BUILT.each { platform_name ->
            dir("output/${platform_name}") {
              unstash "build-${platform_name}"
              echo "unstashed build-${platform_name}"
            }
          }
        }
        // Here we would add logic to upload the unstash binaries to a registry or storage system like s3
        echo "Upload all build artifacts"
      }
    }
  }
}

def callPlatformPipeline(platform) {
  switch (platform) {
    case 'Linux':
      linuxPipeline()
      break
    case 'Windows':
      windowsPipeline()
      break
    default:
      error "Unknown platform: ${platform}"
  }
}

def linuxPipeline() {
  def BUILD_PLATFORM="Linux"
  def TAGLIB_DST_DIR="src/build"

  stage('Build') {
    echo "Building taglib version ${VERSION} on ${BUILD_PLATFORM}"
    sh """
      mkdir -p ${TAGLIB_DST_DIR}
      cmake -B ${TAGLIB_DST_DIR} -DBUILD_SHARED_LIBS=OFF -DVISIBILITY_HIDDEN=ON \
        -DBUILD_TESTING=ON -DBUILD_EXAMPLES=OFF -DBUILD_BINDINGS=ON \
        -DCMAKE_BUILD_TYPE=Release
      cmake --build ${TAGLIB_DST_DIR} --config Release
    """
  }

  stage('Test') {
    echo "Testing taglib version ${VERSION} on ${BUILD_PLATFORM}"
    sh """
      cmake --build ${TAGLIB_DST_DIR} --config Release --target check
    """
  }

  stage('Package') {
    sh """
      cmake --install ${TAGLIB_DST_DIR} --prefix ./taglib-install
      tar -czvf taglib-${BUILD_PLATFORM}-${VERSION}.tar.gz ./taglib-install/
    """
    stash includes: "taglib-${BUILD_PLATFORM}-${VERSION}.tar.gz", name: "build-${BUILD_PLATFORM}"
  }
}

def windowsPipeline() {
  BUILD_PLATFORM="Windows"

  stage('Build') {
    echo "Building taglib version ${VERSION} on ${BUILD_PLATFORM}"
    // Building logic for Windows goes here
  }

  stage('Test') {
    echo "Testing taglib version ${VERSION} on ${BUILD_PLATFORM}"
    // Testing logic for Windows goes here
  }

  stage('Package') {
    echo "Packaging and stashing the build output"
    sh "touch test.txt"
    stash includes: "test.txt", name: "build-${BUILD_PLATFORM}"
    // Packaging and stashin logic for Windows goes here
  }
}
