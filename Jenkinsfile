pipeline {
  agent {
    kubernetes {
      cloud 'kubernetes'
    }
  }
  stages {
    stage('Jenkins 5 hours Job') {
      steps {
        container('ubuntu') {
          sh '''
            env
            sleep 5h
          '''
        }
      }
    }
  }
}