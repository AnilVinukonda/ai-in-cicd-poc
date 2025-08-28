pipeline {
  agent any
  environment {
    MODEL_API_BASE = credentials('MODEL_API_BASE') // Jenkins string credential
    MODEL_API_KEY  = credentials('MODEL_API_KEY')
    MODEL_NAME     = 'gpt-4o-mini'
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('PR Review (manual trigger)') {
      when { expression { return env.CHANGE_ID != null } }
      steps {
        sh 'git diff --unified=0 origin/${CHANGE_TARGET}...HEAD > diff.patch || true'
        sh 'bash scripts/ai_pr_review.sh diff.patch > review.md || true'
        archiveArtifacts artifacts: 'review.md', onlyIfSuccessful: false
      }
    }
    stage('TIA Tests') {
      steps {
        sh 'python3 -m pip install -r requirements.txt'
        sh 'python3 scripts/test_impact.py origin/${BRANCH_NAME} HEAD > selected_tests.txt || true'
        sh 'if [ -s selected_tests.txt ]; then pytest -q $(cat selected_tests.txt); else pytest -q; fi'
      }
    }
    stage('Release Notes (manual)') {
      when { branch 'main' }
      steps {
        sh 'git fetch --tags --force || true'
        sh 'bash scripts/ai_release_notes.sh commit_log.txt > RELEASE_NOTES.md || true'
        archiveArtifacts artifacts: 'RELEASE_NOTES.md', onlyIfSuccessful: false
      }
    }
  }
  options { timestamps() }
}
